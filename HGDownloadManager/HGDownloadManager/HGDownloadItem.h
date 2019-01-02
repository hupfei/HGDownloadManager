//
//  HGDownloadItem.h
//  Test
//
//  Created by hupfei on 2018/12/25.
//  Copyright © 2018 yyets. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LKDBHelper/LKDBHelper.h>
@class HGDownloadItem;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kDownloadTaskFinishedNotification;

typedef NS_ENUM(NSUInteger, HGDownloadStatus) {
    HGDownloadStatusWaiting = 0,
    HGDownloadStatusDownloading,
    HGDownloadStatusPaused,
    HGDownloadStatusCanceled,
    HGDownloadStatusFinished,
    HGDownloadStatusFailed
};

typedef void (^HGProgressHandler)(int64_t downloadedSize, int64_t totalSize);
typedef void (^HGStatusHandler)(HGDownloadStatus status);

@protocol HGDownloadItemDelegate <NSObject>

@optional
- (void)downloadItem:(nonnull HGDownloadItem *)item statusChanged:(HGDownloadStatus)status;
- (void)downloadItem:(nonnull HGDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;
- (void)downloadItem:(nonnull HGDownloadItem *)item speedStr:(NSString *)speedStr;
@end

@interface HGDownloadItem : NSObject

@property (nonatomic, weak) id <HGDownloadItemDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *downloadUrl;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, assign) int64_t downloadedSize;
@property (nonatomic, assign) int64_t totalSize;
@property (nonatomic, assign) HGDownloadStatus downloadStatus;
@property (nonatomic, assign, readonly) NSUInteger createTime;
@property (nonatomic, assign) NSUInteger watchedTime;
/**
 下载的文件在沙盒保存的类型，默认为0视频, 文件类型，0视频 1音频 2图片 3其他
 */
@property (nonatomic, assign, readonly) NSUInteger fileType;

@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, copy, nullable) HGProgressHandler progressHandler;
@property (nonatomic, copy, nullable) HGStatusHandler statusHandler;

- (id)initWithUrl:(NSString *)url fileName:(NSString *)fileName fileType:(NSUInteger)fileType;

@end

NS_ASSUME_NONNULL_END
