//
//  AppDelegate.m
//  HGDownloadManager
//
//  Created by hupfei on 2018/12/29.
//  Copyright © 2018 hupfei. All rights reserved.
//

#import "AppDelegate.h"
#import "HGDownloadManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    //注册通知
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    [[HGDownloadManager manager] configWithMaxTaskCount:1];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNotification object:nil];
    
    return YES;
}

//在应用处于后台，且后台任务下载完成时回调
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    [[HGDownloadManager manager] addCompletionHandler:completionHandler identifier:identifier];
}


- (void)downloadTaskFinishedNoti:(NSNotification *)noti{
    HGDownloadItem *item = noti.object;
    if (item) {
        NSString *detail = [NSString stringWithFormat:@"%@ 视频，已经下载完成！", item.fileName];
        [self localPushWithTitle:@"HGDownloadManager" detail:detail];
    }
}

- (void)localPushWithTitle:(NSString *)title detail:(NSString *)body  {
    
    if (title.length == 0) return;
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:3.0];
    localNote.alertBody = body;
    localNote.alertAction = @"滑动来解锁";
    localNote.hasAction = NO;
    localNote.soundName = @"default";
    localNote.userInfo = @{@"type" : @1};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
}


@end
