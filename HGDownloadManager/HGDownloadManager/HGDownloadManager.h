//
//  HGDownloadManager.h
//  Test
//
//  Created by hupfei on 2018/12/21.
//  Copyright © 2018 yyets. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HGDownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BGCompletedHandler)(void);

@interface HGDownloadManager : NSObject

@property (nonatomic, copy) NSString *savePath;

+ (HGDownloadManager *)manager;
//必须调用！
- (void)configWithMaxTaskCount:(NSInteger)count;

/** 开始一个后台下载任务 */
- (void)startDownloadWithItem:(HGDownloadItem *)item;
/** 通过url fileName开始一个后台下载任务 */
- (void)startDownloadWithUrl:(NSString *)url fileName:(NSString *)fileName;

/** 继续开始一个后台下载任务 */
- (void)resumeDownloadWithItem:(HGDownloadItem *)item;
/** 暂停一个后台下载任务 */
- (void)pauseDownloadWithItem:(HGDownloadItem *)item;

/** 暂停所有的下载 */
//+ (void)pauseAllDownloadTask;
///** 开始所有的下载 */
//+ (void)resumeAllDownloadTask;

/** 删除一个后台下载任务，同时会删除当前任务下载的缓存数据 */
- (void)stopDownloadWithItem:(HGDownloadItem *)item;

/** 获取下载的item */
- (HGDownloadItem *)itemWithUrl:(NSString *)url;

/** 获取所有的未完成的下载item */
- (nonnull NSArray *)downloadList;

/** 获取所有已完成的下载item */
- (nonnull NSArray *)finishList;

-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
