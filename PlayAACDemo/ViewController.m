//
//  ViewController.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "ViewController.h"
#import "KBAudioPlayer.h"

@interface ViewController (){
    KBAudioPlayer *audioPlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    audioPlayer = [[KBAudioPlayer alloc] init];
    audioPlayer.fileType = kAudioFileAAC_ADTSType;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
