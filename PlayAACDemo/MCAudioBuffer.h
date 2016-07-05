//
//  MCAudioBuffer.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#import "MCParsedAudioData.h"


@interface MCAudioBuffer : NSObject

+ (instancetype)buffer;

- (void)enqueueData:(MCParsedAudioData *)data;
- (void)enqueueFromDataArray:(NSArray *)dataArray;

- (BOOL)hasData;
- (UInt32)bufferedSize;

//descriptions needs free
- (NSData *)dequeueDataWithSize:(UInt32)requestSize packetCount:(UInt32 *)packetCount descriptions:(AudioStreamPacketDescription **)descriptions;

@end
