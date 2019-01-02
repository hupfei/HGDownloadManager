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

/** 删除一个后台下载任务，同时会删除当前任务下载的缓存数据 */
- (void)stopDownloadWithItem:(HGDownloadItem *)item;

/** 获取下载的item */
- (HGDownloadItem *)itemWithUrl:(NSString *)url;

/** 获取所有的未完成的下载item */
- (nonnull NSArray *)unfinishedItems;

/** 获取所有已完成的下载item */
- (nonnull NSArray *)finishedItems;

-(void)addCompletionHandler:(void (^)(void))completionHandler identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
