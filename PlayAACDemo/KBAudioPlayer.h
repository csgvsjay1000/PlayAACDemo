//
//  KBAudioPlayer.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KBAudioPlayer : NSObject

@property(nonatomic,assign)AudioFileTypeID fileType;

-(void)paly;



@end
