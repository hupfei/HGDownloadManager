//
//  HGDownloadItem.m
//  Test
//
//  Created by hupfei on 2018/12/25.
//  Copyright © 2018 yyets. All rights reserved.
//

#import "HGDownloadItem.h"
#import "HGDownloadUtils.h"
#import "HGDownloadManager.h"

NSString * const kDownloadTaskFinishedNotification = @"DownloadTaskFinishedNotification";

@interface HGDownloadItem () {
    NSUInteger _preDownloadedSize;
}

@property (nonatomic, copy, readwrite) NSString *downloadUrl;
@property (nonatomic, assign, readwrite) NSUInteger fileType;
@property (nonatomic, assign, readwrite) NSUInteger createTime;
@property (nonatomic, copy, readwrite) NSString *fileName;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation HGDownloadItem

- (id)initWithUrl:(NSString *)url fileName:(NSString *)fileName fileType:(NSUInteger)fileType {
    self = [super init];
    if (self) {
        self.downloadUrl = url;
        self.fileName = fileName;
        self.fileType = fileType;
        self.createTime = [HGDownloadUtils sec_timestamp];
    }
    return self;
}

- (HGProgressHandler)progressHandler {
    __weak typeof(self) weakSelf = self;
    return ^(int64_t downloadedSize, int64_t totalSize){
        weakSelf.downloadedSize = downloadedSize;
        if (weakSelf.totalSize == 0 || weakSelf.downloadStatus == HGDownloadStatusFinished) {
            weakSelf.totalSize = totalSize;
            [weakSelf updateToDB];
        }
        
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(downloadItem:downloadedSize:totalSize:)]) {
            [weakSelf.delegate downloadItem:weakSelf downloadedSize:downloadedSize totalSize:totalSize];
        }
        
        [weakSelf startTimer];
    };
}

- (HGStatusHandler)statusHandler {
    __weak typeof(self) weakSelf = self;
    return ^(HGDownloadStatus status){
        weakSelf.downloadStatus = status;
        BOOL isExists = [[HGDownloadItem getUsingLKDBHelper] isExistsWithTableName:HGDownloadItem.getTableName where:@{@"downloadUrl":weakSelf.downloadUrl}];
        if (isExists) {
            [weakSelf updateToDB];
        } else {
            [weakSelf saveToDB];
        }
        
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(downloadItem:statusChanged:)]) {
            [weakSelf.delegate downloadItem:weakSelf statusChanged:status];
        }
        if (status == HGDownloadStatusFinished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadTaskFinishedNotification object:self];
        }
    };
}


- (void)startTimer {
    if (self.timer) {
        return;
    }
    
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerCall) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerCall {
    NSUInteger speed = _downloadedSize - _preDownloadedSize;
    _preDownloadedSize = _downloadedSize;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadItem:speedStr:)]) {
            [self.delegate downloadItem:self speedStr:[NSString stringWithFormat:@"%@/S",[HGDownloadUtils fileSizeStringFromBytes:speed]]];
        }
    });
}

- (void)dealloc {
    [self stopTimer];
}

#pragma mark- db

//重载选择 使用的LKDBHelper
+ (LKDBHelper *)getUsingLKDBHelper {
    static LKDBHelper *_db;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *dbPath = [HGDownloadManager manager].savePath;
        _db = [[LKDBHelper alloc] initWithDBPath:[dbPath stringByAppendingPathComponent:@"HGDownload.db"]];
    });
    return _db;
}

+ (void)initialize {
    //移除掉 不要的属性
    [self removePropertyWithColumnNameArray:@[@"downloadTask", @"resumeData", @"delegate", @"timer", @"progressHandler", @"statusHandler"]];
}

//主键
+ (NSString *)getPrimaryKey {
    return @"downloadUrl";
}

//表名
+ (NSString *)getTableName {
    return @"HGDownloadTable";
}

@end
