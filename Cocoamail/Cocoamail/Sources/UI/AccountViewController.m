//
//  AccountViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 04/09/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "AccountViewController.h"

#import "EditCocoaButtonView.h"
#import "Accounts.h"
#import "CocoaButton.h"

@interface AccountViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) UITableView* table;
@property (nonatomic, strong) NSArray* settings;

@property (nonatomic, strong) id keyboardNotificationId;

@end




@implementation AccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    item.leftBarButtonItem = [self backButtonInNavBar];
    
    NSString* title = NSLocalizedString(@"Account", @"Account");
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
    
    [self _prepareTable];
    
    table.dataSource = self;
    table.delegate = self;
    self.table = table;
    
}

-(BOOL) haveCocoaButton
{
    return NO;
}

-(void) _hideKeyboard
{
    [self.table endEditing:YES];
}

-(void) _keyboardNotification:(BOOL)listen
{
    if (listen) {
        
        id id3 = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillChangeFrameNotification
                                                                   object:nil
                                                                    queue:[NSOperationQueue mainQueue]
                                                               usingBlock:^(NSNotification* notif){
                                                                   CGRect r = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
                                                                   
                                                                   NSInteger animType = [notif.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
                                                                   CGFloat duration = [notif.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
                                                                   
                                                                   [UIView animateWithDuration:duration
                                                                                         delay:0.
                                                                                       options:animType
                                                                                    animations:^{
                                                                                        CGRect rsv = self.table.frame;
                                                                                        rsv.size.height = r.origin.y - 20;
                                                                                        self.table.frame = rsv;
                                                                                    }
                                                                                    completion:nil];
                                                               }];
        
        self.keyboardNotificationId = id3;
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardNotificationId];
    }
    
}


#define TITLE @"title"
#define CONTENT @"content"

#define TEXT @"t"
#define TEXT_2 @"dt"
#define ACTION @"a"
#define DACTION @"da"

-(void)_prepareTable
{
    
    
    NSArray* infos = @[
                       @{TEXT: @"Name", TEXT_2 : self.account.person.name, DACTION : @"EDIT_NAME"},
                       @{TEXT: @"Address", TEXT_2 : self.account.userMail},
                       @{TEXT: @"Password", TEXT_2 : @"password", DACTION : @"EDIT_PASS"},
                       @{TEXT: @"Signature", ACTION : @"OPEN_SIGN"},
                       @{TEXT: @"Server settings", ACTION : @"OPEN_SERVER"}
                        ];
    
    
    NSString* tAccount = NSLocalizedString(@"ACCOUNT DETAILS", @"ACCOUNT DETAILS");
    NSDictionary* Paccounts = @{TITLE:tAccount, CONTENT:infos};
    
    NSString* tButton = NSLocalizedString(@"COCOA BUTTON", @"COCOA BUTTON");
    NSDictionary* Pbutton = @{TITLE:tButton, CONTENT:@[@{DACTION : @"EDIT_CODE"}]};
    
    NSString* tDelete = NSLocalizedString(@"Delete account", @"Delete account");
    NSDictionary* PDelete = @{TITLE:@"", CONTENT:@[@{TEXT:tDelete, DACTION : @"DELETE"}]};
    
    self.settings = @[Paccounts, Pbutton, PDelete];
    
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self _keyboardNotification:YES];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self _keyboardNotification:NO];
}

-(void) cleanBeforeGoingBack
{
    [self _keyboardNotification:NO];
    
    self.table.delegate = nil;
    self.table.dataSource = nil;
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView.isDragging) {
        [self _hideKeyboard];
    }
}


#pragma mark - Table Datasource


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.settings.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* sectionInfos = self.settings[section];
    NSArray* content = sectionInfos[CONTENT];
    
    return content.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat base = 52.f;
    
    if (indexPath.row==0) {
        base += .5;
        if (indexPath.section == 1) {
            base += 73;
        }
    }
    
    return base;
}

-(void) _updateCocoaButton
{
    if (self.account == [[Accounts sharedInstance] currentAccount]) {
        [ViewController refreshCocoaButton];
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary* sectionInfos = self.settings[indexPath.section];
    NSArray* content = sectionInfos[CONTENT];
    NSDictionary* infoCell = content[indexPath.row];
    
    
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noID"];
    
    
    cell.textLabel.text = infoCell[TEXT];
    
    cell.textLabel.textAlignment = NSTextAlignmentNatural;
    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    
    CGSize bounds = tableView.bounds.size;
    bounds.height = 52;
    
    if (infoCell[TEXT_2] != nil) {
        
        
        UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(100, 0, bounds.width - 110, bounds.height)];
        tf.text = infoCell[TEXT_2];
        tf.delegate = self;
        [cell addSubview:tf];
        
        NSString* action = infoCell[DACTION];

        if (action == nil) {
            tf.userInteractionEnabled = NO;
        }
        else {
            if ([action isEqualToString:@"EDIT_PASS"]) {
                tf.secureTextEntry = YES;
            }
        }
        
    }
    
    
    if (infoCell[DACTION]!=nil) {
        
        NSString* action = infoCell[DACTION];
        
        if ([action isEqualToString:@"EDIT_CODE"]) {
            EditCocoaButtonView* ecbv = [EditCocoaButtonView editCocoaButtonViewForAccount:self.account];
            ecbv.backgroundColor = [UIColor clearColor];
            ecbv.cocobuttonUpdated = ^(){
                [self _updateCocoaButton];
            };
            
            [cell addSubview:ecbv];
        }
        else if ([action isEqualToString:@"NAV_BAR_SOLID"]) {
        }
        else if ([action isEqualToString:@"DELETE"]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor colorWithRed:1. green:0.07 blue:0.0 alpha:1.0];
        }
        
    }
    else if (infoCell[ACTION]!=nil) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* sectionInfos = self.settings[section];
    return sectionInfos[TITLE];
}


#pragma mark Table Delegate

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 52;
}


-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* sectionInfos = self.settings[indexPath.section];
    NSArray* content = sectionInfos[CONTENT];
    NSDictionary* infoCell = content[indexPath.row];
    
    NSString* directAction = infoCell[DACTION];
    
    if (directAction.length>0) {
        
        NSArray* reload = nil;
        
        if ([directAction isEqualToString:@"BADGE_COUNT"]) {
        }
        else if ([directAction isEqualToString:@"NAV_BAR_BLUR"]) {
        }
        else if ([directAction isEqualToString:@"EDIT_CODE"]) {
        }
        else if ([directAction isEqualToString:@"DELETE"]) {
            if ([[Accounts sharedInstance] deleteAccount:self.account]) {

                [ViewController refreshCocoaButton];
                
                if ([Accounts sharedInstance].accounts.count>1) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBACK_NOTIFICATION object:nil];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCREATE_FIRST_ACCOUNT_NOTIFICATION object:nil];
                }
            }
        }
        
        if (reload.count > 0) {
            [tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationNone];
        }
        
        return nil;
    }
    
    NSString* action = infoCell[ACTION];
    
    if (action.length>0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:action object:nil];
        return nil;
    }
    
    
    return nil;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - TextField delegate

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


@end


