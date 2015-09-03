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

@property (nonatomic, strong) NSArray* settings;

@property (nonatomic, weak) UISwitch* badgeSwitch;

@end


@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];

    item.leftBarButtonItem = [self backButtonInNavBar];
    
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:@"Settings"];
    
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

    [self _prepareTable];
    table.dataSource = self;
    table.delegate = self;    
    self.table = table;

}

-(void)_prepareTable
{
    
    NSArray* accounts = [Accounts sharedInstance].accounts;
    NSMutableArray* as = [NSMutableArray arrayWithCapacity:accounts.count];
    NSMutableArray* da = [NSMutableArray arrayWithCapacity:1];

    NSInteger idx = -1;
    
    for (Account* a in accounts) {
        idx++;
        if ([a isAllAccounts]) {
            continue;
        }
        
        [as addObject:@{@"bv": [a.person badgeView], @"t" : a.userMail, @"a" : @"EDIT_ACCOUNT", @"o":a}];
        
        if (idx == [Accounts sharedInstance].defaultAccountIdx) {
            [da addObject:@{@"bv": [a.person badgeView], @"t" : a.userMail, @"a" : @"DEFAULT_ACCOUNT"}];
        }
        
    }
         
    [as addObject:@{@"bv" : [[UIView alloc] init],@"t": @"Add account",@"a" : @"ADD_ACCOUNT"}];
    
    NSDictionary* Paccounts = @{@"title":@"ACCOUNTS", @"footer":@"", @"content":as};
    
    NSDictionary* PdftAccount = @{@"title":@"DEFAULT ACCOUNT", @"footer":@"Default account used to send emails when using unified Inbox", @"content":da};
    
    NSArray* clouds = @[
                        @{@"bi":@"icone_dropbox", @"t": @"Dropbox", @"a" : kSETTINGS_CLOUD_NOTIFICATION, @"o": @"Dropbox", @"k" : kSETTINGS_KEY},
                        @{@"bi":@"icone_icloud", @"t": @"iCloud", @"a" : kSETTINGS_CLOUD_NOTIFICATION, @"o": @"iCloud", @"k" : kSETTINGS_KEY},
                        @{@"bi":@"icone_google", @"t": @"Google Drive", @"a" : kSETTINGS_CLOUD_NOTIFICATION, @"o": @"Google Drive", @"k" : kSETTINGS_KEY},
                        @{@"bi":@"icone_box", @"t": @"Box", @"a" : kSETTINGS_CLOUD_NOTIFICATION, @"o": @"Box", @"k" : kSETTINGS_KEY}
                        ];
    
    NSDictionary* Pclouds = @{@"title":@"CLOUD SERVICES", @"footer":@"", @"content":clouds};
    
    
    NSArray* displays = @[
                          @{@"t": @"Quick Swipe", @"a" : @"CONFIG_SWIPE"},
                          @{@"t": @"Display badge count", @"da" : @"BADGE_COUNT"},
                          @{@"t": @"Notifications", @"a" : @"CONFIG_NOTIF"}
                        ];
    
    NSDictionary* Pdisplay = @{@"title":@"DISPLAY", @"footer":@"", @"content":displays};

    NSDictionary* Pcredit = @{@"title":@"", @"footer":@"",
                              @"content":@[@{@"t":@"Credits", @"a":@"CREDITS"}]
                              };
    

    NSDictionary* PDelete = @{@"title":@"", @"footer":@"",
                              @"content":@[@{@"t":@"Delete stored attachments", @"da" : @"CLEAR"}]
                              };
    
    NSDictionary* PNavbar = @{@"title":@"", @"footer":@"",
                              @"content":@[@{@"t":@"Blurred nav bar", @"da" : @"NAV_BAR_BLUR"},
                                           @{@"t":@"Opaque nav bar", @"da" : @"NAV_BAR_SOLID"}]
                              };
    
    self.settings = @[Paccounts, PdftAccount, Pclouds, Pdisplay, Pcredit, PDelete, PNavbar];
    
}


-(void) cleanBeforeGoingBack
{
    self.table.delegate = nil;
    self.table.dataSource = nil;
}

