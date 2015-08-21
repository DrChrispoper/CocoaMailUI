//
//  ViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 14/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "ViewController.h"

#import "FolderViewController.h"
#import "MailListViewController.h"
#import "ConversationViewController.h"
#import "Accounts.h"
#import "CocoaButton.h"
#import "ContactsViewController.h"
#import "AttachmentsViewController.h"
#import "SettingsViewController.h"
#import "EditMailViewController.h"
#import "Parser.h"



@interface ViewController () <CocoaButtonDatasource>

@property (weak, nonatomic) IBOutlet UIView *blackStatusBar;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic, strong) NSMutableArray *viewControllers;

@property (nonatomic, weak) CocoaButton* cocoaButton;
@property (nonatomic) BOOL askAccountsButton;

@end




@implementation ViewController


static ViewController* s_self;

+(ViewController*) mainVC
{
    return s_self;
}

+(void) presentAlertWIP:(NSString*)message
{
    UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"WIP : %@", message] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"I wait…" style:UIAlertActionStyleDefault
                                                          handler:nil];
    [ac addAction:defaultAction];
    
    [s_self presentViewController:ac animated:YES completion:nil];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    s_self = self;
    [Accounts sharedInstance].navBarBlurred = YES;
    
    self.blackStatusBar.backgroundColor = [UIColor whiteColor];
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    self.contentView.clipsToBounds = YES;
    
    // to init accounts creation
    [Accounts sharedInstance];
    
    [self setup];
    
    CocoaButton* cb = [CocoaButton sharedButton];
    cb.center = CGPointMake(self.view.frame.size.width - 30, self.view.frame.size.height - 30);
    [self.view addSubview:cb];
    cb.datasource = self;
    self.cocoaButton = cb;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) refreshCocoaButton
{
    [self.cocoaButton updateColor];
}


- (void)setup
{
    
    FolderViewController* f = [[FolderViewController alloc] init];
    f.view.frame = self.contentView.bounds;
    [self.contentView addSubview:f.view];

    self.viewControllers = [NSMutableArray arrayWithObject:f];

    [self setupNavigation];
    
    
    UIView* border = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, self.view.frame.size.height)];
    border.backgroundColor = [UIColor clearColor];
    border.userInteractionEnabled = YES;
    border.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    UISwipeGestureRecognizer* sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipeBack:)];
    sgr.direction = UISwipeGestureRecognizerDirectionRight;
    [border addGestureRecognizer:sgr];
    [self.view addSubview:border];
}


-(void) _swipeBack:(UISwipeGestureRecognizer*)sgr
{
    if (sgr.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBACK_NOTIFICATION object:nil];
    }
}



