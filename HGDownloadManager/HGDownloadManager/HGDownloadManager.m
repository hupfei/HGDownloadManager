//
//  HGDownloadManager.m
//  Test
//
//  Created by hupfei on 2018/12/21.
//  Copyright © 2018 yyets. All rights reserved.
//

#import "HGDownloadManager.h"
#import "HGDownloadUtils.h"

@interface HGDownloadManager ()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) LKDBHelper *dbHelper;
@property (nonatomic, assign) NSUInteger maxTaskCount;

/**
 key : url
 value : item
 */
@property (nonatomic, strong) NSMutableDictionary *itemDict;
@property (nonatomic, strong) NSMutableArray *runningItems;
@property (nonatomic, strong) NSMutableArray *waittingItems;

@end

@implementation HGDownloadManager

#pragma mark- init相关
+ (HGDownloadManager *)manager {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        NSString *identifier = [NSString stringWithFormat:@"%@.HGDownloadManager", bundleId];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        configuration.timeoutIntervalForRequest = 10;
        configuration.allowsCellularAccess = YES;
        
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseAllDownloadTask) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)configWithMaxTaskCount:(NSInteger)count {
    self.maxTaskCount = 3;
    
    self.itemDict = [NSMutableDictionary dictionary];
    __weak typeof(self) weakSelf = self;
    [self.dbHelper search:HGDownloadItem.class where:nil orderBy:@"createTime" offset:0 count:10000 callback:^(NSMutableArray * _Nullable array) {
        for (HGDownloadItem *item in array) {
            weakSelf.itemDict[item.downloadUrl] = item;
        }
    }];
}

- (NSMutableArray *)runningItems {
    if (!_runningItems) {
        _runningItems = [NSMutableArray array];
    }
    return _runningItems;
}

- (NSMutableArray *)waittingItems {
    if (!_waittingItems) {
        _waittingItems = [NSMutableArray array];
    }
    return _waittingItems;
}

- (LKDBHelper *)dbHelper {
    if (!_dbHelper) {
        _dbHelper = [HGDownloadItem getUsingLKDBHelper];
    }
    return _dbHelper;
}

- (NSString *)savePath {
    if (!_savePath) {
        NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        _savePath = [saveDir stringByAppendingPathComponent:@"HGDownload"];
        [HGDownloadUtils createPathIfNotExist:_savePath];
        NSLog(@"%@", _savePath);
    }
    return _savePath;
}

#pragma mark- public method

- (void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier {
    NSLog(@"addCompletionHandler:%@", identifier);
}

- (void)startDownloadWithUrl:(NSString *)url fileName:(NSString *)fileName {
    HGDownloadItem *item = [[HGDownloadItem alloc] initWithUrl:url fileName:fileName fileType:0];
    [self startDownloadWithItem:item];
}

- (void)startDownloadWithItem:(HGDownloadItem *)item {
    NSAssert(item.downloadUrl.length > 0, @"下载地址为空");
    HGDownloadItem *searchItem = [[HGDownloadItem getUsingLKDBHelper] searchSingle:HGDownloadItem.class where:@{@"downloadUrl":item.downloadUrl} orderBy:nil];
    if (searchItem.downloadStatus == HGDownloadStatusFinished || searchItem.downloadStatus == HGDownloadStatusDownloading) {
        return;
    }
    if (self.runningItems.count >= self.maxTaskCount) {
        //超过了最大下载数，则置该任务为等待状态
        item.downloadStatus = HGDownloadStatusWaiting;
        item.statusHandler(HGDownloadStatusWaiting);
        [self.waittingItems addObject:item];
        return;
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:item.downloadUrl]];
    NSString *resumePath = [self getResumeDataPathWithUrl:item.downloadUrl];
    if (item.resumeData || [HGDownloadUtils fileExistsWithPath:resumePath]) {
        [self resumeDownloadWithItem:item];
        return;
    }
    
    item.downloadTask = [self.session downloadTaskWithRequest:request];
    [item.downloadTask resume];
    
    item.downloadStatus = HGDownloadStatusDownloading;
    item.statusHandler(HGDownloadStatusDownloading);
    
    //添加到下载队列
    self.itemDict[item.downloadUrl] = item;
    [self.runningItems addObject:item];
}

//继续下载
- (void)resumeDownloadWithItem:(HGDownloadItem *)item {
    NSData *fileResumeData = [NSData dataWithContentsOfFile:[self getResumeDataPathWithUrl:item.downloadUrl]];
    item.downloadTask = [self.session downloadTaskWithResumeData:item.resumeData?:fileResumeData];
    [item.downloadTask resume];
    
    item.downloadStatus = HGDownloadStatusDownloading;
    item.statusHandler(HGDownloadStatusDownloading);
    
    [self.waittingItems removeObject:item];
    [self.runningItems addObject:item];
}

- (void)pauseDownloadWithItem:(HGDownloadItem *)item {
    item.downloadStatus = HGDownloadStatusPaused;
    [item updateToDB];
    
    [item.downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        item.resumeData = resumeData;
    }];
}

