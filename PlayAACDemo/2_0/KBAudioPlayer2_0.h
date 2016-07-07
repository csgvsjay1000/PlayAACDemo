//
//  KBAudioPlayer2_0.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/7/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KBAudioPlayer2_0 : NSObject

@property(nonatomic,copy)NSString *urlStr;

-(void)play;

-(void)pause;

-(void)stop;



@end
