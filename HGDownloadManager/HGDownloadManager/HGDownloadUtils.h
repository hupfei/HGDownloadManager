//
//  HGDownloadUtils.h
//  Test
//
//  Created by hupfei on 2018/12/25.
//  Copyright © 2018 yyets. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HGDownloadUtils : NSObject

/**  获取当前手机的空闲磁盘空间 */
+ (int64_t)fileSystemFreeSize;

/** 将文件的字节大小，转换成更加容易识别的大小KB，MB，GB */
+ (NSString *)fileSizeStringFromBytes:(int64_t)byteSize;

/** 字符串md5加密 */
+ (NSString *)md5ForString:(NSString *)string;

/** 创建路径 */
+ (void)createPathIfNotExist:(NSString *)path;

+ (BOOL)removeFileIfExist:(NSString *)path;

+ (BOOL)fileExistsWithPath:(NSString *)path;

+ (int64_t)fileSizeWithPath:(NSString *)path;

+ (NSString *)urlStrWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask;

+ (NSUInteger)sec_timestamp;

+ (NSString *)getFileExtensionWithTask:(NSURLSessionDownloadTask *)task;

@end

NS_ASSUME_NONNULL_END
