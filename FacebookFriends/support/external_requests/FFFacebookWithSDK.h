//
//  FFFacebookWithSDK.h
//  FacebookFriends
//
//  Created by Bradley Griffith on 5/24/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^connectedBlock)();
typedef void (^foundFriendsBlock)(NSArray *friends);
typedef void (^failedWithError)(NSString *errorMessage);

@interface FFFacebookWithSDK : NSObject

- (void)connectToFacebook:(connectedBlock)success
                  failure:(failedWithError)failure;

- (void)findFriends:(foundFriendsBlock)success
            failure:(failedWithError)failure;

@end