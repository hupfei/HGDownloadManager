//
//  HGDownloadUtils.m
//  Test
//
//  Created by hupfei on 2018/12/25.
//  Copyright © 2018 yyets. All rights reserved.
//

#import "HGDownloadUtils.h"
#import <CommonCrypto/CommonDigest.h>

#define kCommonUtilsGigabyte (1024 * 1024 * 1024)
#define kCommonUtilsMegabyte (1024 * 1024)
#define kCommonUtilsKilobyte 1024

@implementation HGDownloadUtils

+ (int64_t)fileSystemFreeSize {
    int64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes longLongValue];
    }
    return totalFreeSpace;
}

+ (NSString *)fileSizeStringFromBytes:(int64_t)byteSize {
    if (kCommonUtilsGigabyte <= byteSize) {
        return [NSString stringWithFormat:@"%@GB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsGigabyte]];
    }
    if (kCommonUtilsMegabyte <= byteSize) {
        return [NSString stringWithFormat:@"%@MB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsMegabyte]];
    }
    if (kCommonUtilsKilobyte <= byteSize) {
        return [NSString stringWithFormat:@"%@KB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsKilobyte]];
    }
    return [NSString stringWithFormat:@"%luB", (unsigned long)byteSize];
}

+ (NSString *)numberStringFromDouble:(const double)num {
    NSInteger section = round((num - (NSInteger)num) * 100);
    if (section % 10) {
        return [NSString stringWithFormat:@"%.2f", num];
    }
    if (section > 0) {
        return [NSString stringWithFormat:@"%.1f", num];
    }
    return [NSString stringWithFormat:@"%.0f", num];
}

+ (NSString *)md5ForString:(NSString *)string {
    const char *str = [string UTF8String];
    if (str == NULL) str = "";
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *md5Result = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    return md5Result;
}

+ (void)createPathIfNotExist:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
    }
}

+ (BOOL)removeFileIfExist:(NSString *)path {
    if ([HGDownloadUtils fileExistsWithPath:path]) {
        NSError *error;
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"删除文件失败%@", error);
            return NO ;
        }
        return result;
    }
    return NO;
}

+ (BOOL)fileExistsWithPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (int64_t)fileSizeWithPath:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return dic ? (int64_t)[dic fileSize] : 0;
}

+ (NSString *)urlStrWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    return downloadTask.originalRequest.URL.absoluteString ? : downloadTask.currentRequest.URL.absoluteString;
}

+ (NSUInteger)sec_timestamp {
    return (NSUInteger)[[NSDate date] timeIntervalSince1970];
}

+ (NSString *)getFileExtensionWithTask:(NSURLSessionDownloadTask *)task {
    NSURLResponse *oriResponse = task.response;
    if ([oriResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)oriResponse;
        NSString *extension = [[response.allHeaderFields valueForKey:@"Content-Type"] componentsSeparatedByString:@"/"].lastObject;
        if ([extension containsString:@";"]) {
            extension = [extension componentsSeparatedByString:@";"].firstObject;
        }
        if(extension.length==0) extension = response.suggestedFilename.pathExtension;
        return extension;
    }
    return @"data";
}


@end
