//
//  DownloadingViewController.m
//  HGDownloadManager
//
//  Created by hupfei on 2018/12/29.
//  Copyright © 2018 hupfei. All rights reserved.
//

#import "DownloadingViewController.h"
#import "HGDownloadHeader.h"
#import "DownloadChildCell.h"

@interface DownloadingViewController ()

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation DownloadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArray = [[HGDownloadManager manager] unfinishedItems];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DownloadChildCell" bundle:nil] forCellReuseIdentifier:@"DownloadChildCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HGDownloadItem *item = self.dataArray[indexPath.row];
    DownloadChildCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadChildCell" forIndexPath:indexPath];
    cell.item = item;
    item.delegate = cell;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
