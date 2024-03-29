//
//  EditMailViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 21/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "EditMailViewController.h"

#import "Accounts.h"



typedef enum : NSUInteger {
    ContentNone,
    ContentTo,
    ContentCC,
    ContentSubject,
    ContentBody,
    ContentAttach,
    ContentOld
} ContentType;


@class ExpendableBadge;

@protocol ExpendableBadgeDelegate

-(void) removePersonAtIndex:(NSInteger)idx;
-(void) closeOthersBadge:(ExpendableBadge*)badge;

@end



@interface EditMailViewController () <UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, ExpendableBadgeDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UIView* contentView;
@property (nonatomic, weak) UIScrollView* scrollView;

@property (nonatomic, weak) UITextView* subjectTextView;
@property (nonatomic, weak) UITextView* bodyTextView;
@property (nonatomic, strong) id keyboardNotificationId;

@property (nonatomic) BOOL personsAreHidden;

@property (nonatomic, weak) UIButton* sendButton;
@property (nonatomic, weak) UIButton* attachButton;

@property (nonatomic, weak) UIView* searchUI;
@property (nonatomic, weak) UITableView* searchTableView;
@property (nonatomic, strong) NSArray* currentSearchPersonList;
@property (nonatomic, weak) UITextField* toTextField;
@property (nonatomic, weak) UIButton* toButton;

@property (nonatomic, weak) UITapGestureRecognizer* tapContentGesture;

@property (nonatomic, strong) Account* selectedAccount;
@property (nonatomic, strong) NSMutableArray* viewsWithAccountTintColor;

@property (nonatomic, strong) NSMutableArray* expandableBadges;


@end



@interface ExpendableBadge : UIView

-(instancetype) initWithFrame:(CGRect)frame andPerson:(Person*)p;
-(void) setupWithIndex:(NSInteger)idx andDelegate:(id<ExpendableBadgeDelegate>)delegate;
-(void) isHiddenContact;

-(void) close;

@end




@implementation EditMailViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.mail == nil) {
        self.mail = [Mail newMailFormCurrentAccount];
    }
    
//    self.view.backgroundColor = [UIGlobal standardLightGrey];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"editmail_cancel_off" andHighlighted:@"editmail_cancel_on"];
    [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    UIButton* send = [WhiteBlurNavBar navBarButtonWithImage:@"editmail_send_off" andHighlighted:@"editmail_send_on"];
    UIImage* imgNo = [[UIImage imageNamed:@"editmail_send_no"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [send setImage:imgNo forState:UIControlStateDisabled];
    [send addTarget:self action:@selector(_send) forControlEvents:UIControlEventTouchUpInside];
    item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:send];
    
    self.sendButton = send;
    
    Accounts* allAccounts = [Accounts sharedInstance];
    Account* ca = nil;
    if (self.mail.fromPersonID < 0) {
        ca = allAccounts.accounts[-(1+self.mail.fromPersonID)];
    }
    else {
        Account* ca = [allAccounts currentAccount];
        if (ca.isAllAccounts) {
            ca = [allAccounts.accounts objectAtIndex:allAccounts.defaultAccountIdx];
        }
    }
    
    self.selectedAccount = ca;
    self.viewsWithAccountTintColor = [NSMutableArray arrayWithCapacity:20];
    
    back.tintColor = [ca userColor];
    send.tintColor = [ca userColor];
    
    [self.viewsWithAccountTintColor addObject:back];
    [self.viewsWithAccountTintColor addObject:send];
    
    UILabel* titleView = [WhiteBlurNavBar titleViewForItemTitle:ca.userMail];
    
    if (allAccounts.accounts.count>1) {
        
        titleView.userInteractionEnabled = YES;
        UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapTitle:)];
        [titleView addGestureRecognizer:tgr];
        
        UIView* support = [[UIView alloc] initWithFrame:CGRectInset(titleView.bounds, -12, -6.75)];
        CGRect f = support.frame;
        f.origin.x = floorf(f.origin.x);
        f.origin.y = floorf(f.origin.y);
        f.size.width = floorf(f.size.width);
        f.size.height = 33.;
        support.frame = f;
        
        support.layer.borderColor = [UIGlobal noImageBadgeColor].CGColor;
        support.layer.borderWidth = 0.5;
        support.userInteractionEnabled = NO;
        support.backgroundColor = [UIColor clearColor];
        support.layer.cornerRadius = 33./2.;
        
        support.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [titleView addSubview:support];
        
    }
    item.titleView = titleView;
    
    [self _setup];
    
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapContent:)];
    [self.view addGestureRecognizer:tgr];
    self.tapContentGesture = tgr;
    
    [self _keyboardNotification:YES];
    
    [self setupNavBarWith:item overMainScrollView:self.scrollView];
    
    self.navBar.frame = CGRectInset(self.navBar.frame, -5, 0);
    
    BOOL isReply = NO;
    
    if (self.mail.fromMail) {
        if (self.mail.toPersonID.count>0) {
            isReply = YES;
        }
    }
    
    if (isReply) {
        [self.bodyTextView becomeFirstResponder];
    }
    else {
        [self.toTextField becomeFirstResponder];
    }
    
}


-(BOOL) haveCocoaButton
{
    return NO;
}

-(void) cleanBeforeGoingBack
{
    [self _hideKeyboard];
    [self _keyboardNotification:NO];
    
    self.scrollView.delegate = nil;
}

#pragma mark - Interaction Cleaning

-(void) closeOthersBadge:(ExpendableBadge*)badgeOpening
{
    for (ExpendableBadge* badge in self.expandableBadges) {
        if (badge != badgeOpening) {
            [badge close];
        }
    }
}


