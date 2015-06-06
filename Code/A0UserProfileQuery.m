//
//  A0UserProfileQuery.m
//  Layer-Auth0-iOS-Example
//
//  Created by Abir Majumdar on 6/5/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import "A0UserProfileQuery.h"

@interface A0UserProfileQuery ()
@property (nonatomic, readonly) NSString *key;
@property (nonatomic) NSUInteger queryType;
@property (nonatomic) id searchTerm;
@end

@implementation A0UserProfileQuery

static NSString *const A0BearerToken = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJkbXZvTDhQMWw2QXU2aWpYbFE0WGVobTcza3hBQ1M3SSIsInNjb3BlcyI6eyJ1c2VycyI6eyJhY3Rpb25zIjpbInJlYWQiXX19LCJpYXQiOjE0MzMyOTI2MDEsImp0aSI6ImE4NjBjMDg2MWMwNmEwZmRmMjQ1NzE0YWRmNmVmYTA5In0.2aTso2Cl_Ygef5yiJVWkZbIivQelJ7NrzrFpqguTMGY";

- (instancetype)whereKey:(NSString *)key containedIn:(NSArray *)array
{
    _key = key;
    _queryType = A0UserProfileQueryTypeContainIn;
    _searchTerm = array;
    return [A0UserProfileQuery new];
}

- (instancetype)whereKey:(NSString *)key notEqualTo:(id)object
{
    _key = key;
    _queryType = A0UserProfileQueryTypeNotEqualTo;
    _searchTerm = object;
    return [A0UserProfileQuery new];
}

- (void)findObjectsInBackgroundWithBlock:(void (^)(NSArray *, NSError *))completion
{
    A0Lock *lock = [[Application sharedInstance] lock];
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v2/",lock.domainURL]];
    NSURL *relativeURL = [NSURL URLWithString:@"users?include_totals=true" relativeToURL:baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:relativeURL];
    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", A0BearerToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *parameters = @{ };
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    request.HTTPBody = requestBody;
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        // Deserialize the response
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if(![responseObject valueForKey:@"error"])
        {
            if(![responseObject valueForKey:@"error"])
            {
                NSDictionary *users = responseObject[@"users"];
                
                NSMutableArray *mutableArray =[[NSMutableArray alloc]init];
                for (id user in users)
                {
                    A0UserProfile *profile = [[A0UserProfile alloc] initWithDictionary:user];
                    [mutableArray addObject:profile];
                }
                NSArray *array = [self getFilteredResults:mutableArray];
                completion(array, nil);
            }
        }
        else
        {
            NSString *domain = [relativeURL host];
            NSInteger code = 1;
            NSDictionary *userInfo =
            @{
              NSLocalizedDescriptionKey: @"Auth0 Returned an Error.",
              NSLocalizedRecoverySuggestionErrorKey: @"There may be a problem with querying Auth0."
              };
            
            NSError *error = [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
            completion(nil, error);
        }
    }] resume];        
}

- (NSArray *)getFilteredResults:(NSMutableArray*)allUsers
{
    NSArray* result;
    if(self.queryType == A0UserProfileQueryTypeNotEqualTo)
    {
        NSArray* arrayOfProfiles = [allUsers copy];
        NSPredicate* containsAKeyword = [NSPredicate predicateWithBlock: ^BOOL(id evaluatedObject, NSDictionary *bindings) {
            A0UserProfile* profile = (A0UserProfile*)evaluatedObject;
            NSString *userID = [profile valueForKey:self.key];
            NSString *searchTerm = self.searchTerm;
            if([userID isEqualToString:searchTerm])
            {
                return NO;
            }
            return YES;
        }];
        
        result = [arrayOfProfiles filteredArrayUsingPredicate: containsAKeyword];
    }
    else if (self.queryType == A0UserProfileQueryTypeContainIn)
    {
        NSArray* arrayOfProfiles = [allUsers copy];
        NSPredicate* containsAKeyword = [NSPredicate predicateWithBlock: ^BOOL(id evaluatedObject, NSDictionary *bindings) {
            A0UserProfile* profile = (A0UserProfile*)evaluatedObject;
            NSString *userID = [profile valueForKey:self.key];
            NSArray *searchTerms = self.searchTerm;
            
            if([searchTerms containsObject: userID])
            {
                return YES;
            }
            return NO;
        }];
        
        result = [arrayOfProfiles filteredArrayUsingPredicate: containsAKeyword];
    }
    return result;
}

@end