-(void) setupNavigation
{
    UIApplication* app = [UIApplication sharedApplication];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPRESENT_FOLDER_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        MailListViewController* f = nil;
        Person* person = [notif.userInfo objectForKey:kPRESENT_FOLDER_PERSON];
        
        if (person != nil) {
            f = [[MailListViewController alloc] initWithPerson:person];
        }
        else {
            NSString* name = [notif.userInfo objectForKey:kPRESENT_FOLDER_NAME];
            f = [[MailListViewController alloc] initWithName:name];
        }
        [self _animatePushVC:f];
        
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kPRESENT_SETTINGS_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        SettingsViewController* f = [[SettingsViewController alloc] init];
        [self _animatePushVC:f];
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPRESENT_CONVERSATION_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        ConversationViewController* f = [[ConversationViewController alloc] init];
        f.conversation = [notif.userInfo objectForKey:kPRESENT_CONVERSATION_KEY];
        [self _animatePushVC:f];
        
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kPRESENT_CONVERSATION_ATTACHMENTS_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        AttachmentsViewController* f = [[AttachmentsViewController alloc] init];
        f.conversation = [notif.userInfo objectForKey:kPRESENT_CONVERSATION_KEY];
        [self _animatePushVC:f];
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPRESENT_CONTACTS_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        ContactsViewController* f = [[ContactsViewController alloc] init];
        f.mail = [notif.userInfo objectForKey:kPRESENT_MAIL_KEY];
        [self _animatePushVC:f];
        
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kPRESENT_EDITMAIL_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        EditMailViewController* f = [[EditMailViewController alloc] init];
        f.mail = [notif.userInfo objectForKey:kPRESENT_MAIL_KEY];
        [self _animatePushVC:f];
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kBACK_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        if (self.viewControllers.count == 1) {
            return;
        }

        [app beginIgnoringInteractionEvents];
        
        InViewController* vc = [self.viewControllers lastObject];
        [vc cleanBeforeGoingBack];
        UIView* lastView = vc.view;
        [self.viewControllers removeLastObject];
        
        InViewController* f = [self.viewControllers lastObject];
        
        // tweak to realod nav bar after settings view
        if ([vc isKindOfClass:[SettingsViewController class]] && [f isKindOfClass:[FolderViewController class]]) {
            FolderViewController* f = [[FolderViewController alloc] init];
            f.view.frame = self.contentView.bounds;
            UIView* nextView = f.view;
            [self.contentView insertSubview:nextView belowSubview:lastView];
            
            self.viewControllers = [NSMutableArray arrayWithObject:f];
        }
        //
        else {
            UIView* nextView = f.view;
            [self.contentView insertSubview:nextView belowSubview:lastView];
        }
        
        [self.cocoaButton forceCloseButton];
        
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             lastView.transform = CGAffineTransformMakeTranslation(self.view.bounds.size.width, 0);
                         }
                         completion:^(BOOL fini) {
                             [lastView removeFromSuperview];
                             [app endIgnoringInteractionEvents];
                         }];
        
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kACCOUNT_CHANGED_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue]  usingBlock: ^(NSNotification* notif){
        [app beginIgnoringInteractionEvents];
        
        [[Parser sharedParser] cleanConversations];
        
        BOOL inFolders = self.viewControllers.count == 1;
        
        BOOL noAnim = YES;
        
        InViewController* vc = [self.viewControllers lastObject];
        UIView* lastView = vc.view;
        
        FolderViewController* f = [[FolderViewController alloc] init];

        UIView* nextView = f.view;
        
        if (inFolders) {
            self.viewControllers = [NSMutableArray arrayWithObject:f];
        }
        else {
            NSString* name = [[Accounts systemFolderNames] firstObject];
            MailListViewController* inbox = [[MailListViewController alloc] initWithName:name];
            inbox.view.frame = self.contentView.bounds;
            nextView = inbox.view;
            
            self.viewControllers = [NSMutableArray arrayWithObjects:f, inbox, nil];
        }
        
        [self.contentView insertSubview:nextView belowSubview:lastView];
        
        if (noAnim) {
            [lastView removeFromSuperview];
            [app endIgnoringInteractionEvents];
        }
        else {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 lastView.transform = CGAffineTransformMakeTranslation(self.view.bounds.size.width, 0);
                             }
                             completion:^(BOOL fini) {
                                 [lastView removeFromSuperview];
                                 [app endIgnoringInteractionEvents];
                             }];
        }
        
    }];
    
    
    
}

-(void) _animatePushVC:(InViewController*)nextVC
{
    UIApplication* app = [UIApplication sharedApplication];
    
    InViewController* currentVC = [self.viewControllers lastObject];
    UIView* currentView = currentVC.view;
    
    UIView* nextView = nextVC.view;
    CGRect frameForSpring = self.contentView.bounds;
    frameForSpring.size.width += 100;
    nextView.frame = frameForSpring;
    
    [self.contentView addSubview:nextView];
    [self.viewControllers addObject:nextVC];
    
    [self.cocoaButton forceCloseButton];
    
    nextView.transform = CGAffineTransformMakeTranslation(self.view.bounds.size.width, 0);
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         nextView.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL fini) {
                         [currentView removeFromSuperview];
                         nextView.frame = self.contentView.bounds;
                         [app endIgnoringInteractionEvents];
                     }];
    
}

// Cocoa button

-(void) _openAccounts
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.cocoaButton forceCloseButton];
    }
                     completion:^(BOOL fini){
                         self.askAccountsButton = YES;
                         [self.cocoaButton openHorizontal];
                     }];
    
}

-(void) _editMail
{
    [ViewController presentAlertWIP:@"open edit mail"];
}

-(void) _search
{
    [ViewController presentAlertWIP:@"open search view"];
}