-(void) _closeCurrentInteractingView
{
    [self _closeBadge];
    [self _hideKeyboard];
}

-(void) _closeBadge
{
    for (ExpendableBadge* badge in self.expandableBadges) {
        [badge close];
    }
}

-(void) _hideKeyboard
{
    [self.contentView endEditing:YES];
}

-(void) _tapContent:(UITapGestureRecognizer*)tgr
{
    if (!tgr.enabled || tgr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (![self.bodyTextView isFirstResponder]) {
        CGPoint pos = [tgr locationInView:self.view];
        if (pos.y > self.scrollView.contentSize.height) {
            [self.bodyTextView becomeFirstResponder];
            return;
        }
    }
    
    [self _closeCurrentInteractingView];
}


#pragma mark - UI

-(void) _back
{
    BOOL haveSomething = self.subjectTextView.text.length > 0
    || [self.bodyTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0
    || self.mail.attachments.count>0 ;
    
    if (haveSomething) {
        
        // auto-save
        self.mail.title = self.subjectTextView.text;
        self.mail.content = self.bodyTextView.text;
        
        [self.selectedAccount saveDraft:self.mail];
        [self _reallyGoBack];
        
        /*
        UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil
                                                                    message:NSLocalizedString(@"Save to drafts ?", @"Save to drafts ?")
                                                             preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save") style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction* aa) {
                                                                  
                                                                  self.mail.title = self.subjectTextView.text;
                                                                  self.mail.content = self.bodyTextView.text;
                                                                  
                                                                  [self.selectedAccount saveDraft:self.mail];
                                                                  [self _reallyGoBack];
                                                              }];
        [ac addAction:defaultAction];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete") style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction* aa) {
                                                                  [self.selectedAccount deleteDraft:self.mail];
                                                                  [self _reallyGoBack];
                                                              }];
        [ac addAction:cancelAction];
        
        
        ViewController* vc = [ViewController mainVC];
        
        [vc presentViewController:ac animated:YES completion:nil];
         */
        
    }
    else {
        [self _reallyGoBack];
    }
}

-(void) _reallyGoBack
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kBACK_NOTIFICATION object:nil];
}


-(void) _send
{
    self.mail.title = self.subjectTextView.text;
    self.mail.content = self.bodyTextView.text;
    
    [self.selectedAccount sendMail:self.mail];
    
    [self _reallyGoBack];
}

-(void) _manageSendButton
{
    self.sendButton.enabled = /*self.subjectTextView.text.length>0 &&*/ self.mail.toPersonID.count>0;
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
                                                                                        CGRect rsv = self.scrollView.frame;
                                                                                        rsv.size.height = r.origin.y - 20;
                                                                                        self.scrollView.frame = rsv;
                                                                                        
                                                                                    }completion:nil];
                                                               }];
        
        
        self.keyboardNotificationId = id3;
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardNotificationId];
    }
    
}

