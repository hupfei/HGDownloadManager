//
//  ViewController.m
//  HGDownloadManager
//
//  Created by hupfei on 2018/12/29.
//  Copyright © 2018 hupfei. All rights reserved.
//

#import "RootViewController.h"
#import "HGDownloadHeader.h"

@interface RootViewController ()

@property (nonatomic, strong) NSArray *urls;

@property (nonatomic, strong) HGDownloadItem *item;
@property (nonatomic, strong) HGDownloadItem *item1;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.urls = @[@"https://mp4.1sj.tv/mp4/429783ccd0dc474749a21f0eaff9434b.mp4", @"http://192.168.3.45:8080/xiebuyazheng.mp4"];
    
    self.item = [[HGDownloadItem alloc] initWithUrl:self.urls[0] fileName:@"动漫" fileType:2];
    self.item1 = [[HGDownloadItem alloc] initWithUrl:self.urls[1] fileName:@"权利的游戏" fileType:1];
    
    [self localFile];
}

- (IBAction)startDownloadItem:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [[HGDownloadManager manager] startDownloadWithItem:self.item];
    } else {
        [[HGDownloadManager manager] pauseDownloadWithItem:self.item];
    }
}

- (IBAction)startDownloadItem1:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [[HGDownloadManager manager] startDownloadWithItem:self.item1];
    } else {
        [[HGDownloadManager manager] pauseDownloadWithItem:self.item1];
    }
}

-(void)localFile {
    NSString *BASE_PATH = [HGDownloadManager manager].savePath;
    
    // 工程目录
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [myFileManager enumeratorAtPath:BASE_PATH];
    
    //列举目录内容，可以遍历子目录
    for (NSString *path in myDirectoryEnumerator.allObjects) {
        NSLog(@"%@", path);
    }
}

@end
