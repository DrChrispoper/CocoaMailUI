//
//  SettingsViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 17/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "SettingsViewController.h"

#import "Accounts.h"


@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView* table;

@end


@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];

    UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"back_off" andHighlighted:@"back_on"];
    [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:@"Settings"];
    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       screenBounds.size.height-20)
                                                      style:UITableViewStyleGrouped];
    table.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
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


#pragma mark - Table Datasource


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section==0) ? 4 : 2;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row==0) ? 44.5f : 44.0f;
}


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



@end
