//
//  ViewController.m
//  PlayAACDemo
//
//  Created by chengshenggen on 7/5/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#import "ViewController.h"
#import "KBAudioPlayer.h"
//#import "KBAudioPlayer1_1.h"
#import "KBAudioPlayer2_0.h"
#import "KBVideoPlayerController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>{
//    KBAudioPlayer *audioPlayer;
//    KBAudioPlayer1_1 *audioPlayer;
    
    KBAudioPlayer2_0 *audioPlayer;

}

@property(nonatomic,strong)UITableView *tableView;

@end

@implementation ViewController

typedef unsigned char BYTE;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    audioPlayer = [[KBAudioPlayer1_1 alloc] init];
//    audioPlayer.fileType = kAudioFileAAC_ADTSType;

//    audioPlayer = [[KBAudioPlayer2_0 alloc] init];
    
    [self.view addSubview:self.tableView];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [audioPlayer simplest_mediadata_flv];
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"cuc_ieschool" ofType:@"flv"];
//    audioPlayer.urlStr = path;
//    [audioPlayer play];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"播放h264文件";
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KBVideoPlayerController *vc = [[KBVideoPlayerController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

-(UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-20)];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}


@end
