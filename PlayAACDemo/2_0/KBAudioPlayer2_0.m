//
//  KBAudioPlayer2_0.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/7/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "KBAudioPlayer2_0.h"
#import "KBAudioHeader.h"
#import "MCAudioBuffer2_0.h"

@interface KBAudioPlayer2_0 (){
    MCAudioBuffer2_0 *_buffer;
    UInt32 _bufferSize;
    
    UInt32 _readFileBufSize;
    
    uint8_t *aacBuffer;
    
    AudioFileStreamID _audioFileStreamID;
    
    AudioStreamBasicDescription _format;
    
}

@property (nonatomic,assign) MCSAPStatus status;


@end

@implementation KBAudioPlayer2_0

-(id)init{
    self = [super init];
    if (self) {
        _buffer = [MCAudioBuffer2_0 buffer];
    }
    return self;
}

#pragma mark - player controller



-(void)play{
    
    [NSThread detachNewThreadSelector:@selector(readFLVThread) toTarget:self withObject:nil];
    
//    [NSThread detachNewThreadSelector:@selector(threadMain) toTarget:self withObject:nil];
    
}

#pragma mark - thread

-(void)readFLVThread{
    
    _readFileBufSize = 2096;
    
    FILE *ifh = NULL;
    ifh = fopen([_urlStr UTF8String], "rb+");
    FLV_HEADER flv;
    TAG_HEADER tagheader;
    uint previoustagsize, previoustagsize_z=0;
    
    uint ts=0, ts_new=0;
    
    [self openFileParseStream:kAudioFileAAC_ADTSType];
    
    //FLV file header
    fread((char *)&flv,1,sizeof(FLV_HEADER),ifh);
    
    printf("============== FLV Header ==============\n");
    printf("Signature:  0x %c %c %c\n",flv.Signature[0],flv.Signature[1],flv.Signature[2]);
    printf("Version:    0x %X\n",flv.Version);
    printf("Flags  :    0x %X\n",flv.Flags);
    printf("HeaderSize: 0x %X\n",reverse_bytes((byte *)&flv.DataOffset, sizeof(flv.DataOffset)));
    printf("========================================\n");
    
    fseek(ifh, reverse_bytes((byte *)&flv.DataOffset, sizeof(flv.DataOffset)), SEEK_SET);
    aacBuffer = malloc(sizeof(char)*_readFileBufSize);
    
    do {
        
        previoustagsize = getw(ifh);
        
        fread((void *)&tagheader,sizeof(TAG_HEADER),1,ifh);
        int tagheader_datasize=tagheader.DataSize[0]*65536+tagheader.DataSize[1]*256+tagheader.DataSize[2];
        int tagheader_timestamp=tagheader.Timestamp[0]*65536+tagheader.Timestamp[1]*256+tagheader.Timestamp[2];
        
        char tagtype_str[10];
        switch(tagheader.TagType){
            case TAG_TYPE_AUDIO:sprintf(tagtype_str,"AUDIO");break;
            case TAG_TYPE_VIDEO:sprintf(tagtype_str,"VIDEO");break;
            case TAG_TYPE_SCRIPT:sprintf(tagtype_str,"SCRIPT");break;
            default:sprintf(tagtype_str,"UNKNOWN");break;
        }
        printf("[%6s] %6d %6d \n",tagtype_str,tagheader_datasize,tagheader_timestamp);
        
        switch (tagheader.TagType) {
            case TAG_TYPE_AUDIO:{
                char tagdata_first_byte;
                tagdata_first_byte=fgetc(ifh);

                char isACCsequenceHeader = fgetc(ifh);
                int data_size=reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize))-1;
                if(isACCsequenceHeader == 0x00){
                    char *ACCsequenceHeader = (char *)malloc(sizeof(char)*2);
                    fread(ACCsequenceHeader, sizeof(char), 2, ifh);
                    
                    data_size -= 3;
                }else if (isACCsequenceHeader == 0x01){
                    data_size -= 1;
                }
                write_adst_header(data_size, aacBuffer);
                if (fread(aacBuffer+7, 1, data_size, ifh) == data_size) {
                    NSData *data = [[NSData alloc] initWithBytes:aacBuffer length:data_size+7];
                    [self parseData:data error:nil];
                }
                
                break;
            }
            default:
                fseek(ifh, reverse_bytes((byte *)&tagheader.DataSize, sizeof(tagheader.DataSize)), SEEK_CUR);
                break;
        }
        
        
    } while (!feof(ifh));
    
}

-(void)threadMain{
    
    _bufferSize = 2098;
    
    while (self.status != MCSAPStatusStopped) {
        
        if ([_buffer bufferedSize]<_bufferSize) {
            
        }
        
    }
    
}

- (BOOL)parseData:(NSData *)data error:(NSError **)error{
    
    OSStatus status = AudioFileStreamParseBytes(_audioFileStreamID,(UInt32)[data length],[data bytes], 0);
    
    return YES;
}

-(void)openFileParseStream:(AudioFileTypeID)fileType{
    OSStatus status = AudioFileStreamOpen((__bridge void *)self,
                                          MCSAudioFileStreamPropertyListener,
                                          MCAudioFileStreamPacketsCallBack,
                                          kAudioFileAAC_ADTSType,
                                          &_audioFileStreamID);
    if (status != noErr)
    {
        _audioFileStreamID = NULL;
    }
}

#pragma mark - static callbacks
static void MCSAudioFileStreamPropertyListener(void *inClientData,
                                               AudioFileStreamID inAudioFileStream,
                                               AudioFileStreamPropertyID inPropertyID,
                                               UInt32 *ioFlags)
{
    KBAudioPlayer2_0 *audioFileStream = (__bridge KBAudioPlayer2_0 *)inClientData;
    [audioFileStream handleAudioFileStreamProperty:inPropertyID];
}

static void MCAudioFileStreamPacketsCallBack(void *inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void *inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions)
{
    KBAudioPlayer2_0 *audioFileStream = (__bridge KBAudioPlayer2_0 *)inClientData;
    [audioFileStream handleAudioFileStreamPackets:inInputData
                                    numberOfBytes:inNumberBytes
                                  numberOfPackets:inNumberPackets
                               packetDescriptions:inPacketDescriptions];
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
    
    
}


void write_adst_header(int size,unsigned char *puf){
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
