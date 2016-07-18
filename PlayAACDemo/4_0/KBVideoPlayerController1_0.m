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
    
    for (; ; ) {
        previoustagsize = getw(flvbitstream);
        fread(&tagheader, sizeof(TAG_HEADER), 1, flvbitstream);
        int tagheader_datasize=tagheader.DataSize[0]*65536+tagheader.DataSize[1]*256+tagheader.DataSize[2];
        int tagheader_timestamp=tagheader.Timestamp[0]*65536+tagheader.Timestamp[1]*256+tagheader.Timestamp[2];
        
        printf("%6d %6d \n",tagheader_datasize,tagheader_timestamp);

        fread(buf, 1, tagheader_datasize, flvbitstream);
    }
    
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