-(void) _setup
{
    const CGFloat WIDTH = [UIScreen mainScreen].bounds.size.width;
    
    UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 1000)];
    contentView.backgroundColor = [UIColor whiteColor];
    
    UIScrollView* sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.contentSize = contentView.frame.size;
    [sv addSubview:contentView];
    sv.backgroundColor = self.view.backgroundColor;
    self.contentView = contentView;
    
    [self.view addSubview:sv];
    sv.delegate = self;
    self.scrollView = sv;

    Account* ca = self.selectedAccount;
    
    CGFloat currentPosY = 44.f;
    
    // To:
    
    UIView* toView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 45)];
    toView.backgroundColor = [UIColor whiteColor];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 10, 45)];
    label.text = @"To:";
    label.backgroundColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15.];
    label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [label sizeToFit];
    
    CGRect f = label.frame;
    f.origin.y = 0;
    f.size.height = 45;
    label.frame = f;
    
    [toView addSubview:label];
    
    UIButton* addButton = [[UIButton alloc] initWithFrame:CGRectMake(WIDTH-45, 0, 45, 45)];
    /*
    UIImage* plusOff = [[UIImage imageNamed:@"editmail_contact_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage* plusOn = [[UIImage imageNamed:@"editmail_contact_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [addButton setImage:plusOff forState:UIControlStateNormal];
    [addButton setImage:plusOn forState:UIControlStateHighlighted];
    addButton.tintColor = [ca userColor];
     */
    [addButton addTarget:self action:@selector(_addPerson) forControlEvents:UIControlEventTouchUpInside];
    addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [toView addSubview:addButton];
    self.toButton = addButton;
    self.toButton.hidden = YES;
    
    [self.viewsWithAccountTintColor addObject:addButton];
    
    UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(label.frame.size.width + 10, 1.5, WIDTH - 32 - (label.frame.size.width + 10), 43)];
    tf.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tf.font = [UIFont systemFontOfSize:15.];
    tf.textColor = [UIColor blackColor];
    tf.tag = 1;
    tf.delegate = self;
    tf.keyboardType = UIKeyboardTypeEmailAddress;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    [toView addSubview:tf];
    self.toTextField = tf;
    
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 0.5)];
    line.backgroundColor = [UIGlobal standardTableLineColor];
    [toView addSubview:line];
    
    line = [[UIView alloc] initWithFrame:CGRectMake(0, 44.5, WIDTH, 0.5)];
    line.backgroundColor = [UIGlobal standardTableLineColor];
    [toView addSubview:line];
    
    toView.tag = ContentTo;
    [contentView addSubview:toView];

    currentPosY += toView.frame.size.height;
    
    // CC:
    
    UIView* ccView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 45)];
    ccView.backgroundColor = [UIColor whiteColor];

    [contentView addSubview:ccView];
    ccView.tag = ContentCC;
    currentPosY += ccView.frame.size.height;
    
    
    // Subject:
    
    UIView* subView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 45)];
    subView.backgroundColor = [UIColor whiteColor];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 10, 45)];
    label.text = @"Subject:";
    label.backgroundColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15.];
    label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [label sizeToFit];
    
    f = label.frame;
    f.origin.y = 0;
    f.size.height = 45;
    label.frame = f;
    
    [subView addSubview:label];
    
    addButton = [[UIButton alloc] initWithFrame:CGRectMake(WIDTH-46, 0, 45, 45)];
    addButton.backgroundColor = [UIColor whiteColor];
    addButton.tintColor = [ca userColor];
    [addButton addTarget:self action:@selector(_addAttach) forControlEvents:UIControlEventTouchUpInside];
    addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [subView addSubview:addButton];
    [self.viewsWithAccountTintColor addObject:addButton];
    
    self.attachButton = addButton;
    
    UITextView* tvS = [[UITextView alloc] initWithFrame:CGRectMake(label.frame.size.width + 10, 5.5, WIDTH - 42 - (label.frame.size.width + 10), 34)];
    tvS.font = [UIFont systemFontOfSize:15.];
    tvS.textColor = [UIColor blackColor];
    tvS.delegate = self;
    [subView addSubview:tvS];
    self.subjectTextView = tvS;
    
    line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 0.5)];
    line.backgroundColor = [UIGlobal standardTableLineColor];
    [subView addSubview:line];
    
    line = [[UIView alloc] initWithFrame:CGRectMake(0, 44.5, WIDTH, 0.5)];
    line.backgroundColor = [UIGlobal standardTableLineColor];
    line.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [subView addSubview:line];
    
    
    [contentView addSubview:subView];
    subView.tag = ContentSubject;
    currentPosY += subView.frame.size.height;
    
    // Body

    UIView* bdView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 34 + 8 + 19*3 + 20)];
    bdView.backgroundColor = [UIColor whiteColor];

    UITextView* tv = [[UITextView alloc] initWithFrame:CGRectMake(3, 4, WIDTH-6, 34 + 19*3 - 3)];
    tv.textColor = [UIColor blackColor];
    tv.backgroundColor = [UIColor whiteColor];
    tv.font = [UIFont systemFontOfSize:15];
    tv.delegate = self;
    [bdView addSubview:tv];
    tv.text = @"\n\n\n";
    
    NSRange start = {0,0};
    tv.selectedRange = start;
    
    self.bodyTextView = tv;
    
    
    UILabel* signature = [[UILabel alloc] initWithFrame:CGRectMake(8, bdView.frame.size.height-28 , WIDTH-16, 20)];
    signature.textColor = [UIGlobal noImageBadgeColor];
    signature.backgroundColor = [UIColor whiteColor];
    signature.font = [UIFont systemFontOfSize:15];
    signature.text = @"Sent with CocoaMail";
    [bdView addSubview:signature];
    signature.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    
    [contentView addSubview:bdView];
    bdView.tag = ContentBody;
    currentPosY += bdView.frame.size.height;

    
    // attchments

    UIView* attachView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 1)];
    attachView.backgroundColor = [UIColor whiteColor];
    
    [contentView addSubview:attachView];
    attachView.tag = ContentAttach;
    currentPosY += attachView.frame.size.height;
    
    
    // last message
    
    
    if (self.mail.fromMail != nil) {
        
        UIView* oldView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 100)];
        oldView.backgroundColor = [UIColor whiteColor];
        
        
        UITextView* oldtv = [[UITextView alloc] initWithFrame:CGRectMake(10, 4, WIDTH-20, 50)];
        oldtv.textColor = [UIColor blackColor];
        oldtv.backgroundColor = [UIColor clearColor];
        oldtv.font = [UIFont systemFontOfSize:15];
        oldtv.editable = NO;
        oldtv.scrollEnabled = NO;
        [oldView addSubview:oldtv];
        
        Person* from = [[Persons sharedInstance] getPersonID:self.mail.fromMail.fromPersonID];
        NSString* wrote = NSLocalizedString(@"wrote", @"wrote");
        
        NSString* oldcontent = [NSString stringWithFormat:@"\n%@ %@ :\n\n%@\n", from.name, wrote, self.mail.fromMail.content];
        oldtv.text = oldcontent;
        
        [oldtv sizeToFit];

        CGRect f = oldView.frame;
        f.size.height = oldtv.frame.size.height + 20;
        oldView.frame = f;

        
        UIImage* rBack = [[UIImage imageNamed:@"cell_mail_unread"] resizableImageWithCapInsets:UIEdgeInsetsMake(44, 44, 44, 44)];
        UIImageView* iv = [[UIImageView alloc] initWithImage:[rBack imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        
        CGRect ivf = oldtv.frame;
        ivf.origin.x -= 2;
        ivf.size.width += 4;
        ivf.size.height += 6;
        iv.frame = ivf;
        iv.tintColor = [UIGlobal standardLightGrey];
        [oldView insertSubview:iv belowSubview:oldtv];
        
        [contentView addSubview:oldView];
        oldView.tag = ContentOld;
        
    }
    
    [self _createCCcontent];
    
    [self _fillTitle];
    
    if (self.mail.content.length > 0) {
        [self _fillBody];
    }
    
    [self _fixContentSize];
    
    [self _updateAttachView];
}


