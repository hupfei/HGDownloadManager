//
//  FinishedViewController.m
//  HGDownloadManager
//
//  Created by hupfei on 2018/12/29.
//  Copyright © 2018 hupfei. All rights reserved.
//

#import "FinishedViewController.h"
#import "DownloadFinishedCell.h"

@interface FinishedViewController ()

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation FinishedViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArray = [[HGDownloadManager manager] finishedItems];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DownloadFinishedCell" bundle:nil] forCellReuseIdentifier:@"DownloadFinishedCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadFinishedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadFinishedCell" forIndexPath:indexPath];
    cell.item = self.dataArray[indexPath.row];
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
