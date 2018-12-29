//
//  DownloadChildCell.m
//  Router
//
//  Created by hupfei on 2018/12/13.
//  Copyright © 2018 CVN. All rights reserved.
//

#import "DownloadChildCell.h"

@interface DownloadChildCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *startOrPauseBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizePercentLabel;

@end

@implementation DownloadChildCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.nameLabel.text = self.item.fileName;
    [self changeSizeLblDownloadedSize:self.item.downloadedSize totalSize:self.item.totalSize];
    [self setDownloadStatus:self.item.downloadStatus speed:@""];
}

- (IBAction)btnAction:(UIButton *)sender {
    if (sender.tag == 0) {
        //暂停/继续下载
        if (self.item.downloadStatus == HGDownloadStatusDownloading) {
            [[HGDownloadManager manager] pauseDownloadWithItem:self.item];
        } else {
            [[HGDownloadManager manager] resumeDownloadWithItem:self.item];
        }
    } else if (sender.tag == 1) {
        [[HGDownloadManager manager] stopDownloadWithItem:self.item];
    }
}


- (void)setDownloadStatus:(HGDownloadStatus)status speed:(NSString *)speed {
    self.startOrPauseBtn.selected = (status!=HGDownloadStatusDownloading);
    NSString *speedStr = @"0";
    if (status == HGDownloadStatusDownloading) {
        speedStr = speed;
    } else if (status == HGDownloadStatusPaused) {
        speedStr = @"已暂停";
    } else if (status == HGDownloadStatusWaiting) {
        speedStr = @"等待中···";
    } else if (status == HGDownloadStatusFailed) {
        speedStr = @"同步失败";
    }
    self.speedLabel.text = speedStr;
}

- (void)changeSizeLblDownloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize {
    if (totalSize <= 0) {
        self.sizePercentLabel.text = @"";
        self.progressView.progress = 0;
        self.sizeLabel.text = @"";
    } else {
        NSString *downloadedSizeStr = [NSByteCountFormatter stringFromByteCount:downloadedSize countStyle:NSByteCountFormatterCountStyleFile];
        NSString *totalSizeStr = [NSByteCountFormatter stringFromByteCount:totalSize countStyle:NSByteCountFormatterCountStyleFile];
        self.sizeLabel.text = [NSString stringWithFormat:@"%@/%@", downloadedSizeStr, totalSizeStr];
        
        CGFloat percent = (float)downloadedSize/totalSize;
        self.sizePercentLabel.text = [NSString stringWithFormat:@"%.2f%%", percent*100];
        self.progressView.progress = percent;
    }
}

#pragma mark- HGDownloadItem delegate
- (void)downloadItem:(nonnull HGDownloadItem *)item statusChanged:(HGDownloadStatus)status {
    NSLog(@"setDownloadStatus");

    [self setDownloadStatus:item.downloadStatus speed:@""];
}

- (void)downloadItem:(nonnull HGDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize {
    NSLog(@"changeSizeLblDownloadedSize");

    [self changeSizeLblDownloadedSize:downloadedSize totalSize:totalSize];
}

- (void)downloadItem:(nonnull HGDownloadItem *)item speedStr:(NSString *)speedStr {
    if (item.downloadStatus == HGDownloadStatusDownloading) {
        [self setDownloadStatus:HGDownloadStatusDownloading speed:speedStr];
    }
}

@end
