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
        self.maxTaskCount = 3;
        
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
    self.maxTaskCount = count;
    
    self.itemDict = [NSMutableDictionary dictionary];
    __weak typeof(self) weakSelf = self;
    [self.dbHelper search:HGDownloadItem.class where:nil orderBy:@"createTime" offset:0 count:0 callback:^(NSMutableArray * _Nullable array) {
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
        NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _savePath = [saveDir stringByAppendingPathComponent:@"HGDownload"];
        [HGDownloadUtils createPathIfNotExist:_savePath];
        NSLog(@"%@", _savePath);
    }
    return _savePath;
}

#pragma mark- public method

-(void)addCompletionHandler:(void (^)(void))completionHandler identifier:(NSString *)identifier {
    NSLog(@"addCompletionHandler:%@", identifier);
    completionHandler();
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
        //添加到下载队列
        self.itemDict[item.downloadUrl] = item;
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
    if (fileResumeData == nil) {
        [self startDownloadWithItem:item];
        return;
    }
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
    if (item.downloadStatus == HGDownloadStatusDownloading) {
        [self.runningItems removeObject:item];
    }
    [self.itemDict removeObjectForKey:item.downloadUrl];
    
    //删除下载文件
    [HGDownloadUtils removeFileIfExist:item.filePath];
    
    //删除resumeData
    [HGDownloadUtils removeFileIfExist:[self getResumeDataPathWithUrl:item.downloadUrl]];
    
    //删除数据库中的该记录
    BOOL isExist = [self.dbHelper isExistsWithTableName:HGDownloadItem.getTableName where:@{@"downloadUrl":item.downloadUrl}];
    if (isExist) {
        [item deleteToDB];
    }
    
    [item.downloadTask cancel];
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
- (nonnull NSArray *)unfinishedItems {
//    return [self.dbHelper search:HGDownloadItem.class where:[NSString stringWithFormat:@"downloadStatus!=%@", @(HGDownloadStatusFinished)] orderBy:@"createTime" offset:0 count:0];
    NSMutableArray *listArray = [NSMutableArray array];
    for (HGDownloadItem *item in self.itemDict.allValues) {
        if (item.downloadStatus != HGDownloadStatusFinished) {
            [listArray addObject:item];
        }
    }
    return listArray.copy;
}

//获取所有已完成的下载item
- (nonnull NSArray *)finishedItems {
    return [self.dbHelper search:HGDownloadItem.class where:@{@"downloadStatus":@(HGDownloadStatusFinished)} orderBy:@"createTime" offset:0 count:0];
}

#pragma mark- private method

/**
 开始下一个下载任务

 @param curItem 当前正在下载的item
 */
- (void)startNextItemAfterDeleteCurItem:(HGDownloadItem *)curItem {
    [self.runningItems removeObject:curItem];
    
    HGDownloadItem *item = self.waittingItems.firstObject;
    if (item && item.downloadStatus == HGDownloadStatusWaiting) {
        [self startDownloadWithItem:item];
        [self.waittingItems removeObject:item];
    } else {
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

- (HGDownloadItem *)itemWithDownloadTask:(NSURLSessionDownloadTask *)task {
    NSString *url = [HGDownloadUtils urlStrWithDownloadTask:task];
    return [self itemWithUrl:url];
}


#pragma mark - NSURLSessionDownloadDelegate
/* 应用在后台，而且后台所有下载任务完成后，
 * 在所有其他NSURLSession和NSURLSessionDownloadTask委托方法执行完后回调，
 * 可以在该方法中做下载数据管理和UI刷新
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

/* 下载过程中调用，用于跟踪下载进度
 * bytesWritten为单次下载大小
 * totalBytesWritten为当当前一共下载大小
 * totalBytesExpectedToWrite为文件大小
 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    HGDownloadItem *item = [self itemWithDownloadTask:downloadTask];
    if (item) {
        item.progressHandler(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

//下载完成
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    HGDownloadItem *item = [self itemWithDownloadTask:downloadTask];
    
    [self startNextItemAfterDeleteCurItem:item];

    if (item == nil) {
        //数据库中找不到该记录
        [HGDownloadUtils removeFileIfExist:[self getResumeDataPathWithUrl:item.downloadUrl]];
        return;
    }
    int64_t itemSize = [HGDownloadUtils fileSizeWithPath:location.path];
    if (itemSize > 0 && item.totalSize == 0) {
        item.totalSize = itemSize;
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
    item.progressHandler(itemSize, itemSize);
    
    //移除保存的resumeData
    [HGDownloadUtils removeFileIfExist:[self getResumeDataPathWithUrl:item.downloadUrl]];
}

/* 在任务下载完成、下载失败
 * 或者是应用被杀掉后，重新启动应用并创建相关identifier的Session时调用
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDownloadTask *)downloadTask
didCompleteWithError:(NSError *)error {
    HGDownloadItem *item = [self itemWithDownloadTask:downloadTask];
    [self startNextItemAfterDeleteCurItem:item];
    
    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
    if (!error || resumeData == nil){
        return;
    }
    
    if (item == nil) {
        //数据库中找不到该记录
        [HGDownloadUtils removeFileIfExist:[self getResumeDataPathWithUrl:item.downloadUrl]];
        return;
    }
    
    //用户暂停或者下载失败
    item.resumeData = resumeData;
    if (item.downloadStatus != HGDownloadStatusPaused) {
        //用户手动暂停的则不需要改变状态
        item.downloadStatus = HGDownloadStatusFailed;
    }
    item.statusHandler(item.downloadStatus);
    [self.waittingItems addObject:item];
    
    //保存resumeData
    NSString *resumeDataPath = [self getResumeDataPathWithUrl:item.downloadUrl];
    [HGDownloadUtils removeFileIfExist:resumeDataPath];
    [resumeData writeToFile:resumeDataPath atomically:YES];
}

@end
