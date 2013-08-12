//
//  FFFriendListViewController.h
//  FacebookFriends
//
//  Created by Bradley Griffith on 5/25/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FFFriendListViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong)NSMutableArray *friendList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@interface NSArray (Reverse)
- (NSArray *)sortedDiacriticalAlphabetical;
@end
