//
//  ViewController.m
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
#import "Application.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "UserManager.h"
#import <ATLConstants.h>
#import <libextobjc/EXTScope.h>
#import <JWTDecode/A0JWTDecoder.h>
//#import <MBProgressHUD/MBProgressHUD.h>
#import <SimpleKeychain/A0SimpleKeychain.h>

@interface ViewController ()

@property (nonatomic) BOOL isAuthenticating;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isAuthenticating = NO;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    A0SimpleKeychain *store = [Application sharedInstance].store;
    A0UserProfile *profile = [NSKeyedUnarchiver unarchiveObjectWithData:[store dataForKey:@"profile"]];
    NSString *idToken = [store stringForKey:@"id_token"];
    
    if (idToken) {
        if ([A0JWTDecoder isJWTExpired:idToken]) {
            NSLog(@"Auth0 token has expired, refreshing.");
            NSString *refreshToken = [store stringForKey:@"refresh_token"];
           
            @weakify(self);
            A0APIClient *client = [[[Application sharedInstance] lock] apiClient];
            [client fetchNewIdTokenWithRefreshToken:refreshToken parameters:nil success:^(A0Token *token) {
                @strongify(self);
                [store setString:token.idToken forKey:@"id_token"];
                [self loginLayer:profile.userId];
            } failure:^(NSError *error) {
                [store clearAll];
            }];
            
        } else {
            //User is connected in Auth0 but layerclient isn't connected
            self.tokenID = idToken;
            [self loginLayer:profile.userId];
        }
    } else {
        [self signInToAuth0];
    }
}

- (void)signInToAuth0
{
    A0Lock *lock = [[Application sharedInstance] lock];
    A0LockViewController *controller = [lock newLockViewController];
    controller.closable = true;
    @weakify(self);
    controller.onAuthenticationBlock = ^(A0UserProfile *profile, A0Token *token) {
        @strongify(self);
        self.tokenID = token.idToken;
        
        A0SimpleKeychain *keychain = [Application sharedInstance].store;
        [keychain setString:token.idToken forKey:@"id_token"];
        [keychain setString:token.refreshToken forKey:@"refresh_token"];
        [keychain setData:[NSKeyedArchiver archivedDataWithRootObject:profile] forKey:@"profile"];

        [self dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:controller animated:YES completion:nil];
}


- (void)loginLayer:(NSString *)userID
{
    [SVProgressHUD show];
    
    // Connect to Layer
    // See "Quick Start - Connect" for more details
    // https://developer.layer.com/docs/quick-start/ios#connect
    self.isAuthenticating = YES;
    [self.layerClient connectWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Failed to connect to Layer: %@", error);
        } else {
            [self authenticateLayerWithUserID:userID completion:^(BOOL success, NSError *error) {
                if (!error){
                    self.isAuthenticating = NO;
                    [self presentConversationListViewController];
                } else {
                    NSLog(@"Failed Authenticating Layer Client with error:%@", error);
                }
            }];
            
        }
    }];
}

- (void)authenticateLayerWithUserID:(NSString *)userID completion:(void (^)(BOOL success, NSError * error))completion
{
    // Check to see if the layerClient is already authenticated.
    if (self.layerClient.authenticatedUserID) {
        // If the layerClient is authenticated with the requested userID, complete the authentication process.
        if ([self.layerClient.authenticatedUserID isEqualToString:userID]){
            NSLog(@"Layer Authenticated as User %@", self.layerClient.authenticatedUserID);
            if (completion) {
                completion(YES, nil);
            }
            return;
        } else {
            //If the authenticated userID is different, then deauthenticate the current client and re-authenticate with the new userID.
            [self.layerClient deauthenticateWithCompletion:^(BOOL success, NSError *error) {
                if (!error){
                    [self authenticationTokenWithUserId:userID completion:^(NSString *identityToken, NSError *error) {
                        if (completion){
                            completion(success, error);
                        }
                    }];
                } else {
                    if (completion){
                        completion(NO, error);
                    }
                }
            }];
        }
    } else {
        // If the layerClient isn't already authenticated, then authenticate.
        [self authenticationTokenWithUserId:userID completion:^(NSString *identityToken, NSError *error) {
            if (completion){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        }];
    }
}

- (void)authenticationTokenWithUserId:(NSString *)userID completion:(void (^)(NSString *identityToken, NSError* error))completion
{
    /*
     * 1. Request an authentication Nonce from Layer
     */
    [self.layerClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
        if (!nonce) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        A0APIClient *client = [[[Application sharedInstance] lock] apiClient];
        A0AuthParameters *parameters = [A0AuthParameters newWithDictionary:@{
                                                                             @"id_token":    self.tokenID,
                                                                             @"target":      @"vU834mVE0b8kXY1Pl8xsX00jQcGTuFKO",
                                                                             @"api_type":    @"layer",
                                                                             @"scope":       @[@"openid"],
                                                                             @"nonce":       nonce,
                                                                             }];
        [client fetchDelegationTokenWithParameters:parameters success:^(NSDictionary *delegationToken) {
            NSString *identityToken = delegationToken[@"id_token"];
            [self.layerClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
                if (authenticatedUserID) {
                    if (completion) {
                        completion(identityToken, nil);
                    }
                    NSLog(@"Layer Authenticated as User: %@", authenticatedUserID);
                } else {
                    completion(nil, error);
                }
            }];
        } failure:^(NSError *error) {
            completion(nil, error);
        }];
    }];
}

- (void)presentConversationListViewController
{
    [SVProgressHUD dismiss];
     ConversationListViewController *controller = [ConversationListViewController  conversationListViewControllerWithLayerClient:self.layerClient];
     [self.navigationController pushViewController:controller animated:YES];
}

@end
