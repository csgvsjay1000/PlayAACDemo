//
//  KBVideoPlayerController.m
//  PlayAACDemo
//
//  Created by feng on 16/7/10.
//  Copyright © 2016年 Gan Tian. All rights reserved.
//

#import "KBVideoPlayerController.h"
#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    NALU_TYPE_SLICE    = 1,
    NALU_TYPE_DPA      = 2,
    NALU_TYPE_DPB      = 3,
    NALU_TYPE_DPC      = 4,
    NALU_TYPE_IDR      = 5,
    NALU_TYPE_SEI      = 6,
    NALU_TYPE_SPS      = 7,
    NALU_TYPE_PPS      = 8,
    NALU_TYPE_AUD      = 9,
    NALU_TYPE_EOSEQ    = 10,
    NALU_TYPE_EOSTREAM = 11,
    NALU_TYPE_FILL     = 12,
} NaluType;

typedef enum {
    NALU_PRIORITY_DISPOSABLE = 0,
    NALU_PRIRITY_LOW         = 1,
    NALU_PRIORITY_HIGH       = 2,
    NALU_PRIORITY_HIGHEST    = 3
} NaluPriority;


typedef struct
{
    int startcodeprefix_len;      //! 4 for parameter sets and first slice in picture, 3 for everything else (suggested)
    unsigned int len;                 //! Length of the NAL unit (Excluding the start code, which does not belong to the NALU)
    unsigned max_size;            //! Nal Unit Buffer size
    int forbidden_bit;            //! should be always FALSE
    int nal_reference_idc;        //! NALU_PRIORITY_xxxx
    int nal_unit_type;            //! NALU_TYPE_xxxx
    char *buf;                    //! contains the first byte followed by the EBSP
} NALU_t;

@interface KBVideoPlayerController (){
    FILE *h264bitstream;
    int info2, info3;
    
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    AAPLEAGLLayer *_glLayer;
    
    AVSampleBufferDisplayLayer *videolayer;
    
    BOOL _isChange;
}

@property(nonatomic,strong)UIButton *backButton;



@end

@implementation KBVideoPlayerController

-(void)viewDidLoad{
    [super viewDidLoad];
    _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];

    [self.view.layer addSublayer:_glLayer];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.backButton];
    
    [NSThread detachNewThreadSelector:@selector(playVideo) toTarget:self withObject:nil];

}

-(void)playVideo{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"h264"];
    [self simplest_h264_parser:[path UTF8String]];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

#pragma mark - decode h264
static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}


-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}

-(CVPixelBufferRef)decode:(NALU_t *)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)vp->buf, vp->len+4,
                                                          kCFAllocatorNull,
                                                          NULL, 0, vp->len+4,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp->len+4};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}


#pragma mark - parse h264
-(int) simplest_h264_parser:(const char *)url{
    
    NALU_t *n;
    int buffersize=100000;
    
    //FILE *myout=fopen("output_log.txt","wb+");
    FILE *myout=stdout;
    
    h264bitstream=fopen(url, "rb+");
    if (h264bitstream==NULL){
        printf("Open file error\n");
        return 0;
    }
    
    n = (NALU_t*)calloc (1, sizeof (NALU_t));
    if (n == NULL){
        printf("Alloc NALU Error\n");
        return 0;
    }
    
    n->max_size=buffersize;
    n->buf = (char*)calloc (buffersize, sizeof (char));
    if (n->buf == NULL){
        free (n);
        printf ("AllocNALU: n->buf");
        return 0;
    }
    
    int data_offset=0;
    int nal_num=0;
    printf("-----+-------- NALU Table ------+---------+\n");
    printf(" NUM |    POS  |    IDC |  TYPE |   LEN   |\n");
    printf("-----+---------+--------+-------+---------+\n");
    
    while(!feof(h264bitstream))
    {
        int data_lenth;
        data_lenth=[self GetAnnexbNALU:n];
        
        char type_str[20]={0};
        CVPixelBufferRef pixelBuffer = NULL;
        switch (n->nal_unit_type) {
            case NALU_TYPE_IDR:
                if ([self initH264Decoder]) {
                    pixelBuffer = [self decode:n];
                }
                break;
            case NALU_TYPE_SPS:
                _spsSize = n->len;
                _sps = malloc(_spsSize);
                memcpy(_sps, n->buf + 4, _spsSize);
                break;
            case NALU_TYPE_PPS:
                _ppsSize = n->len;
                _pps = malloc(_ppsSize);
                memcpy(_pps, n->buf + 4, _ppsSize);
                break;

            default:
                pixelBuffer = [self decode:n];
                break;
        }
        if(pixelBuffer) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                _glLayer.pixelBuffer = pixelBuffer;
            });
            
            CVPixelBufferRelease(pixelBuffer);
        }
        
        data_offset=data_offset+data_lenth;
        
        nal_num++;
    }
    
    //Free
    if (n){
        if (n->buf){
            free(n->buf);
            n->buf=NULL;
        }
        free (n);
    }

    
    return 0;
}

