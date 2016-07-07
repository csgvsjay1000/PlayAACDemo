//
//  KBAudioHeader.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/7/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#ifndef KBAudioHeader_h
#define KBAudioHeader_h

#import <AVFoundation/AVFoundation.h>
#import <pthread.h>

typedef NS_ENUM(NSUInteger, MCSAPStatus)
{
    MCSAPStatusStopped = 0,
    MCSAPStatusPlaying = 1,
    MCSAPStatusWaiting = 2,
    MCSAPStatusPaused = 3,
    MCSAPStatusFlushing = 4,
};

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

#endif /* KBAudioHeader_h */
