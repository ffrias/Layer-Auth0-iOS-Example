//
//  PFUser+Participant.h
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

#import "A0UserProfile+ATLParticipant.h"

@implementation A0UserProfile (ATLParticipant)

- (NSString *)firstName
{
    if ([self.name rangeOfString:@" "].location != NSNotFound) {
        NSArray *chunks = [self.name componentsSeparatedByString: @" "];
        return [chunks firstObject];
    } else {
        return self.nickname;
    }
}

- (NSString *)lastName
{
    if ([self.name rangeOfString:@" "].location != NSNotFound) {
        NSArray *chunks = [self.name componentsSeparatedByString: @" "];
        return [chunks lastObject];
    } else {
        return @"";
    }
}

- (NSString *)fullName
{
    NSArray *sourceArray = [self.userId componentsSeparatedByString: @"|"];
    return [NSString stringWithFormat:@"%@ (%@)", self.name, [sourceArray firstObject]];
}

- (NSString *)participantIdentifier
{
    return self.userId;
}

- (UIImage *)avatarImage
{
    /*
    if ([self.userId rangeOfString:@"github"].location != NSNotFound) {
        return [UIImage imageNamed:@"github.png"];
    } else {
        return [UIImage imageNamed:@"auth0.png"];
    }
     */
    return nil;
}

- (NSString *)avatarInitials
{
    return [[NSString stringWithFormat:@"%@%@", [self.firstName substringToIndex:1], [self.lastName substringToIndex:1]] uppercaseString];
}

- (NSURL *)avatarImageURL
{
    return self.picture;
}

@end
