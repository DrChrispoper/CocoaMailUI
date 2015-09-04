//
//  QuickSwipeViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 04/09/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "QuickSwipeViewController.h"

#import "Accounts.h"

@interface QuickSwipeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView* table;

@end


@implementation QuickSwipeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    item.leftBarButtonItem = [self backButtonInNavBar];
    
    NSString* title = NSLocalizedString(@"Quick swipe", @"Quick swipe");
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:title];
    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       screenBounds.size.height-20)
                                                      style:UITableViewStyleGrouped];
    table.contentInset = UIEdgeInsetsMake(44, 0, 60, 0);
    table.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    table.backgroundColor = [UIGlobal standardLightGrey];
    
    [self.view addSubview:table];
    
    [self setupNavBarWith:item overMainScrollView:table];
    
    table.dataSource = self;
    table.delegate = self;
    self.table = table;
    
}



-(void) cleanBeforeGoingBack
{
    self.table.delegate = nil;
    self.table.dataSource = nil;
}

-(BOOL) haveCocoaButton
{
    return NO;
}


#pragma mark - Table Datasource


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row==0) ? 52.5f : 52.0f;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noID"];
    
    
    NSArray* names = @[NSLocalizedString(@"Archive", @"Archive"),
                       NSLocalizedString(@"Delete",@"Delete"),
                       NSLocalizedString(@"Reply",@"Reply"),
                       NSLocalizedString(@"Mark as read/unread",@"Mark as read/unread")];
    
    NSArray* imgNames = @[@"swipe_archive", @"swipe_delete", @"swipe_reply_single",@"swipe_unread"];
    
    cell.textLabel.text = names[indexPath.row];
    UIImage* img = [[UIImage imageNamed:imgNames[indexPath.row]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.image = img;
    cell.imageView.tintColor = [UIGlobal standardBlue];
    
    if ([Accounts sharedInstance].quickSwipeType == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    cell.tintColor = [UIGlobal standardBlue];
    
    return cell;
}


#pragma mark Table Delegate

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 20;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 52;
}

-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [Accounts sharedInstance].quickSwipeType = indexPath.row;
    [tableView reloadData];
    
    return nil;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end



/*
 #pragma mark - Table Datasource
 
 -(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 
 Account* cac = [[Accounts sharedInstance] currentAccount];
 
 UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noID"];
 
 
 if (indexPath.section == 0) {
 
 NSArray* names = @[NSLocalizedString(@"Archive", @"Archive"),
 NSLocalizedString(@"Delete",@"Delete"),
 NSLocalizedString(@"Reply",@"Reply"),
 NSLocalizedString(@"Mark as read/unread",@"Mark as read/unread")];
 
 NSArray* imgNames = @[@"swipe_archive", @"swipe_delete", @"swipe_reply_single",@"swipe_unread"];
 
 cell.textLabel.text = names[indexPath.row];
 UIImage* img = [[UIImage imageNamed:imgNames[indexPath.row]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
 cell.imageView.image = img;
 cell.imageView.tintColor = cac.userColor;
 
 if ([Accounts sharedInstance].quickSwipeType == indexPath.row) {
 cell.accessoryType = UITableViewCellAccessoryCheckmark;
 }
 }
 else {
 NSArray* names = @[@"Blurred nav bar", @"Opaque nav bar"];
 cell.textLabel.text = names[indexPath.row];
 
 NSInteger idx = [Accounts sharedInstance].navBarBlurred ? 0 : 1;
 
 if (idx == indexPath.row) {
 cell.accessoryType = UITableViewCellAccessoryCheckmark;
 }
 }
 
 cell.tintColor = cac.userColor;
 cell.selectionStyle = UITableViewCellSelectionStyleGray;
 
 
 return cell;
 }
 
 -(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
 {
 return nil;
 }
 
 
 #pragma mark Table Delegate
 
 -(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
 {
 return CGFLOAT_MIN;
 }
 
 -(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
 {
 return 30;
 }
 
 -(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
 {
 [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
 if (indexPath.section==0) {
 [Accounts sharedInstance].quickSwipeType = indexPath.row;
 }
 else {
 [Accounts sharedInstance].navBarBlurred = indexPath.row==0;
 }
 
 [tableView reloadData];
 
 }
 */

