//
//  MCAudioBuffer2_0.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/7/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "MCAudioBuffer2_0.h"

@interface MCAudioBuffer2_0 (){
@private
    NSMutableArray *_bufferBlockArray;
    UInt32 _bufferedSize;
}

@end

@implementation MCAudioBuffer2_0

+ (instancetype)buffer
{
    return [[self alloc] init];
}

- (UInt32)bufferedSize
{
    return _bufferedSize;
}

@end