static int FindStartCode2 (unsigned char *Buf){
    if(Buf[0]!=0 || Buf[1]!=0 || Buf[2] !=1) return 0; //0x000001?
    else return 1;
}

static int FindStartCode3 (unsigned char *Buf){
    if(Buf[0]!=0 || Buf[1]!=0 || Buf[2] !=0 || Buf[3] !=1) return 0;//0x00000001?
    else return 1;
}


-(int) GetAnnexbNALU:(NALU_t *)nalu{
    int pos = 0;
    int StartCodeFound, rewind;
    unsigned char *Buf;
    
    if ((Buf = (unsigned char*)calloc (nalu->max_size , sizeof(char))) == NULL)
        printf ("GetAnnexbNALU: Could not allocate Buf memory\n");
    
    nalu->startcodeprefix_len=3;
    
    if (3 != fread (Buf, 1, 3, h264bitstream)){
        free(Buf);
        return 0;
    }
    info2 = FindStartCode2 (Buf);
    if(info2 != 1) {
        if(1 != fread(Buf+3, 1, 1, h264bitstream)){
            free(Buf);
            return 0;
        }
        info3 = FindStartCode3 (Buf);
        if (info3 != 1){
            free(Buf);
            return -1;
        }
        else {
            pos = 4;
            nalu->startcodeprefix_len = 4;
        }
    }
    else{
        nalu->startcodeprefix_len = 3;
        pos = 3;
    }
    StartCodeFound = 0;
    info2 = 0;
    info3 = 0;
    
    while (!StartCodeFound){
        if (feof (h264bitstream)){
            nalu->len = (pos-1)-nalu->startcodeprefix_len;
            
            uint32_t nalSize = (uint32_t)(nalu->len);
            uint8_t *pNalSize = (uint8_t*)(&nalSize);
            nalu->buf[0] = *(pNalSize + 3);
            nalu->buf[1] = *(pNalSize + 2);
            nalu->buf[2] = *(pNalSize + 1);
            nalu->buf[3] = *(pNalSize);
            
            memcpy (nalu->buf+4, &Buf[nalu->startcodeprefix_len], nalu->len);//
            nalu->forbidden_bit = nalu->buf[4] & 0x80; //1 bit
            nalu->nal_reference_idc = nalu->buf[4] & 0x60; // 2 bit
            nalu->nal_unit_type = (nalu->buf[4]) & 0x1f;// 5 bit

            
            
//            memcpy (nalu->buf, &Buf[nalu->startcodeprefix_len], nalu->len);
//            nalu->forbidden_bit = nalu->buf[0] & 0x80; //1 bit
//            nalu->nal_reference_idc = nalu->buf[0] & 0x60; // 2 bit
//            nalu->nal_unit_type = (nalu->buf[0]) & 0x1f;// 5 bit
            free(Buf);
            return pos-1;
        }
        Buf[pos++] = fgetc (h264bitstream);
        info3 = FindStartCode3(&Buf[pos-4]);
        if(info3 != 1)
            info2 = FindStartCode2(&Buf[pos-3]);
        StartCodeFound = (info2 == 1 || info3 == 1);
    }
    
    // Here, we have found another start code (and read length of startcode bytes more than we should
    // have.  Hence, go back in the file
    rewind = (info3 == 1)? -4 : -3;
    
    if (0 != fseek (h264bitstream, rewind, SEEK_CUR)){
        free(Buf);
        printf("GetAnnexbNALU: Cannot fseek in the bit stream file");
    }
    
    // Here the Start code, the complete NALU, and the next start code is in the Buf.
    // The size of Buf is pos, pos+rewind are the number of bytes excluding the next
    // start code, and (pos+rewind)-startcodeprefix_len is the size of the NALU excluding the start code
    
    nalu->len = (pos+rewind)-nalu->startcodeprefix_len;
    uint32_t nalSize = (uint32_t)(nalu->len);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    nalu->buf[0] = *(pNalSize + 3);
    nalu->buf[1] = *(pNalSize + 2);
    nalu->buf[2] = *(pNalSize + 1);
    nalu->buf[3] = *(pNalSize);

    memcpy (nalu->buf+4, &Buf[nalu->startcodeprefix_len], nalu->len);//
    nalu->forbidden_bit = nalu->buf[4] & 0x80; //1 bit
    nalu->nal_reference_idc = nalu->buf[4] & 0x60; // 2 bit
    nalu->nal_unit_type = (nalu->buf[4]) & 0x1f;// 5 bit
    free(Buf);
    
    return (pos+rewind);
}


-(void)backButtonActions{
    [self dismissViewControllerAnimated:YES completion:nil];
}

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
