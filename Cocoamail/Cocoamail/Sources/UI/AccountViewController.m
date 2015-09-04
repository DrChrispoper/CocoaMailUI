//
//  AccountViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 04/09/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "AccountViewController.h"


#import "Accounts.h"
#import "CocoaButton.h"

@interface AccountViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) UITableView* table;
@property (nonatomic, strong) NSArray* settings;

@property (nonatomic, strong) id keyboardNotificationId;
@property (nonatomic, weak) UIView* fakeCocoaButton;
@property (nonatomic, weak) UITextField* editCodeName;

@end



@interface ChooseColorView : UIView

-(instancetype) initWithFrame:(CGRect)frame forAccountColor:(UIColor*)color;

@property (nonatomic, copy) void (^tapColor)(UIColor*);

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
    
    NSArray* infosB = @[
                       @{DACTION : @"EDIT_CODE"},
                       @{DACTION : @"EDIT_COLOR"}
                       ];
    
    NSDictionary* Pbutton = @{TITLE:tButton, CONTENT:infosB};
    
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

#pragma mark - Scroll View Delegate

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView.isDragging) {
        [self _hideKeyboard];
    }
}



-(void) cleanBeforeGoingBack
{
    [self _keyboardNotification:NO];
    
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
    NSArray* content = sectionInfos[CONTENT];
    
    return content.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat base = 52.f;
    
    if (indexPath.row==0) {
        base += .5;
        if (indexPath.section == 1) {
            base += 60;
        }
    }
    
    return base;
}


#define kTAG_CODE 1358

-(void) _updateCocoaButton
{
    // TODO if editing current account update real cocoa button
    
    if (self.account == [[Accounts sharedInstance] currentAccount]) {
        [ViewController refreshCocoaButton];
    }
    
    if (self.fakeCocoaButton==nil) {
        return;
    }
    
    
    UIView* superview = self.fakeCocoaButton.superview;
    
    CocoaButton* cb = [CocoaButton fakeCocoaButtonForAccount:self.account];
    cb.center = self.fakeCocoaButton.center;
    cb.userInteractionEnabled = NO;
    [superview addSubview:cb];
    [self.fakeCocoaButton removeFromSuperview];
    self.fakeCocoaButton = cb;
    
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
        
        if ([action isEqualToString:@"EDIT_COLOR"]) {
            
            ChooseColorView* v = [[ChooseColorView alloc] initWithFrame:CGRectMake(0, 0, bounds.width, bounds.height) forAccountColor:self.account.userColor];
            v.tapColor = ^(UIColor* color){
                self.account.userColor = color;
                [self _updateCocoaButton];
            };
            [cell addSubview:v];
            
        }
        else if ([action isEqualToString:@"EDIT_CODE"]) {
            
            CocoaButton* cb = [CocoaButton fakeCocoaButtonForAccount:self.account];
            cb.center = CGPointMake(bounds.width / 2.f, 35.f);
            cb.userInteractionEnabled = NO;
            [cell addSubview:cb];
            self.fakeCocoaButton = cb;
            
            UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(50, 60, bounds.width - 100, bounds.height)];
            tf.tag = kTAG_CODE;
            tf.textAlignment = NSTextAlignmentCenter;
            tf.text = self.account.codeName;
            tf.delegate = self;
            [cell addSubview:tf];
            
            self.editCodeName = tf;
            
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
            [self.editCodeName becomeFirstResponder];
        }
        else if ([directAction isEqualToString:@"DELETE"]) {
            [ViewController presentAlertWIP:@"delete account…"];
        }
        
        if (reload.count > 0) {
            [tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationNone];
        }
        
        return nil;
    }
    
    NSString* action = infoCell[ACTION];
    
    if (action.length>0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:action object:nil userInfo:nil];
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

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == kTAG_CODE) {
        
        NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];

        if (newText.length<4) {
            textField.text = [newText uppercaseString];
            
            self.account.codeName = textField.text;
            [self _updateCocoaButton];
            
        }
        
        return NO;
    }
    
    return YES;
}

@end





@interface ChooseColorView ()

@property (nonatomic, strong) NSArray* colors;

@end





@implementation ChooseColorView

-(instancetype) initWithFrame:(CGRect)frame forAccountColor:(UIColor*)accColor
{
    self = [super initWithFrame:frame];
    
    self.backgroundColor = [UIColor whiteColor];
    
    const CGFloat BIG = 44.f;
    const CGFloat halfBIG = BIG / 2.f;
    
    
    CGFloat posX = 8.f + halfBIG;
    const CGFloat step = (frame.size.width - (2.f*posX))/6.f;
    
    NSArray* allColors = [Accounts sharedInstance].accountColors;
    
    NSMutableArray* c = [NSMutableArray arrayWithCapacity:allColors.count];
    
    NSInteger wantedIdx = 0;
    
    for (UIColor* color in allColors) {
        
        if (color == accColor) {
            wantedIdx = [allColors indexOfObject:color];
        }
        
        UIView* v = [[UIView alloc] initWithFrame:CGRectMake(posX-halfBIG, 4, BIG, BIG)];
        v.layer.cornerRadius = halfBIG;
        v.layer.masksToBounds = YES;
        v.backgroundColor = color;
        [self addSubview:v];
     
        [c addObject:v];
        
        posX = floorf(posX + step);
    }
    
    self.colors = c;
    
    [self selectColorIdx:wantedIdx];
    
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tap:)];
    [self addGestureRecognizer:tgr];
    
    self.userInteractionEnabled = YES;
    
    return self;
}

-(void) selectColorIdx:(NSInteger)idx
{
    CGFloat scale = 26.f / 44.f;

    UIView* selected = self.colors[idx];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         for (UIView* v in self.colors) {
                             if (v==selected) {
                                 v.transform = CGAffineTransformIdentity;
                             }
                             else {
                                 v.transform = CGAffineTransformMakeScale(scale, scale);
                             }
                         }
                     }];
}

-(void)_tap:(UITapGestureRecognizer*)tgr
{
    if (tgr.state != UIGestureRecognizerStateEnded || !tgr.enabled) {
        return;
    }
    
    CGPoint pos = [tgr locationInView:tgr.view];
    
    CGFloat step = self.bounds.size.width / 7.f;
    
    NSInteger posX = (NSInteger)(pos.x / step);
    
    if (posX<0) {
        posX = 0;
    }
    else if (posX>6) {
        posX = 6;
    }
    [self selectColorIdx:posX];
    
    UIColor* c = [Accounts sharedInstance].accountColors[posX];
    self.tapColor(c);
    
}





@end


