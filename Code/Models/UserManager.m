//
//  UserManager.m
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

#import "UserManager.h"
//#import <Parse/Parse.h>
#import <Lock/Lock.h>
//#import "PFUser+ATLParticipant.h"
#import "A0UserProfile+ATLParticipant.h"
//#import <Bolts/Bolts.h>
#import "Application.h"
#import <SimpleKeychain/A0SimpleKeychain.h>

@interface UserManager ()

@property (nonatomic) NSCache *userCache;

@end

@implementation UserManager

#pragma mark - Public Methods

+ (instancetype)sharedManager
{
    static UserManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[UserManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userCache = [NSCache new];
    }
    return self;
}

#pragma mark Query Methods

- (void)queryForUserWithName:(NSString *)searchText completion:(void (^)(NSArray *, NSError *))completion
{
/*    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *contacts = [NSMutableArray new];
            for (PFUser *user in objects){
                if ([user.fullName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [contacts addObject:user];
                }
            }
            if (completion) completion([NSArray arrayWithArray:contacts], nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
*/
    A0UserProfileQuery *query = [[A0UserProfileQuery alloc] init];
    A0SimpleKeychain *store = [Application sharedInstance].store;
    A0UserProfile *profile = [NSKeyedUnarchiver unarchiveObjectWithData:[store dataForKey:@"profile"]];
    NSString *currentUserID = profile.userId;
    [query whereKey:@"userId" notEqualTo:currentUserID];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *contacts = [NSMutableArray new];
            for (A0UserProfile *user in objects){
                if ([user.fullName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [contacts addObject:user];
                }
            }
            if (completion) completion([NSArray arrayWithArray:contacts], nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
    
}

- (void)queryForAllUsersWithCompletion:(void (^)(NSArray *, NSError *))completion
{
/*
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (completion) completion(objects, nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
*/
    A0UserProfileQuery *query = [[A0UserProfileQuery alloc] init];
    A0SimpleKeychain *store = [Application sharedInstance].store;
    A0UserProfile *profile = [NSKeyedUnarchiver unarchiveObjectWithData:[store dataForKey:@"profile"]];
    NSString *currentUserID = profile.userId;
    [query whereKey:@"userId" notEqualTo:currentUserID];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (completion) completion(objects, nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
}

- (void)queryAndCacheUsersWithIDs:(NSArray *)userIDs completion:(void (^)(NSArray *, NSError *))completion
{/*
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" containedIn:userIDs];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFUser *user in objects) {
                [self cacheUserIfNeeded:user];
            }
            if (completion) objects.count > 0 ? completion(objects, nil) : completion(nil, nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
*/
    A0UserProfileQuery *query = [[A0UserProfileQuery alloc] init];
    [query whereKey:@"userId" containedIn:userIDs];
//    A0SimpleKeychain *store = [Application sharedInstance].store;
//    A0UserProfile *profile = [NSKeyedUnarchiver unarchiveObjectWithData:[store dataForKey:@"profile"]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (A0UserProfile *user in objects) {
                [self cacheUserIfNeeded:user];
            }
            if (completion) objects.count > 0 ? completion(objects, nil) : completion(nil, nil);
        } else {
            if (completion) completion(nil, error);
        }
    }];
}

- (A0UserProfile *)cachedUserForUserID:(NSString *)userID
{
    if ([self.userCache objectForKey:userID]) {
        return [self.userCache objectForKey:userID];
    }
    return nil;
}

- (void)cacheUserIfNeeded:(A0UserProfile *)user
{
    if (![self.userCache objectForKey:user.userId]) {
        [self.userCache setObject:user forKey:user.userId];
    }
}

- (NSArray *)unCachedUserIDsFromParticipants:(NSArray *)participants
{
    NSMutableArray *array = [NSMutableArray new];
    
    for (NSString *userID in participants) {
        A0SimpleKeychain *store = [Application sharedInstance].store;
        A0UserProfile *profile = [NSKeyedUnarchiver unarchiveObjectWithData:[store dataForKey:@"profile"]];
        NSString *currentUserID = profile.userId;
        if ([userID isEqualToString:currentUserID]) continue;
        if (![self.userCache objectForKey:userID]) {
            [array addObject:userID];
        }
    }
    
    return [NSArray arrayWithArray:array];
}

- (NSArray *)resolvedNamesFromParticipants:(NSArray *)participants
{
    NSMutableArray *array = [NSMutableArray new];
    for (NSString *userID in participants) {
        A0SimpleKeychain *store = [Application sharedInstance].store;
        A0UserProfile *profile = [NSKeyedUnarchiver unarchiveObjectWithData:[store dataForKey:@"profile"]];
        NSString *currentUserID = profile.userId;
        if ([userID isEqualToString:currentUserID]) continue;
        if ([self.userCache objectForKey:userID]) {
            A0UserProfile *user = [self.userCache objectForKey:userID];
            [array addObject:user.firstName];
        }
    }
    return [NSArray arrayWithArray:array];
}


@end

