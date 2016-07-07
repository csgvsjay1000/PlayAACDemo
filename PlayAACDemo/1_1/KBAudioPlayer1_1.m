//
//  KBAudioPlayer1_1.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "KBAudioPlayer1_1.h"
#import <AVFoundation/AVFoundation.h>
#import "MCParsedAudioData.h"
#import "MCAudioBuffer.h"

//Important!
#pragma pack(1)

#define TAG_TYPE_SCRIPT 18
#define TAG_TYPE_AUDIO  8
#define TAG_TYPE_VIDEO  9

typedef unsigned char byte;
typedef unsigned int uint;

typedef struct {
    byte Signature[3];
    byte Version;
    byte Flags;
    uint DataOffset;
} FLV_HEADER;

typedef struct {
    byte TagType;
    byte DataSize[3];
    byte Timestamp[3];
    uint Reserved;
} TAG_HEADER;


//reverse_bytes - turn a BigEndian byte array into a LittleEndian integer
uint reverse_bytes(byte *p, char c) {
    int r = 0;
    int i;
    for (i=0; i<c; i++)
        r |= ( *(p+i) << (((c-1)*8)-8*i));
    
    
    return r;
}


@interface KBAudioPlayer1_1 (){

    FILE *ifh;
    
    AudioFileStreamID _audioFileStreamID;
    
    AudioStreamBasicDescription _format;
    
    NSFileHandle *_fileHandler;
    
    AudioQueueRef playQueue;
    
    AudioQueueBufferRef playBufs[3];
    
    UInt32 audio_buf_size;
    
    MCAudioBuffer *_buffer;
    
    BOOL isStart;
    
    unsigned char *aacBuffer;
    
}

@end

@implementation KBAudioPlayer1_1

