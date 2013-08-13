//
//  FFFriendListViewController.m
//  FacebookFriends
//
//  Created by Bradley Griffith on 5/25/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "FFFriendListViewController.h"
#import "FFFacebookFriendTableViewFriendCell.h"
#import "UIImageView+AFNetworking.h"

#import <QuartzCore/QuartzCore.h>

@interface FFFriendListViewController (){
    BOOL retina;
    BOOL isFiltered;
    NSString *searchString;
    NSDictionary *sortedFriends;
    NSArray *nameIndex;
    NSMutableArray *selectedFriends;
}
@property (nonatomic, strong)NSMutableDictionary *imageCache;
@end

@implementation FFFriendListViewController
@synthesize tableView = _tableview;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    retina = NO;
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        retina = [[UIScreen mainScreen] scale] == 2.0 ? YES : NO;
    
    selectedFriends = [[NSMutableArray alloc] init];
    
    [self sortFriends:_friendList];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self dismissKeyboard];
}

- (NSMutableDictionary *)imageCache {
    if (!_imageCache) {
        _imageCache = [NSMutableDictionary dictionary];
    }
    return _imageCache;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)scrollToTop {
    //[self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [nameIndex count];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [nameIndex objectAtIndex:section];
    NSArray *friendsForKey = [sortedFriends objectForKey:key];
    return [friendsForKey count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return [[nameIndex objectAtIndex:section] uppercaseString];
    
}

/*
 // Uncomment this to make the table view display the index on the right side of the screen.
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 return nameIndex;
 }
*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendCell";
    FFFacebookFriendTableViewFriendCell *cell = (FFFacebookFriendTableViewFriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *key = [nameIndex objectAtIndex:indexPath.section];
    NSArray *friendsForKey = [sortedFriends objectForKey:key];
    NSDictionary *friend = [friendsForKey objectAtIndex:indexPath.row];

    UIImage *defaultPhoto = [UIImage imageNamed:@"facebook_avatar.png"];
    UIImage *friendImage = [_imageCache valueForKey:friend[@"id"]];
    cell.friendImageView.contentMode = UIViewContentModeCenter;
    cell.friendImageView.layer.masksToBounds = YES;
    cell.friendImageView.layer.cornerRadius = 3.0;
    if (friendImage) {
        cell.friendImageView.image = friendImage;  // this is the best scenario: cached image
    } else {
        // Use default image and asynchronously load and cache the actual image.
        [self asynchSetImageForUser:friend atIndex:indexPath];
        cell.friendImageView.image = defaultPhoto;
    }
    
    NSMutableAttributedString *styledName = [self highlightSubstring:searchString inString:friend[@"name"]];
    cell.friendName.attributedText = styledName;
    
    
    cell.selectionCheckMark.hidden = [selectedFriends containsObject:friend[@"id"]] ? NO : YES;
    
    return cell;
}
 
- (void)asynchSetImageForUser:(NSDictionary *)friend atIndex:(NSIndexPath *)indexPath {
    
    NSString *urlString;
    if (retina) {
        urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=80&height=80", friend[@"id"]];
    }
    else {
        urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=40&height=40", friend[@"id"]];
    }
    
    NSURL *avatarUrl = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:avatarUrl];
 
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error) {
            
            UIImage *image = [UIImage imageWithData:data];
            if (retina) {
                // Scale for retina.
                image = [UIImage imageWithCGImage:[image CGImage] scale:2.0 orientation:UIImageOrientationUp];
            }
            
            if (image) {
                [self.imageCache setValue:image forKey:friend[@"id"]];
            }
            
            // If row is still visible, reload it. It should now use the cached image if it is available.
            NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
            if ([visiblePaths containsObject:indexPath]) {
                NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
                [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation: UITableViewRowAnimationFade];
                // because we cached the image, cellForRow... will see it and run fast
            }
        }
    }];
}

- (void)sortFriends:(NSArray *)friends {
    // Sorts users into a dictionary of alphabetical sections.
    NSArray *extractedNames = [friends valueForKey:@"name"];
    friends = extractedNames.copy;
    
    if (!isFiltered)
        friends = [extractedNames sortedDiacriticalAlphabetical];
    
    NSMutableDictionary *sectioned = [NSMutableDictionary dictionary];
    NSString *firstChar = nil;
    NSMutableArray *keys = [NSMutableArray array];
    
    for(NSString *friendName in friends) {
        if(![friendName length])continue;
        
        NSMutableArray *names = nil;
        firstChar = [[[friendName decomposedStringWithCanonicalMapping] substringToIndex:1] uppercaseString];
        
        if (!(names = [sectioned objectForKey:firstChar])) {
            names = [NSMutableArray array];
            [sectioned setObject:names forKey:firstChar];
            [keys addObject:firstChar];
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", friendName];
        NSArray *matchedDicts = [_friendList filteredArrayUsingPredicate:predicate];
        
        // TODO: This might be bad... make sure this isnt dropping people that share names or anything.
        [names addObject:matchedDicts[0]];
    }
    
    sortedFriends = sectioned.copy;
    if (isFiltered) {
        // Keep keys in order of names returned by search function.
        nameIndex = keys;
    }
    else {
        // Arrange keys alphabetically.
        nameIndex = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
}

- (NSMutableAttributedString *)highlightSubstring:(NSString *)subString inString:(NSString *)containerString {
    NSMutableAttributedString *styledString = [[NSMutableAttributedString alloc] initWithString:containerString];
    
    if (subString && containerString) {
        
        CGFloat fontSize = 17;
        UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               boldFont, NSFontAttributeName, nil];
        NSRange range = [containerString rangeOfString:subString
                                               options:(NSCaseInsensitiveSearch+NSDiacriticInsensitiveSearch)];
        
        
        [styledString addAttributes:attrs range:range];
    }
    
    return styledString;
}

#pragma mark - SearchBar Delegate

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    searchString = searchText.copy;
    
    NSArray *searchedUsers;
    if (searchString.length > 0) {
        NSArray *extractedNames = [_friendList valueForKey:@"name"];
        
        isFiltered = YES;
        NSArray *sorted = [extractedNames sortedDiacriticalAlphabetical];
        
        // Find and build array of all users whos names contain the search string, giving priority to names
        // that begin with the search text.
        NSMutableArray *foundInFirstname = [[NSMutableArray alloc] init];
        NSMutableArray *foundInName = [[NSMutableArray alloc] init];
        for (NSString *name in sorted) {
            NSRange range = [name rangeOfString:searchText
                                        options:(NSCaseInsensitiveSearch+NSDiacriticInsensitiveSearch+NSAnchoredSearch)];
            if (range.length > 0) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
                NSArray *matchedDicts = [_friendList filteredArrayUsingPredicate:predicate];
                
                // TODO: This might be bad... make sure this isnt dropping people that share names or anything.
                [foundInFirstname addObject:matchedDicts[0]];
            }
            else {
                range = [name rangeOfString:searchText
                                    options:NSCaseInsensitiveSearch+NSDiacriticInsensitiveSearch];
                if (range.length > 0) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
                    NSArray *matchedDicts = [_friendList filteredArrayUsingPredicate:predicate];
                    
                    // TODO: This might be bad... make sure this isnt dropping people that share names or anything.
                    [foundInName addObject:matchedDicts[0]];
                }
            }
        }
        searchedUsers = [foundInFirstname arrayByAddingObjectsFromArray:foundInName];
    }
    else {
        isFiltered = NO;
        searchedUsers = _friendList;
    }
    [self sortFriends:searchedUsers];
    
    [self.tableView reloadData];
    //[self scrollToTop];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissKeyboard];
    
    NSString *key = [nameIndex objectAtIndex:indexPath.section];
    NSArray *friendsForKey = [sortedFriends objectForKey:key];
    NSDictionary *friend = [friendsForKey objectAtIndex:indexPath.row];
    NSLog(@"%@",friend[@"name"]);
    FFFacebookFriendTableViewFriendCell *cell = (FFFacebookFriendTableViewFriendCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if ([selectedFriends containsObject:friend[@"id"]]) {
        [selectedFriends removeObject:friend[@"id"]];
        cell.selectionCheckMark.hidden = YES;
    }
    else {
        [selectedFriends addObject:friend[@"id"]];
        cell.selectionCheckMark.hidden = NO;
    }
}

@end

@implementation NSArray (Reverse)

- (NSArray *)sortedDiacriticalAlphabetical {
    NSArray *sorted = [self sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString*)obj1 compare:obj2 options:NSDiacriticInsensitiveSearch+NSCaseInsensitiveSearch];
    }];
    return sorted;
}

@end