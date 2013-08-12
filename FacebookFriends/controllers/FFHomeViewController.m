//
//  FFHomeViewController.m
//  FacebookFriends
//
//  Created by Bradley Griffith on 5/24/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "FFHomeViewController.h"
#import "FFFacebookWithSDK.h"
#import "FFFacebookWithSocialFramework.h"
#import "FFFriendListViewController.h"

#import "SVProgressHUD.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <FacebookSDK/FacebookSDK.h>

@interface FFHomeViewController ()
@property (nonatomic, strong)ACAccountStore *accountStore;
@property (nonatomic, strong)NSArray *facebookFriends;
@end

@implementation FFHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupAccountStore];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAccountStoreChanged:)
                                                 name:ACAccountStoreDidChangeNotification
                                               object:nil];
}

- (void)setupAccountStore {
    _accountStore = [[ACAccountStore alloc] init];
}

- (void)onAccountStoreChanged:(NSNotification *)notification {
    // When account store changes, the user could have added or removed an account.
    [self setupAccountStore];
    
    // There is a chance that we have a presented view controller when this
    // change takes place. In this situation we need to dismiss the presented view controller.
    if (self.navigationController.visibleViewController != [self.navigationController.viewControllers objectAtIndex:0]){
        // Leave friend list unless we are using the SDK and not the Social Framework.
        if (![[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"FBAccessTokenInformationKey"]){
            [self.navigationController popToRootViewControllerAnimated:YES];
            [SVProgressHUD showErrorWithStatus:@"Changes were made to the Facebook account linked with your device."];
        }
    }
}

- (IBAction)showFacebookFriends:(id)sender {

    ACAccountType *facebookAccountType  = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSArray *accounts = [_accountStore accountsWithAccountType:facebookAccountType];

    if ([[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"FBAccessTokenInformationKey"]){
        // Only give SDK connection priority over Social Framework connection if
        // the user has previously signed in using this method.
        [self establishConnectionUsingSDK];
    }
    else if ([accounts count] > 0) {
        [self establishConnectionUsingSocialFramework];
    }
    else {
        [self establishConnectionUsingSDK];
    }
}


- (void)establishConnectionUsingSDK {
    [SVProgressHUD show];
    
    NSLog(@"Attempting to connect to Facebook using SDK.");
    FFFacebookWithSDK *sdkConnection = [[FFFacebookWithSDK alloc] init];
    
    [sdkConnection connectToFacebook:^{
        if (FBSession.activeSession.state == FBSessionStateOpen) {
            // Sometimes we have a cached authorization token that can't be used immediately.
            // Hence, we ensure that our state is open before requesting friends.
            // Facebook SDK will call this twice (failing once) if it needs to refresh the token.
            
            [self useSDKToFindFriends];
        }
        else {
            [SVProgressHUD dismiss];
        }
    } failure:^(NSString *errorMessage) {
        [SVProgressHUD showErrorWithStatus:@"Failed to connect to Facebook using SDK."];
    }];
}

- (void)establishConnectionUsingSocialFramework {
    [SVProgressHUD show];
    NSLog(@"Attempt to connect to Facebook using Facebook account in Social Framework.");
    FFFacebookWithSocialFramework *frameworkConnection = [[FFFacebookWithSocialFramework alloc] init];
    
    [frameworkConnection connectToFacebook:^{

        ACAccountType *facebookAccountType  = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        ACAccount *fbAccount = [[self.accountStore accountsWithAccountType:facebookAccountType] lastObject];
        
        [self useSocialFrameworkToFindFriendsFor:fbAccount];
        
    } failure:^(NSString *errorMessage) {
        [SVProgressHUD showErrorWithStatus:@"Failed to connect to Facebook using account stored on this device."];
    }];
}


- (void)useSocialFrameworkToFindFriendsFor:(ACAccount *)account {
    
    FFFacebookWithSocialFramework *frameworkConnection = [[FFFacebookWithSocialFramework alloc] init];
    
    [frameworkConnection findFriendsForAccount:account success:^(NSArray *friends) {
        NSLog(@"Found: %i friends", friends.count);
        _facebookFriends = [self sortFriends:friends];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self performSegueWithIdentifier:@"segueToFacebookFriendList" sender:self];
        });
    } failure:^(NSString *errorMessage) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", errorMessage]];
    }];
}

- (void)useSDKToFindFriends {
    
    FFFacebookWithSDK *sdkConnection = [[FFFacebookWithSDK alloc] init];
    
    [sdkConnection findFriends:^(NSArray *friends) {
        NSLog(@"Found: %i friends", friends.count);
        _facebookFriends = [self sortFriends:friends];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        [self performSegueWithIdentifier:@"segueToFacebookFriendList" sender:self];
    } failure:^(NSString *errorMessage) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", errorMessage]];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToFacebookFriendList"]) {
        FFFriendListViewController *destViewController = segue.destinationViewController;
        
        destViewController.friendList = [NSMutableArray arrayWithArray:_facebookFriends];
    }
}

- (NSArray *)sortFriends:(NSArray *)friends{
    NSMutableArray *mutableFriends = [NSMutableArray arrayWithArray:friends];
    NSSortDescriptor *alphaDesc = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                              ascending:YES
                                                               selector:@selector(localizedCaseInsensitiveCompare:)];
    [mutableFriends sortUsingDescriptors:[NSMutableArray arrayWithObjects:alphaDesc, nil]];
    return [NSArray arrayWithArray:mutableFriends];
}

@end