#pragma mark - Table Datasource


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.settings.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* sectionInfos = self.settings[section];
    NSArray* content = sectionInfos[@"content"];
    
    return content.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row==0) ? 52.5f : 52.0f;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary* sectionInfos = self.settings[indexPath.section];
    NSArray* content = sectionInfos[@"content"];
    NSDictionary* infoCell = content[indexPath.row];
    
    
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noID"];
    
    
    cell.textLabel.text = infoCell[@"t"];
    
    

    
    if ([infoCell objectForKey:@"bv"] != nil) {
        UIView* v = infoCell[@"bv"];
    
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(33.f, 33.f), NO, [UIScreen mainScreen].scale);
        UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    
        cell.imageView.image = img;
        [cell.imageView addSubview:v];
    }
    else {
        NSArray* alls = cell.imageView.subviews;
        for (UIView* v in alls) {
            [v removeFromSuperview];
        }
        
        NSString* imgName = infoCell[@"bi"];
        
        cell.imageView.image = (imgName.length>0) ? [UIImage imageNamed:imgName] : nil;
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentNatural;
    cell.textLabel.textColor = [UIColor blackColor];
    
    if (infoCell[@"da"]!=nil) {

        NSString* action = infoCell[@"da"];
        
        cell.accessoryView = nil;
        
        if ([action isEqualToString:@"BADGE_COUNT"]) {
            UISwitch* s = [[UISwitch alloc] init];
            s.onTintColor = [UIGlobal standardBlue];
            [s addTarget:self action:@selector(_switchBadge:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            self.badgeSwitch = s;
        }
        else if ([action isEqualToString:@"NAV_BAR_BLUR"]) {
            cell.accessoryType = ([Accounts sharedInstance].navBarBlurred) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else if ([action isEqualToString:@"NAV_BAR_SOLID"]) {
            cell.accessoryType = ([Accounts sharedInstance].navBarBlurred) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
        }
        else if ([action isEqualToString:@"CLEAR"]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIGlobal standardBlue];
            
        }
        
    }
    else if (infoCell[@"a"]!=nil) {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
//    cell.tintColor = cac.userColor;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* sectionInfos = self.settings[section];
    return sectionInfos[@"title"];
}

-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary* sectionInfos = self.settings[section];
    return sectionInfos[@"footer"];
}


#pragma mark Table Delegate

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSDictionary* sectionInfos = self.settings[section];
    NSString* info = sectionInfos[@"footer"];
    return (info.length>0) ? 46 :CGFLOAT_MIN;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 52;
}


-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* sectionInfos = self.settings[indexPath.section];
    NSArray* content = sectionInfos[@"content"];
    NSDictionary* infoCell = content[indexPath.row];
    
    NSString* directAction = infoCell[@"da"];
    

    if (directAction.length>0) {
        
        NSArray* reload = nil;
        
        if ([directAction isEqualToString:@"BADGE_COUNT"]) {
            [self.badgeSwitch setOn:!self.badgeSwitch.on animated:YES];
            [self _switchBadge:self.badgeSwitch];
        }
        else if ([directAction isEqualToString:@"NAV_BAR_BLUR"]) {
            [Accounts sharedInstance].navBarBlurred = YES;
            
            reload = @[indexPath, [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section]];
        }
        else if ([directAction isEqualToString:@"NAV_BAR_SOLID"]) {
            [Accounts sharedInstance].navBarBlurred = NO;
            reload = @[indexPath, [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section]];
        }
        else if ([directAction isEqualToString:@"CLEAR"]) {
            [ViewController presentAlertWIP:@"clear attachments…"];
        }
        
        if (reload.count > 0) {
            [tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationNone];
        }
    
        return nil;
    }
    
    NSString* action = infoCell[@"a"];
    
    if (action.length>0) {
        
        NSString* key = infoCell[@"k"];
        id object = infoCell[@"o"];
        
        if (key.length > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:action object:nil userInfo:@{key:object}];
        }
        
        return nil;
    }
    
    
    return nil;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    
    
    /*
    if (indexPath.section==0) {
        [Accounts sharedInstance].quickSwipeType = indexPath.row;
    }
    else {
        [Accounts sharedInstance].navBarBlurred = indexPath.row==0;
    }
    
    [tableView reloadData];
    */
}

-(void) _switchBadge:(UISwitch*)sender
{
    [Accounts sharedInstance].showBadgeCount = ![Accounts sharedInstance].showBadgeCount;
    
    // TODO make something with that
}


/*
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
*/


@end
