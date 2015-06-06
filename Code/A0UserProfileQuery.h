//
//  A0UserProfileQuery.h
//  Layer-Auth0-iOS-Example
//
//  Created by Abir Majumdar on 6/5/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "A0UserProfile+ATLParticipant.h"
#import "Application.h"

@interface A0UserProfileQuery : NSObject


typedef NS_ENUM(NSUInteger, A0UserProfileQueryType) {
    A0UserProfileQueryTypeNotEqualTo     = 1000,
    A0UserProfileQueryTypeContainIn      = 1001
};

- (instancetype)whereKey:(NSString *)key notEqualTo:(id)object;

- (instancetype)whereKey:(NSString *)key containedIn:(NSArray *)array;

- (void)findObjectsInBackgroundWithBlock:(void (^)(NSArray *object,
                                                   NSError *error))completion;

@end
