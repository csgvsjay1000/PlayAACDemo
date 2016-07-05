//
//  ViewController.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "ViewController.h"
#import "KBAudioPlayer.h"
#import "KBAudioPlayer1_1.h"

@interface ViewController (){
//    KBAudioPlayer *audioPlayer;
    KBAudioPlayer1_1 *audioPlayer;

}

@end

@implementation ViewController

typedef unsigned char BYTE;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    audioPlayer = [[KBAudioPlayer1_1 alloc] init];
//    audioPlayer.fileType = kAudioFileAAC_ADTSType;


}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [audioPlayer simplest_mediadata_flv];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