-(void) _fillTitle
{
    CGFloat lastH = self.subjectTextView.frame.size.height;

    self.subjectTextView.text = self.mail.title;
    
    CGRect oneLineFrame = self.subjectTextView.frame;
    
    [self.subjectTextView sizeToFit];
    
    CGFloat delta = self.subjectTextView.frame.size.height - lastH;
    
    if (delta == 0.) {
        self.subjectTextView.frame = oneLineFrame;
    }
    else {
        UIView* subject = [self.contentView viewWithTag:ContentSubject];
        CGRect r = subject.frame;
        r.size.height += delta;
        subject.frame = r;
        [self _subjectChangeSize:delta];
    }
}

-(void) _fillBody
{
    CGFloat lastH = self.bodyTextView.frame.size.height;
    
    self.bodyTextView.text = self.mail.content;
    
    CGRect fourLineFrame = self.bodyTextView.frame;
    
    [self.bodyTextView sizeToFit];
    
    CGFloat delta = self.bodyTextView.frame.size.height - lastH;
    
    if (delta <= 0.) {
        self.bodyTextView.frame = fourLineFrame;
    }
    else {
        UIView* body = [self.contentView viewWithTag:ContentBody];
        CGRect r = body.frame;
        r.size.height += delta;
        body.frame = r;
        [self _bodyChangeSize:delta];
    }
}




#pragma mark - attach

