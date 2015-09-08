//
//  AddAccountViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 05/09/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "AddAccountViewController.h"

#import "Accounts.h"
#import "EditCocoaButtonView.h"


@interface AddAccountViewController ()

@property (nonatomic, strong) Account* account;

@end


@interface AddAccountViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) UITableView* table;
@property (nonatomic, strong) NSArray* settings;

@property (nonatomic, weak) UITextField* username;
@property (nonatomic, weak) UITextField* email;
@property (nonatomic, weak) UITextField* password;

@property (nonatomic, weak) EditCocoaButtonView* editCocoa;
@property (nonatomic) NSInteger step;

@property (nonatomic, weak) UIButton* googleBtn;

@end



@implementation AddAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    if (self.firstRunMode == NO) {
        item.leftBarButtonItem = [self backButtonInNavBar];
    }
    
    NSString* title = NSLocalizedString(@"Add account", @"Add account");
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:title];
    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       242/*screenBounds.size.height-20*/)
                                                      style:UITableViewStyleGrouped];
    table.contentInset = UIEdgeInsetsMake(44, 0, 60, 0);
    table.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    table.backgroundColor = [UIGlobal standardLightGrey];
    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    [self.view addSubview:table];
    
    [self setupNavBarWith:item overMainScrollView:table];
    
    [self _prepareTable];
    
    table.scrollEnabled = NO;
    
    table.dataSource = self;
    table.delegate = self;
    self.table = table;
    
    
    UIImageView* cocoa = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cocoamail"]];
    
    CGFloat posYbutton = screenBounds.size.height - 20 - (70+45);
    cocoa.frame = CGRectMake(0, 242, screenBounds.size.width, posYbutton + 35 - 242);
    cocoa.contentMode = UIViewContentModeCenter;
    
    [self.view addSubview:cocoa];
    
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tap:)];
    [cocoa addGestureRecognizer:tgr];
    cocoa.userInteractionEnabled = YES;
    
    UIButton* google = [[UIButton alloc] initWithFrame:CGRectMake(0, posYbutton, screenBounds.size.width, 70+45)];
    [google setImage:[UIImage imageNamed:@"signGoogle_on"] forState:UIControlStateNormal];
    [google setImage:[UIImage imageNamed:@"signGoogle_off"] forState:UIControlStateHighlighted];
    [google addTarget:self action:@selector(_google:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:google];
    self.googleBtn = google;
}

-(BOOL) haveCocoaButton
{
    return NO;
}

-(void) _tap:(UITapGestureRecognizer*)tgr
{
    if (tgr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    [self _hideKeyboard];
}

-(void) _google:(UIButton*)sender
{
    [ViewController presentAlertWIP:@"google sign in…"];
}

-(void) _hideKeyboard
{
    [self.table endEditing:YES];
}


#define TITLE @"title"
#define CONTENT @"content"

#define TEXT @"t"
#define DACTION @"da"

-(void)_prepareTable
{
    
    NSArray* infos = @[
                       @{TEXT: @"Username", DACTION : @"EDIT_NAME"},
                       @{TEXT: @"Email", DACTION : @"EDIT_MAIL"},
                       @{TEXT: @"Password", DACTION : @"EDIT_PASS"}
                       ];
    
    NSDictionary* Paccounts = @{TITLE:@"", CONTENT:infos};
    
    NSString* tDelete = NSLocalizedString(@"OK", @"OK");
    NSDictionary* PDelete = @{TITLE:@"", CONTENT:@[@{TEXT:tDelete, DACTION : @"VALIDATE"}]};
    
    self.settings = @[Paccounts, PDelete];
    
}


-(void) cleanBeforeGoingBack
{
    [self _hideKeyboard];
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
    
    CGFloat base = 44.f;
    
    if (indexPath.row==0) {
        base += .5;
        /*
        if (indexPath.section == 1) {
            base += 60;
        }
         */
    }
    
    return base;
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
    bounds.height = 44.f;
    
    
    NSString* action = infoCell[DACTION];

    if ([action isEqualToString:@"VALIDATE"]) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIGlobal standardBlue];
    }
    else {
        
        UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(100, 0, bounds.width - 110, bounds.height)];
        tf.delegate = self;
        [cell addSubview:tf];
        
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        
        if ([action isEqualToString:@"EDIT_PASS"]) {
            tf.secureTextEntry = YES;
            self.password = tf;
        }
        else if ([action isEqualToString:@"EDIT_MAIL"]) {
            tf.keyboardType = UIKeyboardTypeEmailAddress;
            self.email = tf;
        }
        else {
            self.username = tf;
        }
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
    return 10;
}


-(void) _nextStep
{
    if (self.step == 0) {
        
        
        Account* ac = [Account emptyAccount];
        ac.userColor = [[Accounts sharedInstance] accountColors][0];

        BOOL added = NO;

        NSString* mail = self.email.text;
        NSUInteger loc = [mail rangeOfString:@"@"].location;
        NSUInteger locDot = [mail rangeOfString:@"." options:NSBackwardsSearch].location;
        
        if (loc != NSNotFound && loc > 2 &&  locDot != NSNotFound && loc < locDot) {
            
            NSString* code = [[mail substringToIndex:3] uppercaseString];
            
            Person* p = [Person createWithName:self.username.text email:mail icon:nil codeName:code];
            added = YES;
            ac.person = p;
        }

        
        if (self.username.text.length>2) {
            added = YES;
        }
        
        if (added) {
            ac.userMail = mail;
            self.account = ac;
            self.step = 1;
            
            EditCocoaButtonView* ecbv = [EditCocoaButtonView editCocoaButtonViewForAccount:self.account];
            ecbv.frame = CGRectMake(0, 55, ecbv.frame.size.width, ecbv.frame.size.height);
            [self.view addSubview:ecbv];
            self.editCocoa = ecbv;
            [ecbv becomeFirstResponder];
            
            UINavigationItem* item = [self.navBar.items firstObject];
            NSString* title = NSLocalizedString(@"Your Cocoa button", @"Your Cocoa button");
            item.titleView = [WhiteBlurNavBar titleViewForItemTitle:title];
            [self.navBar setNeedsDisplay];
            
            self.googleBtn.hidden = YES;
            
        }
        
        
        
    }
    else {
        
        [[Accounts sharedInstance] addAccount:self.account];

        if ([Accounts sharedInstance].accounts.count==2) {
            // it's the first account
            [Accounts sharedInstance].currentAccountIdx = 0;
            [self.account fakeInitContent];
            [ViewController refreshCocoaButton];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kBACK_NOTIFICATION object:nil];
    }
    
}


-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        NSArray* alls = [cell subviews];
        
        for (UIView* v in alls) {
            if ([v isKindOfClass:[UITextField class]]) {
                [v becomeFirstResponder];
                break;
            }
        }
    }
    else {
        [self _hideKeyboard];
        [self _nextStep];
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



