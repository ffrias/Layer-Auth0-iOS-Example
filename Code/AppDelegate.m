//
//  AppDelegate.m
//  Layer-Auth0-iOS-Example
//
//  Created by Abir Majumdar on 6/5/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ViewController.h"
#import <LayerKit/LayerKit.h>
#import <Lock/Lock.h>
#import "AppDelegate.h"
#import "Application.h"

@implementation AppDelegate

#pragma mark TODO: Before first launch, update LayerAppIDString, Auth0ClientID, Auth0ClientDomain values
#warning "TODO:If LayerAppIDString, Auth0ClientID, Auth0ClientDomain are nil, this app will crash"
static NSString *const LayerAppIDString = @"44a270b6-7c58-11e4-bbba-fcf307000352";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *auth0ClientID = info[@"Auth0ClientId"];
    NSString *auth0Domain = info[@"Auth0Domain"];
    
     if (LayerAppIDString.length == 0 || auth0ClientID.length == 0 || auth0Domain.length == 0) {
         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid Configuration" message:@"You have not configured your Layer and/or Auth0 keys. Please check your configuration and try again." delegate:nil cancelButtonTitle:@"Rats!" otherButtonTitles:nil];
         [alertView show];
         return YES;
     }
    
    A0Lock *lock = [[Application sharedInstance] lock];
    [lock applicationLaunchedWithOptions:launchOptions];
    
    // Initializes a LYRClient object
    NSUUID *appID = [[NSUUID alloc] initWithUUIDString:LayerAppIDString];
    LYRClient *layerClient = [LYRClient clientWithAppID:appID];
    
    // Show View Controller
    ViewController *controller = [ViewController new];
    controller.layerClient = layerClient;
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:controller];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    A0Lock *lock = [[Application sharedInstance] lock];
    return [lock handleURL:url sourceApplication:sourceApplication];
}

@end
