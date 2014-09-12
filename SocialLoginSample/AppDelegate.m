//
//  AppDelegate.m
//  SocialLoginSample
//
//  Created by tomonobu on 2014/09/09.
//  Copyright (c) 2014年 Tomonobu Sato. All rights reserved.
//

#import "AppDelegate.h"
#import "FBAppCall.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [FBAppCall handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme isEqualToString:@"fb691135414309579"]) {
        return [FBSession.activeSession handleOpenURL:url];
    }

    if (![url.scheme isEqualToString:@"socialloginsample"]) {
        return NO;
    }

    NSDictionary *dict = [self parametersDictionaryFromQueryString:url.query];

    NSString *token = dict[@"oauth_token"];
    NSString *verifier = dict[@"oauth_verifier"];

    ViewController *vc = (ViewController *)[[self window] rootViewController];
    [vc setOAuthToken:token oauthVerifier:verifier];

    return YES;
}

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString
{
    NSDictionary *dict = @{};

    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];

    for(NSString *string in queryComponents) {
        NSArray *pair = [string componentsSeparatedByString:@"="];
        if (pair.count != 2) {
            continue;
        }

        dict = @{pair[0]:pair[1]};
    }

    return dict;
}

@end
