//
//  DownloadFinishedCell.m
//  Router
//
//  Created by hupfei on 2018/12/13.
//  Copyright © 2018 CVN. All rights reserved.
//

#import "DownloadFinishedCell.h"

@interface DownloadFinishedCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@implementation DownloadFinishedCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.nameLabel.text = self.item.fileName;
    
    self.detailLabel.text = [NSString stringWithFormat:@"%@\t  %@", @(self.item.createTime), [HGDownloadUtils fileSizeStringFromBytes:self.item.totalSize]];
}

- (IBAction)deleteAction:(UIButton *)sender {
    [[HGDownloadManager manager] stopDownloadWithItem:self.item];
}


@end