-(void) _updateAttachView
{
    UIView* attach = [self.contentView viewWithTag:ContentAttach];
    
    UIView* old = [[attach subviews] firstObject];
    [old removeFromSuperview];
    
    UIView* content = [self _createAttachmentsView];
    
    CGRect f = attach.frame;
    
    CGFloat delta = content.frame.size.height - f.size.height;
    
    f.size.height = content.frame.size.height;
    attach.frame = f;
    
    [attach addSubview:content];
    
    if (delta != 0) {
        [self _attachChangeSize:delta];
    }
    
    UIImage* on = [[UIImage imageNamed:@"editmail_attachment_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    if (self.mail.attachments.count==0) {
        UIImage* off = [[UIImage imageNamed:@"editmail_attachment_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.attachButton setImage:off forState:UIControlStateNormal];
        [self.attachButton setImage:on forState:UIControlStateHighlighted];
    }
    else {
        UIImage* more = [[UIImage imageNamed:@"editmail_attachment_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.attachButton setImage:on forState:UIControlStateNormal];
        [self.attachButton setImage:more forState:UIControlStateHighlighted];
    }

    
}


-(UIView*) _createAttachmentsView
{
    NSArray* attachs = self.mail.attachments;
    
    if (attachs.count==0) {
        return nil;
    }
    
    CGFloat WIDTH = [UIScreen mainScreen].bounds.size.width;
    
    const CGFloat stepY = 73.f;
    
    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(2, 0, WIDTH, stepY * attachs.count)];
    v.backgroundColor = [UIColor whiteColor];
    CGFloat posY = 0.f;
    
    NSInteger idx = 0;
    
    for (Attachment* a in attachs) {
        
        
        AttachmentView* av = [[AttachmentView alloc] initWithWidth:WIDTH leftMarg:2];
        CGRect f = av.frame;
        f.origin.y = posY;
        av.frame = f;
        
        [av fillWith:a];
        [av buttonActionType:AttachmentViewActionDelete];
        [av addActionTarget:self selector:@selector(_delAttach:) andTag:idx];
        
        [v addSubview:av];
       
        idx++;
        posY += stepY;
    }
    
    return v;
    
}

-(void)_delAttach:(UIButton*)b
{
    NSMutableArray* attachs = [self.mail.attachments mutableCopy];
    [attachs removeObjectAtIndex:b.tag];
    self.mail.attachments = attachs;
    
    [self _updateAttachView];
}


#pragma mark - cc view

-(void) _createCCcontent
{
    UIColor* currentAccountColor = self.selectedAccount.userColor;
    
    UIView* ccView = [self.contentView viewWithTag:ContentCC];
    
    CGFloat delta = 0.f;
    
    if (self.mail.toPersonID.count > 0) {
        
        NSArray* alls = ccView.subviews;
        for (UIView* v in alls) {
            [v removeFromSuperview];
        }
        ccView.hidden = NO;
        
        CGFloat nextPosX = 8;
        CGFloat currentPosY = 6;
        
        const CGFloat stepX = 33 + 5;
        
        UIButton* ccButton = [[UIButton alloc] initWithFrame:CGRectMake(nextPosX, currentPosY, 33, 33)];
        [ccButton addTarget:self action:@selector(_ccButton:) forControlEvents:UIControlEventTouchUpInside];
        UIImage* ccoff = [[UIImage imageNamed:@"editmail_cc"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage* ccon = [[UIImage imageNamed:@"editmail_cci"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [ccButton setImage:ccoff forState:UIControlStateNormal];
        [ccButton setImage:ccon forState:UIControlStateSelected];
        ccButton.tintColor = currentAccountColor;
        [ccView addSubview:ccButton];
        [self.viewsWithAccountTintColor addObject:ccButton];
        
        ccButton.selected = self.personsAreHidden;
        
        nextPosX += stepX;
        
        NSInteger idx = 0;
        
        self.expandableBadges = [NSMutableArray arrayWithCapacity:self.mail.toPersonID.count];
        
        for (NSNumber* val in self.mail.toPersonID) {
            NSInteger personID = [val integerValue];
            Person* p = [[Persons sharedInstance] getPersonID:personID];
            
            if (nextPosX+33+8 >= self.view.frame.size.width) {
                currentPosY+=45;
                nextPosX = 8 + stepX;
            }
            
            ExpendableBadge* v = [[ExpendableBadge alloc] initWithFrame:CGRectMake(nextPosX, currentPosY, 33, 33) andPerson:p];
            [v setupWithIndex:idx andDelegate:self];
            idx++;
            [ccView addSubview:v];
            
            if (self.personsAreHidden) {
                [v isHiddenContact];
            }
            
            [self.expandableBadges addObject:v];
            
            nextPosX += stepX;
        }
        
        CGRect f = ccView.frame;
        f.size.height = 45;
        
        while (currentPosY>45) {
            UIView* line = [[UIView alloc] initWithFrame:CGRectMake(8 + stepX, currentPosY-6.f, self.view.frame.size.width - (8+stepX), 0.5)];
            line.backgroundColor = [UIGlobal standardTableLineColor];
            [ccView addSubview:line];
            
            currentPosY-=45;
            f.size.height += 45;
        }

        ccView.frame = f;
        
        
        UIView* subView = [self.contentView viewWithTag:ContentSubject];
        const CGFloat cible = ccView.frame.origin.y + ccView.frame.size.height;
        delta = cible - subView.frame.origin.y;
    }
    else {
        ccView.hidden = YES;
        
        UIView* subView = [self.contentView viewWithTag:ContentSubject];
        UIView* toView = [self.contentView viewWithTag:ContentTo];
        const CGFloat cible = toView.frame.origin.y + toView.frame.size.height - 0.5;
        delta = cible - subView.frame.origin.y;
    }
    
    
    
    if (delta!=0) {
        [self _ccChangeSize:delta];
    }
    
    [self _manageSendButton];
}

-(void) _ccButton:(UIButton*)b
{
    self.personsAreHidden = ! self.personsAreHidden;
    [self _createCCcontent];
}

-(void) removePersonAtIndex:(NSInteger)idx
{
    NSMutableArray* tmp = [self.mail.toPersonID mutableCopy];
    [tmp removeObjectAtIndex:idx];
    self.mail.toPersonID = tmp;
    
    [self _createCCcontent];
}



#pragma mark - Change Sizes

-(void) _fixContentSize
{
    UIView* last = [self.contentView viewWithTag:ContentOld];
    
    if (last==nil) {
        last = [self.contentView viewWithTag:ContentAttach];
        
        if (last==nil) {
            last = [self.contentView viewWithTag:ContentBody];
        }
        
    }
    
    CGFloat height = last.frame.origin.y + last.frame.size.height + 20;
    
    CGRect f = self.contentView.frame;
    f.size.height = height + 50;
    self.contentView.frame = f;

    self.scrollView.contentSize = self.contentView.frame.size;
    
}

-(void) _ccChangeSize:(CGFloat) delta
{

    UIView* subView = [self.contentView viewWithTag:ContentSubject];
    
    CGRect f = subView.frame;
    f.origin.y += delta;
    subView.frame = f;
    
    [self _subjectChangeSize:delta];
    
}

-(void) _subjectChangeSize:(CGFloat) delta
{
    UIView* body = [self.contentView viewWithTag:ContentBody];
    
    CGRect f = body.frame;
    f.origin.y += delta;
    body.frame = f;
    
    [self _bodyChangeSize:delta];
}

-(void) _bodyChangeSize:(CGFloat) delta
{
    UIView* a = [self.contentView viewWithTag:ContentAttach];
    
    CGRect f = a.frame;
    f.origin.y += delta;
    a.frame = f;
    
    [self _attachChangeSize:delta];
}

-(void) _attachChangeSize:(CGFloat) delta
{
    UIView* a = [self.contentView viewWithTag:ContentOld];
    
    CGRect f = a.frame;
    f.origin.y += delta;
    a.frame = f;
    
    [self _fixContentSize];
}




#pragma mark - TextView Delegate

-(void) textViewDidChange:(UITextView *)textView
{
    const CGFloat currentHeight = textView.frame.size.height;
    const CGFloat next = textView.contentSize.height;
    /*
    if (textView == self.subjectTextView) {
        [self _manageSendButton];
    }
    */
    if (currentHeight != next) {
        
        CGFloat delta = next - currentHeight;
        
        CGRect r = textView.frame;
        r.size.height += delta;
        textView.frame = r;
        
        if (textView == self.subjectTextView) {
            
            UIView* subject = [self.contentView viewWithTag:ContentSubject];
            
            r = subject.frame;
            r.size.height += delta;
            subject.frame = r;
            
            [self _subjectChangeSize:delta];
        }
        else {
            // body textView
            
            UIView* bogy = [self.contentView viewWithTag:ContentBody];
            
            r = bogy.frame;
            r.size.height += delta;
            bogy.frame = r;
            
            [self _bodyChangeSize:delta];

            // scroll to be on screen
            NSArray* arr = [textView selectionRectsForRange:textView.selectedTextRange];
            if (arr.count>0) {
                UITextSelectionRect* r = [arr firstObject];

                const CGRect rt1 = [bogy convertRect:r.rect fromView:textView];
                const CGRect rt2 = [self.scrollView convertRect:rt1 fromView:textView];
                const CGRect rt3 = [self.view convertRect:rt2 fromView:self.scrollView];
                
                CGFloat fixDelta = 0.f;
                if (rt3.origin.y >= self.scrollView.frame.size.height - 24) {
                    fixDelta = rt3.origin.y - (self.scrollView.frame.size.height - 24);
                    
                }
                else if (rt3.origin.y<[WhiteBlurNavBar navBarHeight] + 4) {
                    fixDelta = rt3.origin.y - ([WhiteBlurNavBar navBarHeight] + 4);
                }
                
                if (fixDelta != 0) {
                    CGPoint nextOffset = self.scrollView.contentOffset;
                    nextOffset.y += fixDelta;
                    [self.scrollView setContentOffset:nextOffset animated:YES];
                }
            }
            // scroll to be on screen
        }
    }
    
    /*
    [self _manageSendButton];
    */
}

-(BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView == self.subjectTextView) {
        if ([text rangeOfString:@"\n"].location!=NSNotFound) {
            [textView resignFirstResponder];
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - SearchUI

-(void) _presentSearchUI
{
    if (self.searchUI!=nil) {
        return;
    }
    
    self.tapContentGesture.enabled = NO;
    
    UIImage* plusOff = [[UIImage imageNamed:@"editmail_close_bubble_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage* plusOn = [[UIImage imageNamed:@"editmail_close_bubble_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.toButton setImage:plusOff forState:UIControlStateNormal];
    [self.toButton setImage:plusOn forState:UIControlStateHighlighted];
    self.toButton.tintColor = [UIGlobal noImageBadgeColor];
    self.toButton.hidden = NO;
    
    
    UIView* toView = [self.contentView viewWithTag:ContentTo];
    CGFloat posY = toView.frame.origin.y + toView.frame.size.height;
    
    UIView* searchUI = [[UIView alloc] initWithFrame:CGRectMake(0, posY, self.scrollView.frame.size.width, self.scrollView.frame.size.height - posY)];
    searchUI.backgroundColor = [UIColor whiteColor];
    
    UIImage* shadow = [UIImage imageNamed:@"editmail_shadow_stretch"];
    UIImageView* iv = [[UIImageView alloc] initWithImage:shadow];
    iv.frame = CGRectMake(0, 0, toView.frame.size.width, 3);
    iv.contentMode = UIViewContentModeScaleToFill;
    
    UITableView* tv = [[UITableView alloc] initWithFrame:searchUI.bounds style:UITableViewStyleGrouped];
    tv.delegate = self;
    tv.dataSource = self;
    tv.backgroundColor = [UIGlobal standardLightGrey];
    
    [searchUI addSubview:tv];
    [searchUI addSubview:iv];
    
    self.searchTableView = tv;
    
    CGRect fcv = self.contentView.frame;
    fcv.size = self.scrollView.frame.size;
    self.contentView.frame = fcv;
    
    self.scrollView.contentSize = self.contentView.frame.size;
    
    [self.contentView addSubview:searchUI];
    self.searchUI = searchUI;
}

-(void) _removeSearchUI
{
    if (self.searchUI == nil) {
        return;
    }
    
    self.currentSearchPersonList = nil;
    
    /*
    UIImage* plusOff = [[UIImage imageNamed:@"editmail_contact_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage* plusOn = [[UIImage imageNamed:@"editmail_contact_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.toButton setImage:plusOff forState:UIControlStateNormal];
    [self.toButton setImage:plusOn forState:UIControlStateHighlighted];
    self.toButton.tintColor = [self.selectedAccount userColor];
    */
    self.toButton.hidden = YES;
    
    self.tapContentGesture.enabled = YES;
    
    [self.searchUI removeFromSuperview];
    self.searchUI = nil;
    
    [self _fixContentSize];
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person* p = self.currentSearchPersonList[indexPath.row];
    
    NSString* reuseID = @"kPersonCellID";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    }
    
    cell.detailTextLabel.text = p.email;
    cell.textLabel.text = p.name;
    
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGFLOAT_MIN;    
}


-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person* p = self.currentSearchPersonList[indexPath.row];
    
    NSInteger idxPerson = [[Persons sharedInstance] indexForPerson:p];
    
    if (self.mail.toPersonID.count<1) {
        self.mail.toPersonID = @[@(idxPerson)];
    }
    else {
        NSMutableArray* olds = [self.mail.toPersonID mutableCopy];
        [olds addObject:@(idxPerson)];
        self.mail.toPersonID = olds;
    }
    
    [self _createCCcontent];
    
    self.toTextField.text = nil;
    [self _removeSearchUI];
    //[self.toTextField resignFirstResponder];
    
    return nil;
}



-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentSearchPersonList.count;
}

-(void) textViewDidBeginEditing:(UITextView *)textView
{
    [self _closeBadge];
}



#pragma mark - TextField Delegate

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string rangeOfString:@" "].location!=NSNotFound) {
        [self textFieldShouldReturn:textField];
        [textField becomeFirstResponder];
        return NO;
    }
    
    // TODO a real incremental search
    NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (string.length<1) {
        self.currentSearchPersonList = [[Persons sharedInstance] allPersons];
    }

    if (newText.length>0) {
        
        if (self.currentSearchPersonList==nil) {
            self.currentSearchPersonList = [[Persons sharedInstance] allPersons];
        }
        
        if (newText.length==1) {
            [self _presentSearchUI];
        }
        
        newText = [newText lowercaseString];
        
        NSMutableArray* res = [[NSMutableArray alloc] initWithCapacity:self.currentSearchPersonList.count];
        
        for (Person* p in self.currentSearchPersonList) {
            
            if ([p.name rangeOfString:newText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [res addObject:p];
            }
            else if ([p.email rangeOfString:newText].location != NSNotFound) {
                [res addObject:p];
            }
        }
        
        self.currentSearchPersonList = res;
        
        [self.searchTableView reloadData];
    }
    else {
        [self _removeSearchUI];
    }
    
    return YES;
}

-(void) textFieldDidBeginEditing:(UITextField *)textField
{
    [self _closeBadge];
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _presentSearchUI];
    });
     */
}

-(void) textFieldDidEndEditing:(UITextField *)textField
{
    [self _removeSearchUI];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    //[textField resignFirstResponder];

    NSString* mailText = textField.text;
    
    NSArray* alls = [mailText componentsSeparatedByString:@" "];
    
    BOOL added = NO;
    
    for (NSString* mail in alls) {
        
        NSUInteger loc = [mail rangeOfString:@"@"].location;
        NSUInteger locDot = [mail rangeOfString:@"." options:NSBackwardsSearch].location;
        
        if (loc != NSNotFound && loc > 2 &&  locDot != NSNotFound && loc < locDot) {
            
            NSString* code = [[mail substringToIndex:3] uppercaseString];
            
            Person* p = [Person createWithName:mail email:mail icon:nil codeName:code];
            NSInteger idxPerson = [[Persons sharedInstance] addPerson:p];
            
            if (self.mail.toPersonID.count<1) {
                self.mail.toPersonID = @[@(idxPerson)];
            }
            else {
                NSMutableArray* olds = [self.mail.toPersonID mutableCopy];
                [olds addObject:@(idxPerson)];
                self.mail.toPersonID = olds;
            }
            
            added = YES;
            
        }
    }
    
    if (added) {
        [self _createCCcontent];
    }
    
    textField.text = nil;
    [self _removeSearchUI];
    self.currentSearchPersonList = nil;
    
    return NO;
}


#pragma mark - Interaction

- (void)_openPhotoPicker:(UIImagePickerControllerSourceType)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        [[ViewController mainVC] presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* img = info[UIImagePickerControllerEditedImage];
    if (img==nil) {
        img = info[UIImagePickerControllerOriginalImage];
    }
    
    if (img != nil) {
        Attachment* attach = [[Attachment alloc] init];
        attach.image = img;
        
        attach.name = @"find a name";
        attach.size = @"find the size";
        
        if (self.mail.attachments == nil) {
            self.mail.attachments = @[attach];
        }
        else {
            NSMutableArray* ma = [self.mail.attachments mutableCopy];
            [ma addObject:attach];
            self.mail.attachments = ma;
        }
        [self _updateAttachView];
        
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void) _addAttach
{
    [self _closeCurrentInteractingView];
    
    UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction* action = [UIAlertAction actionWithTitle:NSLocalizedString(@"My pictures", @"My pictures")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* aa) {
                                                       [self _openPhotoPicker:UIImagePickerControllerSourceTypePhotoLibrary];
                                                   }];
    [action setValue:[[UIImage imageNamed:@"pj_photos"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    
    [ac addAction:action];
    
    
    action = [UIAlertAction actionWithTitle:NSLocalizedString(@"New picture", @"New picture")
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction* aa) {
                                        [self _openPhotoPicker:UIImagePickerControllerSourceTypeCamera];
                                    }];
    [action setValue:[[UIImage imageNamed:@"pj_camera"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    
    [ac addAction:action];
    
    
    action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dropbox", @"Dropbox")
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction* aa) {
                                        //
                                        [ViewController presentAlertWIP:@"dropbox link…"];
                                    }];
    [action setValue:[[UIImage imageNamed:@"pj_dropbox"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    
    [ac addAction:action];
    
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel
                                                          handler:nil];
    [ac addAction:defaultAction];
    
    ac.view.tintColor = [UIColor blackColor];
    
    ViewController* vc = [ViewController mainVC];
    [vc presentViewController:ac animated:YES completion:nil];
    
}

-(void) _addPerson
{
    if (self.searchUI != nil) {
        self.toTextField.text = nil;
        [self.toTextField resignFirstResponder];
        return;
    }
}

-(void) _tapTitle:(UITapGestureRecognizer*)tgr
{
    if (tgr.enabled==NO || tgr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    [self _closeCurrentInteractingView];
    
    UINavigationItem* ni = self.navBar.items.firstObject;
    UILabel* lbl = (UILabel*)ni.titleView;
    NSString* currentTitle = lbl.text;
    
    UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([Accounts sharedInstance].accounts.count == 2) {
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Create a new acccount" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction* aa) {
                                                                  // TODO …
                                                              }];
        [ac addAction:defaultAction];
    }
    
    NSInteger idx = -1;
    
    for (Account* a in [Accounts sharedInstance].accounts) {
        idx++;
        
        if (a.isAllAccounts) {
            continue;
        }
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:a.userMail style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction* aa) {
                                                                  
                                                                  // remove from last account if already saved here
                                                                  [self.selectedAccount deleteDraft:self.mail];
                                                                  
                                                                  UINavigationItem* ni = self.navBar.items.firstObject;
                                                                  
                                                                  UILabel* lbl = (UILabel*)ni.titleView;
                                                                  lbl.text = a.userMail;
                                                                  [lbl sizeToFit];
                                                                  self.selectedAccount = a;
                                                                  
                                                                  self.mail.fromPersonID = -(1+idx);
                                                                  
                                                                  for (UIView* v in self.viewsWithAccountTintColor) {
                                                                      v.tintColor = a.userColor;
                                                                  }
                                                                  
                                                                  [self.navBar setNeedsDisplay];
                                                              }];
        if ([a.userMail isEqualToString:currentTitle]) {
            [defaultAction setValue:[UIImage imageNamed:@"swipe_select"] forKey:@"image"];
        }
        else {
            [defaultAction setValue:[UIImage imageNamed:@"empty_pixel"] forKey:@"image"];
        }
        
        [ac addAction:defaultAction];
    }
    

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel
                                                          handler:nil];
    [ac addAction:defaultAction];
    
    ac.view.tintColor = [UIColor blackColor];
    
    ViewController* vc = [ViewController mainVC];
    [vc presentViewController:ac animated:YES completion:nil];
    
}


#pragma mark - Scroll View Delegate

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        [super scrollViewDidScroll:scrollView];
        return;
    }
    
    if ([scrollView isKindOfClass:[UITextView class]]) {
        scrollView.contentOffset = CGPointMake(0, 0);
        return;
    }    
    
}


@end





@interface ExpendableBadge ()

@property (nonatomic, strong) Person* person;
@property (nonatomic, weak) UIView* badge;
@property (nonatomic, weak) UIView* voile;
@property (nonatomic, weak) UIView* backgroundView;

@property (nonatomic) BOOL expanded;
@property (nonatomic) CGRect baseFrame;

@property (nonatomic) NSInteger idxInMailToList;
@property (nonatomic, weak) id<ExpendableBadgeDelegate> delegate;

@end


@implementation ExpendableBadge

-(instancetype) initWithFrame:(CGRect)frame andPerson:(Person*)p
{
    self = [super initWithFrame:frame];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.person = p;
    self.baseFrame = frame;
    
    UIView* back = [[UIView alloc] initWithFrame:self.bounds];
    back.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    back.layer.cornerRadius = self.bounds.size.height / 2.f;
    back.layer.masksToBounds = YES;
    
    [self addSubview:back];
    self.backgroundView = back;
    
    back.alpha = 0;
    back.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel* mail = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 2, 33.f)];
    mail.backgroundColor = [UIColor clearColor];
    mail.textColor = [UIColor whiteColor];
    mail.font = [UIFont systemFontOfSize:14.f];
    [back addSubview:mail];
    mail.textAlignment = NSTextAlignmentLeft;
    mail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    mail.text = [NSString stringWithFormat:@"          %@", p.email];
    
    UIButton* remove = [[UIButton alloc] initWithFrame:CGRectMake(2, 0, 31.f, 33.f)];    
    [remove setImage:[UIImage imageNamed:@"editmail_close_bubble_off"] forState:UIControlStateNormal];
    [remove setImage:[UIImage imageNamed:@"editmail_close_bubble_on"] forState:UIControlStateHighlighted];
    [remove addTarget:self action:@selector(_remove) forControlEvents:UIControlEventTouchUpInside];
    [back addSubview:remove];
    remove.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    UIView* b =[p badgeView];
    [self addSubview:b];
    self.badge = b;
    
    
    back.userInteractionEnabled = YES;
    b.userInteractionEnabled = NO;
    self.userInteractionEnabled = YES;
    
    
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tap:)];
    [self addGestureRecognizer:tgr];
    
    return self;
}