#pragma mark - initialization
-(id)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)simplest_mediadata_flv{
    [self setFileType:kAudioFileAAC_ADTSType];
    FLV_HEADER flv;
    TAG_HEADER tagheader;
    uint previoustagsize, previoustagsize_z=0;
    uint ts=0, ts_new=0;
    
    FILE *myout=stdout;

    NSString *path = [[NSBundle mainBundle] pathForResource:@"cuc_ieschool" ofType:@"flv"];

    ifh = fopen([path UTF8String], "rb+");
    if ( ifh== NULL) {
        printf("Failed to open files!");
    }
    
    //FLV file header
    fread((char *)&flv,1,sizeof(FLV_HEADER),ifh);
    
    fprintf(myout,"============== FLV Header ==============\n");
    fprintf(myout,"Signature:  0x %c %c %c\n",flv.Signature[0],flv.Signature[1],flv.Signature[2]);
    fprintf(myout,"Version:    0x %X\n",flv.Version);
    fprintf(myout,"Flags  :    0x %X\n",flv.Flags);
    fprintf(myout,"HeaderSize: 0x %X\n",reverse_bytes((byte *)&flv.DataOffset, sizeof(flv.DataOffset)));
    fprintf(myout,"========================================\n");
    
    //move the file pointer to the end of the header
    fseek(ifh, reverse_bytes((byte *)&flv.DataOffset, sizeof(flv.DataOffset)), SEEK_SET);
    audio_buf_size = 2069;

    aacBuffer = malloc(sizeof(char)*audio_buf_size);
    
    //process each tag
    do {
        
        previoustagsize = getw(ifh);
        
        fread((void *)&tagheader,sizeof(TAG_HEADER),1,ifh);
        
        //int temp_datasize1=reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize));
        int tagheader_datasize=tagheader.DataSize[0]*65536+tagheader.DataSize[1]*256+tagheader.DataSize[2];
        int tagheader_timestamp=tagheader.Timestamp[0]*65536+tagheader.Timestamp[1]*256+tagheader.Timestamp[2];
        
        char tagtype_str[10];
        switch(tagheader.TagType){
            case TAG_TYPE_AUDIO:sprintf(tagtype_str,"AUDIO");break;
            case TAG_TYPE_VIDEO:sprintf(tagtype_str,"VIDEO");break;
            case TAG_TYPE_SCRIPT:sprintf(tagtype_str,"SCRIPT");break;
            default:sprintf(tagtype_str,"UNKNOWN");break;
        }
        fprintf(myout,"[%6s] %6d %6d |",tagtype_str,tagheader_datasize,tagheader_timestamp);
        
        //if we are not past the end of file, process the tag
        if (feof(ifh)) {
            break;
        }
        
        //process tag by type
        switch (tagheader.TagType) {
                
            case TAG_TYPE_AUDIO:{
                char audiotag_str[100]={0};
                strcat(audiotag_str,"| ");
                char tagdata_first_byte;
                tagdata_first_byte=fgetc(ifh);
                int x=tagdata_first_byte&0xF0;
                x=x>>4;
                switch (x)
                {
                    case 0:strcat(audiotag_str,"Linear PCM, platform endian");break;
                    case 1:strcat(audiotag_str,"ADPCM");break;
                    case 2:strcat(audiotag_str,"MP3");break;
                    case 3:strcat(audiotag_str,"Linear PCM, little endian");break;
                    case 4:strcat(audiotag_str,"Nellymoser 16-kHz mono");break;
                    case 5:strcat(audiotag_str,"Nellymoser 8-kHz mono");break;
                    case 6:strcat(audiotag_str,"Nellymoser");break;
                    case 7:strcat(audiotag_str,"G.711 A-law logarithmic PCM");break;
                    case 8:strcat(audiotag_str,"G.711 mu-law logarithmic PCM");break;
                    case 9:strcat(audiotag_str,"reserved");break;
                    case 10:strcat(audiotag_str,"AAC");break;
                    case 11:strcat(audiotag_str,"Speex");break;
                    case 14:strcat(audiotag_str,"MP3 8-Khz");break;
                    case 15:strcat(audiotag_str,"Device-specific sound");break;
                    default:strcat(audiotag_str,"UNKNOWN");break;
                }
                strcat(audiotag_str,"| ");
                x=tagdata_first_byte&0x0C;
                x=x>>2;
                switch (x)
                {
                    case 0:strcat(audiotag_str,"5.5-kHz");break;
                    case 1:strcat(audiotag_str,"1-kHz");break;
                    case 2:strcat(audiotag_str,"22-kHz");break;
                    case 3:strcat(audiotag_str,"44-kHz");break;
                    default:strcat(audiotag_str,"UNKNOWN");break;
                }
                strcat(audiotag_str,"| ");
                x=tagdata_first_byte&0x02;
                x=x>>1;
                switch (x)
                {
                    case 0:strcat(audiotag_str,"8Bit");break;
                    case 1:strcat(audiotag_str,"16Bit");break;
                    default:strcat(audiotag_str,"UNKNOWN");break;
                }
                strcat(audiotag_str,"| ");
                x=tagdata_first_byte&0x01;
                switch (x)
                {
                    case 0:strcat(audiotag_str,"Mono");break;
                    case 1:strcat(audiotag_str,"Stereo");break;
                    default:strcat(audiotag_str,"UNKNOWN");break;
                }
                fprintf(myout,"%s",audiotag_str);
                
                char isACCsequenceHeader = fgetc(ifh);
                int data_size=reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize))-1;
                if(isACCsequenceHeader == 0x00){
                    char *ACCsequenceHeader = (char *)malloc(sizeof(char)*2);
                    fread(ACCsequenceHeader, sizeof(char), 2, ifh);
                    
                    data_size -= 3;
                    //
                    //                int audioObjectType = (ACCsequenceHeader[0]&0xf8)>>3;
                    //                int samplingFrequencyIndex = ((ACCsequenceHeader[0]&0x7)<<1)|(ACCsequenceHeader[1]>>7);
                    //                int channelConfiguration = (ACCsequenceHeader[1]>>3)&0x0f;
                    //                int extensionFlag = (ACCsequenceHeader[1]&0x01);
                    
                }else if (isACCsequenceHeader == 0x01){
                    data_size -= 1;
                }

                //TagData - First Byte Data
                
                
                
                write_adst_header(data_size, aacBuffer);
                
//        
//                //TagData - First Byte Data
//                int data_size=reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize))-1;
                
                if (fread(aacBuffer+7, 1, data_size, ifh) == data_size) {
                    NSData *data = [[NSData alloc] initWithBytes:aacBuffer length:data_size+7];
                    [self parseData:data error:nil];
                }
                if (_format.mSampleRate>0 && !isStart ) {
                    isStart = YES;
//                    [self playAudio];
                    [NSThread detachNewThreadSelector:@selector(playAudio) toTarget:self withObject:nil];
                }
                
//                for (int i=0; i<data_size; i++)
//                    fgetc(ifh);
                break;
            }
            case TAG_TYPE_VIDEO:{
                char videotag_str[100]={0};
                strcat(videotag_str,"| ");
                char tagdata_first_byte;
                tagdata_first_byte=fgetc(ifh);
                int x=tagdata_first_byte&0xF0;
                x=x>>4;
                switch (x)
                {
                    case 1:strcat(videotag_str,"key frame  ");break;
                    case 2:strcat(videotag_str,"inter frame");break;
                    case 3:strcat(videotag_str,"disposable inter frame");break;
                    case 4:strcat(videotag_str,"generated keyframe");break;
                    case 5:strcat(videotag_str,"video info/command frame");break;
                    default:strcat(videotag_str,"UNKNOWN");break;
                }
                strcat(videotag_str,"| ");
                x=tagdata_first_byte&0x0F;
                switch (x)
                {
                    case 1:strcat(videotag_str,"JPEG (currently unused)");break;
                    case 2:strcat(videotag_str,"Sorenson H.263");break;
                    case 3:strcat(videotag_str,"Screen video");break;
                    case 4:strcat(videotag_str,"On2 VP6");break;
                    case 5:strcat(videotag_str,"On2 VP6 with alpha channel");break;
                    case 6:strcat(videotag_str,"Screen video version 2");break;
                    case 7:strcat(videotag_str,"AVC");break;
                    default:strcat(videotag_str,"UNKNOWN");break;
                }
                fprintf(myout,"%s",videotag_str);
                
                fseek(ifh, -1, SEEK_CUR);
                //if the output file hasn't been opened, open it.
               #if 0
                //Change Timestamp
                //Get Timestamp
                ts = reverse_bytes((byte *)&tagheader.Timestamp, sizeof(tagheader.Timestamp));
                ts=ts*2;
                //Writeback Timestamp
                ts_new = reverse_bytes((byte *)&ts, sizeof(ts));
                memcpy(&tagheader.Timestamp, ((char *)&ts_new) + 1, sizeof(tagheader.Timestamp));
#endif
                
                
                //TagData + Previous Tag Size
                int data_size=reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize))+4;
                for (int i=0; i<data_size; i++)
                    fgetc(ifh);
                //rewind 4 bytes, because we need to read the previoustagsize again for the loop's sake
                fseek(ifh, -4, SEEK_CUR);
                
                break;
            }
            default:
                
                //skip the data of this tag
                fseek(ifh, reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize)), SEEK_CUR);
        }
        
        sleep(0.1);
        
        fprintf(myout,"\n");
        
    } while (!feof(ifh));
    
}


