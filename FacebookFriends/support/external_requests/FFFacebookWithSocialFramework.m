//
//  FFFacebookWithSocialFramework.m
//  FacebookFriends
//
//  Created by Bradley Griffith on 5/24/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "FFFacebookWithSocialFramework.h"
#import <Social/Social.h>

#define FACEBOOK_APP_ID @"463736673694867"

@interface FFFacebookWithSocialFramework ()
@property (nonatomic, strong)ACAccountStore *accountStore;
@end


@implementation FFFacebookWithSocialFramework

- (id)init
{
    self = [super init];
    if (self) {
        [self setupAccountStore];
    }
    return self;
}

- (void)setupAccountStore {
    _accountStore = [[ACAccountStore alloc] init];
}

- (void)connectToFacebook:(connectedBlock)success
                  failure:(failedWithError)failure {

    ACAccountType *facebookAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    id options = @{
                   ACFacebookAppIdKey: FACEBOOK_APP_ID,
                   ACFacebookPermissionsKey: @[ @"email", @"read_friendlists"],
                   ACFacebookAudienceKey: ACFacebookAudienceFriends
                   };
    
    [_accountStore requestAccessToAccountsWithType:facebookAccountType
                                           options:options
                                        completion:^(BOOL granted, NSError *error) {
                                            if (granted) {
                                                success();
                                            } else {
                                                NSLog(@"Failed to connect to Facebook! %@", error.localizedDescription);
                                                failure(@"Failed to Connect to Facebook.");
                                            }
                                        }];
    
}

- (void)renewCredentials {
    ACAccountType *facebookAccountType  = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    ACAccount *fbAccount = [[self.accountStore accountsWithAccountType:facebookAccountType] lastObject];
    if (fbAccount) {
        [_accountStore renewCredentialsForAccount:fbAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
            // Do nothing.
        }];
    }
}

- (void)findFriendsForAccount:(ACAccount *)facebookAccount
                      success:(foundFriendsBlock)success
                      failure:(failedWithError)failure {
    
    SLRequest *friendsListRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:[NSURL URLWithString:@"https://graph.facebook.com/me/friends"]
                                                          parameters:nil];
    friendsListRequest.account = facebookAccount;
    [friendsListRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (responseData) {
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                NSError *jsonError = nil;
                NSDictionary *friendsListData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                                options:NSJSONReadingAllowFragments
                                                                                  error:&jsonError];
                if (jsonError) {
                    NSLog(@"Error parsing friends list: %@", jsonError);
                    failure(@"Error retrieving Facebook friends. Facebook might be having problems right now.");
                }
                else {
                    success([friendsListData objectForKey:@"data"]);
                }
            }
            else {
                [self renewCredentials];
                NSLog(@"HTTP %d returned. Error code: %@", urlResponse.statusCode, error.localizedDescription);
                failure(@"Error retrieving Facebook friends. Facebook might be having problems right now.");
            }
        } else {
            NSLog(@"Cannot establish connection. Error code: %@", error.localizedDescription);
            failure(@"Error retrieving Facebook friends. Facebook might be having problems right now.");
        }
    }];
}

@end