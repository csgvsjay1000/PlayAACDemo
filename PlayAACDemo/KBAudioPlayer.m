//
//  KBAudioPlayer.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "KBAudioPlayer.h"
#import "MCParsedAudioData.h"
#import "MCAudioBuffer.h"

typedef enum : NSUInteger {
    KBPlayerPlayingStatePlaying = 10,  //正在播放
    KBPlayerPlayingStatePause = 20, //暂停
    
} KBPlayerPlayingState;

@interface KBAudioPlayer (){
    
    AudioFileStreamID _audioFileStreamID;
    
    AudioStreamBasicDescription _format;
    
    NSFileHandle *_fileHandler;
    
    AudioQueueRef playQueue;
    
    AudioQueueBufferRef playBufs[3];

    UInt32 audio_buf_size;
    
    MCAudioBuffer *_buffer;


}

@property(nonatomic,assign)KBPlayerPlayingState playingState;  //播放状态


@end

@implementation KBAudioPlayer

#pragma mark - initialization
-(id)init{
    self = [super init];
    if (self) {
        _buffer = [MCAudioBuffer buffer];
        NSThread *playThread = [[NSThread alloc] initWithTarget:self selector:@selector(playAudio) object:nil];
        [playThread start];
        
    }
    return self;
}

#pragma mark - player manager
-(void)paly{
    _playingState = KBPlayerPlayingStatePause;
    
}

-(void)playAudio{
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"nocturne" ofType:@"aac"];
    _fileHandler = [NSFileHandle fileHandleForReadingAtPath:path];
    audio_buf_size = 2069;
    NSData *data = [_fileHandler readDataOfLength:480*1024];
    [self parseData:data error:nil];
    
    if (_format.mSampleRate>0) {
        if (!playQueue) {
            AudioQueueNewOutput(&_format, AQueueOutputCallback, (__bridge void*)self, NULL, NULL, 0, &playQueue);
            AudioQueueStart(playQueue, NULL);
            
            for (int i=0; i<3; i++) {
                OSStatus statu = AudioQueueAllocateBuffer(playQueue, audio_buf_size, &playBufs[i]);
                if (statu == noErr) {
                    [self readPacketsIntoBuffer:playBufs[i]];
                }
            }
        }
    }
}

#pragma mark - static callbacks
static void MCSAudioFileStreamPropertyListener(void *inClientData,
                                               AudioFileStreamID inAudioFileStream,
                                               AudioFileStreamPropertyID inPropertyID,
                                               UInt32 *ioFlags)
{
    KBAudioPlayer *audioFileStream = (__bridge KBAudioPlayer *)inClientData;
    [audioFileStream handleAudioFileStreamProperty:inPropertyID];
}

static void MCAudioFileStreamPacketsCallBack(void *inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void *inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions)
{
    KBAudioPlayer *audioFileStream = (__bridge KBAudioPlayer *)inClientData;
    [audioFileStream handleAudioFileStreamPackets:inInputData
                                    numberOfBytes:inNumberBytes
                                  numberOfPackets:inNumberPackets
                               packetDescriptions:inPacketDescriptions];
}

static void AQueueOutputCallback(
                                 void * __nullable       inUserData,
                                 AudioQueueRef           inAQ,
                                 AudioQueueBufferRef     inBuffer){
    KBAudioPlayer *vc = (__bridge KBAudioPlayer *)inUserData;
    [vc readPacketsIntoBuffer:inBuffer];
}

- (void)handleAudioFileStreamProperty:(AudioFileStreamPropertyID)propertyID{
    if (propertyID == kAudioFileStreamProperty_DataFormat){
        UInt32 asbdSize = sizeof(_format);
        AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_DataFormat, &asbdSize, &_format);
    }
}

- (void)handleAudioFileStreamPackets:(const void *)packets
                       numberOfBytes:(UInt32)numberOfBytes
                     numberOfPackets:(UInt32)numberOfPackets
                  packetDescriptions:(AudioStreamPacketDescription *)packetDescriptioins{
    NSLog(@"numberOfBytes %d",numberOfBytes);
    NSMutableArray *parsedDataArray = [[NSMutableArray alloc] init];

    
    for (int i = 0; i < numberOfPackets; ++i){
        SInt64 packetOffset = packetDescriptioins[i].mStartOffset;
        MCParsedAudioData *parsedData = [MCParsedAudioData parsedAudioDataWithBytes:packets + packetOffset
                                                                  packetDescription:packetDescriptioins[i]];
        
        [parsedDataArray addObject:parsedData];
    }
    [_buffer enqueueFromDataArray:parsedDataArray];
}

-(void)readPacketsIntoBuffer:(AudioQueueBufferRef)buffer{
    UInt32 packetCount;
    AudioStreamPacketDescription *desces = NULL;
    NSData *data = [_buffer dequeueDataWithSize:audio_buf_size packetCount:&packetCount descriptions:&desces];
    
    memcpy(buffer->mAudioData, [data bytes], [data length]);
    buffer->mAudioDataByteSize = (UInt32)[data length];
    
    OSStatus status = AudioQueueEnqueueBuffer(playQueue, buffer, packetCount, desces);
    if (status != noErr) {
        printf("AudioQueueEnqueueBuffer error\n");
    }else{
        printf("AudioQueueEnqueueBuffer Success\n");
    }
}

#pragma mark - parse data
- (BOOL)parseData:(NSData *)data error:(NSError **)error{
    
    OSStatus status = AudioFileStreamParseBytes(_audioFileStreamID,(UInt32)[data length],[data bytes], 0);
    
    
    return YES;
}


#pragma mark - private methods
- (void)_errorForOSStatus:(OSStatus)status error:(NSError **)outError
{
    if (status != noErr && outError != NULL)
    {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
}

#pragma mark - setters and getters
-(void)setFileType:(AudioFileTypeID)fileType{
    _fileType = fileType;
    OSStatus status = AudioFileStreamOpen((__bridge void *)self,
                                          MCSAudioFileStreamPropertyListener,
                                          MCAudioFileStreamPacketsCallBack,
                                          _fileType,
                                          &_audioFileStreamID);
    
    if (status != noErr)
    {
        _audioFileStreamID = NULL;
    }
    NSError *error;
    [self _errorForOSStatus:status error:&error];
}

@end
