//
//  KBVideoPlayerController1_0.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/18/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "KBVideoPlayerController1_0.h"
#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "KBAudioHeader.h"
#import "KBPlayerHeader.h"

@interface KBAVAudioBuffer : NSObject

@property(nonatomic,assign)TAG_HEADER header;
//@property(nonatomic,strong)
@end

@implementation KBAVAudioBuffer

@end



@interface KBVideoPlayerController1_0 (){
    FILE *flvbitstream;
    FLV_HEADER flv;
    TAG_HEADER tagheader;
    
    pthread_mutex_t read_mutex;
    pthread_cond_t read_cond;
}

@property(nonatomic,strong)UIButton *backButton;

@end

@implementation KBVideoPlayerController1_0

-(void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.backButton];
    
    [NSThread detachNewThreadSelector:@selector(playVideo) toTarget:self withObject:nil];
}

-(void)playVideo{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cuc_ieschool" ofType:@"flv"];
    flvbitstream = fopen([path UTF8String], "rb");
    
    fread(&flv, sizeof(FLV_HEADER), 1, flvbitstream);
    flv.DataOffset = CFSwapInt32BigToHost(flv.DataOffset);
    printf("%d",flv.DataOffset);
     ;
    
    pthread_mutex_init(&read_mutex, NULL);
    pthread_cond_init(&read_cond, NULL);
    
    uint8_t *buf = malloc(sizeof(char)*1024*10);
    
    uint previoustagsize = 0;
    
    KBPacket *packet= NULL;
    packet = (KBPacket *)malloc(sizeof(KBPacket));
    
    for (; ; ) {
        previoustagsize = getw(flvbitstream);
        fread(&tagheader, sizeof(TAG_HEADER), 1, flvbitstream);
        int tagheader_datasize=tagheader.DataSize[0]*65536+tagheader.DataSize[1]*256+tagheader.DataSize[2];
        int tagheader_timestamp=tagheader.Timestamp[0]*65536+tagheader.Timestamp[1]*256+tagheader.Timestamp[2];
        
        printf("%6d %6d \n",tagheader_datasize,tagheader_timestamp);

        fread(buf, 1, tagheader_datasize, flvbitstream);
        
        switch (tagheader.TagType) {
            case TAG_TYPE_AUDIO:{
                char tagdata_first_byte;
                tagdata_first_byte=fgetc(flvbitstream);
                char isACCsequenceHeader = fgetc(flvbitstream);
                
                
                
                
                break;
            }
                
                
                
            default:
                break;
        }
        
    }
    
}

#pragma mark - private methods
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

#pragma mark - button response
-(void)backButtonActions{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - setters and getters
-(UIButton *)backButton{
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backButton setTitle:@"返回" forState:UIControlStateNormal];
        _backButton.frame = CGRectMake(0, 20, 60, 30);
        [_backButton addTarget:self action:@selector(backButtonActions) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

@end