-(void) setupWithIndex:(NSInteger)idx andDelegate:(id<ExpendableBadgeDelegate>)delegate
{
    self.idxInMailToList = idx;
    self.delegate = delegate;
}

-(void) isHiddenContact
{
    UIView* voile = [[UIView alloc] initWithFrame:self.bounds];
    voile.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self.badge addSubview:voile];
    self.voile = voile;
}



-(void)_remove
{
    [self _closeAndThen:^{
        [self.delegate removePersonAtIndex:self.idxInMailToList];
    }];
     
}


-(void) close
{
    if (self.expanded) {
        [self _closeAndThen:nil];
    }
}


-(void) _closeAndThen:(void(^)())action
{
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         
                         self.frame = self.baseFrame;
                         //self.badge.frame = self.bounds;
                         
                         //self.backgroundView.alpha = 0.;
                         
                     }
                     completion:^(BOOL fini){
                         //self.voile.hidden = NO;
                         self.backgroundView.alpha = 0.;
                         self.expanded = NO;
                         if (action != nil) {
                             action();
                         }
                     }];
    
    /*
    [UIView animateWithDuration:0.15 delay:0.
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.badge.alpha = 1.;
                     }
                     completion:nil];
     */
}

-(void)_tap:(UITapGestureRecognizer*)tgr
{
    if (tgr.state != UIGestureRecognizerStateEnded || tgr.enabled==NO) {
        return;
    }
    
    if (self.expanded) {
        [self _closeAndThen:nil];
        return;
    }
    
    // else open
    const CGFloat minX = 8 + 33 + 5;
    
    CGFloat lastPosX = minX;
    const CGFloat stepX = 33 + 5;
    
    UIView* support = self.superview;
    
    while (lastPosX+33+8 < support.frame.size.width) {
        lastPosX += stepX;
    }
    
    [support bringSubviewToFront:self];
    
    //self.voile.hidden = YES;
    
    [self.delegate closeOthersBadge:self];
    
    self.backgroundView.alpha = 1.;
    [UIView animateWithDuration:0.25
                     animations:^{
                         
                         CGRect f = self.frame;
                         f.origin.x = minX;
                         f.size.width = lastPosX - minX;
                         self.frame = f;
                         
                         /*
                         f = self.badge.frame;
                         f.origin.x = self.baseFrame.origin.x - minX;
                         self.badge.frame = f;
                         */
                         //self.backgroundView.alpha = 1.;
                         
                     }
                     completion:^(BOOL fini){
                         self.expanded = YES;
                     }];
    /*
    [UIView animateWithDuration:0.15 delay:0.1
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.badge.alpha = 0.;
                     }
                     completion:nil];
    */
    
}


@end

