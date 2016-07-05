//
//  MCParsedAudioData.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MCParsedAudioData : NSObject

@property (nonatomic,readonly) NSData *data;
@property (nonatomic,readonly) AudioStreamPacketDescription packetDescription;

+ (instancetype)parsedAudioDataWithBytes:(const void *)bytes
                       packetDescription:(AudioStreamPacketDescription)packetDescription;

@end