- (void)stopDownloadWithItem:(HGDownloadItem *)item {
    if (item == nil) {
        return;
    }
    item.downloadStatus = HGDownloadStatusCanceled;
    [item.downloadTask cancel];
    
    //删除下载文件
    [HGDownloadUtils removeFileIfExist:item.filePath];
    
    //删除resumeData
    [HGDownloadUtils removeFileIfExist:[self getResumeDataPathWithUrl:item.downloadUrl]];
    
    //删除数据库中的该记录
    BOOL isExist = [self.dbHelper isExistsWithTableName:HGDownloadItem.getTableName where:@{@"downloadUrl":item.downloadUrl}];
    if (isExist) {
        [item deleteToDB];
    }
}

- (HGDownloadItem *)itemWithUrl:(NSString *)url {
    HGDownloadItem *item = self.itemDict[url];
    if (item == nil) {
        //从数据库中查找
        item = [self.dbHelper searchSingle:HGDownloadItem.class where:@{@"downloadUrl":url} orderBy:nil];
    }
    return item;
}

//获取所有的未完成的下载item
- (nonnull NSArray *)downloadList {
    return [self.dbHelper search:HGDownloadItem.class withSQL:@"select * from @t where downloadStatus != %lu ORDER BY createTime", HGDownloadStatusFinished];
}

//获取所有已完成的下载item
- (nonnull NSArray *)finishList {
    return [self.dbHelper search:HGDownloadItem.class withSQL:@"select * from @t where downloadStatus = %lu ORDER BY createTime", HGDownloadStatusFinished];
}

#pragma mark- private method
- (void)startNextDownload {
    HGDownloadItem *item = self.waittingItems.firstObject;
    if (item && item.downloadStatus == HGDownloadStatusWaiting) {
        [self.waittingItems removeObject:item];
        [self startDownloadWithItem:item];
    }else{
        NSLog(@"[startNextDownload] all download task finished");
    }
}

- (NSString *)getResumeDataPathWithUrl:(NSString *)url {
    return [self.savePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.data", [HGDownloadUtils md5ForString:url]]];
}

- (BOOL)downloadFinishedWithItem:(HGDownloadItem *)item {
    int64_t localFileSize = [HGDownloadUtils fileSizeWithPath:item.filePath];
    return localFileSize>0 && localFileSize == item.totalSize;
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    [self startNextDownload];

    NSString *url = [HGDownloadUtils urlStrWithDownloadTask:downloadTask];
    HGDownloadItem *item = [self itemWithUrl:url];
    if (item == nil) {
        return;
    }
    NSError *error;
    NSString *movePath = [self.savePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", item.fileName, [HGDownloadUtils getFileExtensionWithTask:downloadTask]]];
    BOOL result = [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:movePath error:&error];
    if (result) {
        item.downloadStatus = HGDownloadStatusFinished;
    } else {
        item.downloadStatus = HGDownloadStatusFailed;
    }
    item.filePath = movePath;
    item.statusHandler(item.downloadStatus);
    
    [self.runningItems removeObject:item];
    
    //移除保存的resumeData
    [HGDownloadUtils removeFileIfExist:[self getResumeDataPathWithUrl:item.downloadUrl]];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *url = [HGDownloadUtils urlStrWithDownloadTask:downloadTask];
    HGDownloadItem *item = [self itemWithUrl:url];
    if (item) {
        item.progressHandler(totalBytesWritten, totalBytesExpectedToWrite);
    }

    NSLog(@"percent:%.2f%%",(float)totalBytesWritten / totalBytesExpectedToWrite * 100);
}

/*
 * 该方法下载成功和失败都会回调
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDownloadTask *)downloadTask
didCompleteWithError:(NSError *)error {
    if (!error){
        return;
    }
    
    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
    if (resumeData == nil) {
        return;
    }
    
    //下载失败/暂停
    NSString *url = [HGDownloadUtils urlStrWithDownloadTask:downloadTask];
    HGDownloadItem *item = [self itemWithUrl:url];
    if (item == nil || item.downloadStatus == HGDownloadStatusCanceled) {
        if (item.downloadStatus == HGDownloadStatusCanceled) {
            [self.runningItems removeObject:item];
            [self.waittingItems removeObject:item];
        }
        
        //开始下一个下载
        [self startNextDownload];
        return;
    }
    
    //开始下一个下载
    [self startNextDownload];
    
    item.resumeData = resumeData;
    if (item.downloadStatus != HGDownloadStatusPaused) {
        //用户手动暂停的则不需要改变状态
        item.downloadStatus = HGDownloadStatusFailed;
    }
    item.statusHandler(item.downloadStatus);
    
    [self.runningItems removeObject:item];
    [self.waittingItems addObject:item];
    
    NSString *resumeDataPath = [self getResumeDataPathWithUrl:item.downloadUrl];
    [HGDownloadUtils removeFileIfExist:resumeDataPath];
    BOOL isWriteData = [resumeData writeToFile:resumeDataPath atomically:YES];
    if (isWriteData) { NSLog(@"resumeData 文件写入成功"); }
}

@end