-(NSArray*) buttonsWideFor:(CocoaButton*)cocoabutton
{
    InViewController* currentVC = [self.viewControllers lastObject];
    
    if ([currentVC conformsToProtocol:@protocol(CocoaButtonDatasource)]) {
        id<CocoaButtonDatasource> src = (id<CocoaButtonDatasource>)currentVC;
        NSArray* res = [src buttonsWideFor:cocoabutton];
        if (res != nil)
            return res;
    }
    
    
    UIButton* b1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b1 setImage:[UIImage imageNamed:@"edit_off"] forState:UIControlStateNormal];
    [b1 setImage:[UIImage imageNamed:@"edit_on"] forState:UIControlStateHighlighted];
    [b1 addTarget:self action:@selector(_editMail) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton* b2 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b2 setImage:[UIImage imageNamed:@"search_off"] forState:UIControlStateNormal];
    [b2 setImage:[UIImage imageNamed:@"search_on"] forState:UIControlStateHighlighted];
    [b2 addTarget:self action:@selector(_search) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton* b3 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b3 setImage:[UIImage imageNamed:@"accounts_off"] forState:UIControlStateNormal];
    [b3 setImage:[UIImage imageNamed:@"accounts_on"] forState:UIControlStateHighlighted];
    [b3 addTarget:self action:@selector(_openAccounts) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray* buttons = @[b1, b2, b3];

    return buttons;
}


-(void) _moreAccount
{
    [ViewController presentAlertWIP:@"account creation view"];
    [self.cocoaButton forceCloseButton];
}

-(void) _applyAccountButton:(UIButton*)button
{
    [self.cocoaButton closeHorizontalButton:button refreshCocoaButtonAndDo:^{
        [Accounts sharedInstance].currentAccountIdx = button.tag;
        [[NSNotificationCenter defaultCenter] postNotificationName:kACCOUNT_CHANGED_NOTIFICATION object:nil];
    }];
}


-(NSArray*) _accountsButtons
{
    const CGRect baseRect = self.cocoaButton.bounds;
    
    NSArray* alls = [Accounts sharedInstance].accounts;
    NSMutableArray* buttons = [NSMutableArray arrayWithCapacity:alls.count];
    NSInteger currentAIdx = [Accounts sharedInstance].currentAccountIdx;
    
    NSInteger idx = 0;
    for (Account* a in alls) {
        
        if (idx == currentAIdx) {
            idx++;
            continue;
        }
        
        UIButton* b = [[UIButton alloc] initWithFrame:baseRect];
        
        b.backgroundColor = a.userColor;
        [b setTitle:a.codeName forState:UIControlStateNormal];
        b.layer.cornerRadius = 22;
        b.layer.masksToBounds = YES;
        b.titleLabel.font = [UIFont systemFontOfSize:13];
        
        b.tag = idx;
        [b addTarget:self action:@selector(_applyAccountButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [buttons addObject:b];
        
        idx++;
    }
    
    // more btn
    UIButton* b = [[UIButton alloc] initWithFrame:baseRect];
    b.backgroundColor = [UIColor blackColor];
    [b setImage:[UIImage imageNamed:@"add_accounts"] forState:UIControlStateNormal];
    [b setImage:[UIImage imageNamed:@"add_accounts"] forState:UIControlStateHighlighted];
    b.layer.cornerRadius = 22;
    b.layer.masksToBounds = YES;
    [b addTarget:self action:@selector(_moreAccount) forControlEvents:UIControlEventTouchUpInside];
    [buttons addObject:b];
    
    return buttons;
}

-(NSArray*) buttonsHorizontalFor:(CocoaButton*)cocoabutton
{
    if (self.askAccountsButton) {
        self.askAccountsButton = NO;
        return [self _accountsButtons];
    }
    
    InViewController* currentVC = [self.viewControllers lastObject];
    
    if ([currentVC conformsToProtocol:@protocol(CocoaButtonDatasource)]) {
        id<CocoaButtonDatasource> src = (id<CocoaButtonDatasource>)currentVC;
        return [src buttonsHorizontalFor:cocoabutton];
    }
    
    return nil;
}


@end




@implementation InViewController

-(void) cleanBeforeGoingBack
{
    // clean delegates
}

-(void) _back
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kBACK_NOTIFICATION object:nil];
}

@end

