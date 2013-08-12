//
//  FFFacebookFriendTableViewFriendCell.h
//  FacebookFriends
//
//  Created by Bradley Griffith on 5/26/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FFFacebookFriendTableViewFriendCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *friendName;
@property (weak, nonatomic) IBOutlet UIImageView *friendImageView;
@property (weak, nonatomic) IBOutlet UILabel *selectionCheckMark;

@end