-(void)playAudio{
    
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
    KBAudioPlayer1_1 *audioFileStream = (__bridge KBAudioPlayer1_1 *)inClientData;
    [audioFileStream handleAudioFileStreamProperty:inPropertyID];
}

static void MCAudioFileStreamPacketsCallBack(void *inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void *inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions)
{
    KBAudioPlayer1_1 *audioFileStream = (__bridge KBAudioPlayer1_1 *)inClientData;
    [audioFileStream handleAudioFileStreamPackets:inInputData
                                    numberOfBytes:inNumberBytes
                                  numberOfPackets:inNumberPackets
                               packetDescriptions:inPacketDescriptions];
}

static void AQueueOutputCallback(
                                 void * __nullable       inUserData,
                                 AudioQueueRef           inAQ,
                                 AudioQueueBufferRef     inBuffer){
    KBAudioPlayer1_1 *vc = (__bridge KBAudioPlayer1_1 *)inUserData;
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
    OSStatus status = AudioFileStreamOpen((__bridge void *)self,
                                          MCSAudioFileStreamPropertyListener,
                                          MCAudioFileStreamPacketsCallBack,
                                          kAudioFileAAC_ADTSType,
                                          &_audioFileStreamID);
    
    if (status != noErr)
    {
        _audioFileStreamID = NULL;
    }
    NSError *error;
    [self _errorForOSStatus:status error:&error];
}

void write_adst_header(int size,char *puf){
    int syncword = 0xfff;  //12
    uint8_t ID = 0;  //1
    uint8_t layer = 0;  //2
    uint8_t protection_absent = 1;  //1
    
    //3 byte
    int profile = 1;  //2
    int sampling_frequency_index = 7;  //4
    
    int private_bit = 0;  //1
    int channel_configuration = 2;  //3
    
    int original_copy = 0;  //1
    int home = 0;  //1
    
    int copyright_identification_bit = 0;  //1
    int copyright_identification_start = 0;  //1
    
    int aac_frame_length = 7+size;  //13     first2bit 4byte
    int adts_buffer_fullness = 0;  //11   0x7ff
    int number_of_raw_data_blocks_in_frame = 0;//2
    
    
//    char *puf = (char *)malloc(sizeof(char)*7);
    
    puf[0] = syncword;
    puf[1] = (syncword&0xf0)|(ID&0xf8)|(layer&0xf6)|(protection_absent&0xf1);
    puf[2] = ((profile<<6))|(sampling_frequency_index<<2)|(private_bit<<1)|(channel_configuration>>2);
    puf[3] = (channel_configuration<<6)|(original_copy<<5)|(home<<4)|(copyright_identification_bit<<3)|(copyright_identification_start<<2)|(aac_frame_length>>11);
    
    puf[4] = (aac_frame_length>>2);
    puf[5] = (aac_frame_length>>10)|(adts_buffer_fullness<<6);
    puf[6] = (adts_buffer_fullness>>5)|(number_of_raw_data_blocks_in_frame);
    
    
//    fwrite(puf, 1, 7, ifh);
//    free(puf);
}

@end
