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



@protocol ExpendableBadgeDelegate

-(void) removePersonAtIndex:(NSInteger)idx;

@end



@interface EditMailViewController () <UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, ExpendableBadgeDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) UIView* contentView;
@property (nonatomic, weak) UIScrollView* scrollView;

@property (nonatomic, weak) WhiteBlurNavBar* navBar;

@property (nonatomic, weak) UITextView* subjectTextView;
@property (nonatomic, weak) UITextView* bodyTextView;
@property (nonatomic, strong) id keyboardNotificationId;

@property (nonatomic) BOOL personsAreHidden;

@property (nonatomic, weak) UIButton* sendButton;
@property (nonatomic, weak) UIButton* attachButton;

@end



@interface ExpendableBadge : UIView

-(instancetype) initWithFrame:(CGRect)frame andPerson:(Person*)p;
-(void) setupWithIndex:(NSInteger)idx andDelegate:(id<ExpendableBadgeDelegate>)delegate;
-(void) isHiddenContact;

@end




@implementation EditMailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.mail == nil) {
        self.mail = [[Mail alloc] init];
    }
    
//    self.view.backgroundColor = [UIGlobal standardLightGrey];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    WhiteBlurNavBar* navBar = [[WhiteBlurNavBar alloc] initWithWidth:screenBounds.size.width];
    
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil/*mail.title*/];
    
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
    
    Account* ca = [allAccounts currentAccount];
    if ([ca.userMail isEqualToString:@"all"]) {
        ca = [allAccounts.accounts firstObject];
    }
    
    back.tintColor = [ca userColor];
    send.tintColor = [ca userColor];
    
    
    UILabel* titleView = [WhiteBlurNavBar titleViewForItemTitle:ca.userMail];
    
    if (allAccounts.accounts.count>1) {
        titleView.userInteractionEnabled = YES;
        UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapTitle:)];
        [titleView addGestureRecognizer:tgr];
    }
    item.titleView = titleView;
    
    [navBar pushNavigationItem:item animated:NO];
    

    [self _setup];
    
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapContent:)];
    [self.view addGestureRecognizer:tgr];
    
    [self _keyboardNotification:YES];
    
    [self.view addSubview:navBar];
    self.navBar = navBar;
    
    [navBar createWhiteMaskOverView:self.scrollView withOffset:0.f];
    
    [self _manageSendButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) cleanBeforeGoingBack
{
    [self _hideKeyboard];
    [self _keyboardNotification:NO];
    
    self.scrollView.delegate = nil;
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
    
    [self _hideKeyboard];
}


#pragma mark - UI

-(void) _send
{
    self.mail.title = self.subjectTextView.text;
    self.mail.content = self.bodyTextView.text;
    // TODO : everything else
    
    [self _back];
}

-(void) _manageSendButton
{
    self.sendButton.enabled = self.subjectTextView.text.length>0 && self.mail.toPersonID.count>0;
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

    Accounts* allAccounts = [Accounts sharedInstance];
    Account* ca = [allAccounts currentAccount];
    
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
    UIImage* plusOff = [[UIImage imageNamed:@"editmail_contact_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage* plusOn = [[UIImage imageNamed:@"editmail_contact_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [addButton setImage:plusOff forState:UIControlStateNormal];
    [addButton setImage:plusOn forState:UIControlStateHighlighted];
    
    addButton.tintColor = [ca userColor];
    [addButton addTarget:self action:@selector(_addPerson) forControlEvents:UIControlEventTouchUpInside];
    addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [toView addSubview:addButton];
    
    
    UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(label.frame.size.width + 10, 1.5, WIDTH - 32 - (label.frame.size.width + 10), 43)];
    tf.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tf.font = [UIFont systemFontOfSize:15.];
    tf.textColor = [UIColor blackColor];
    tf.tag = 1;
    tf.delegate = self;
    tf.keyboardType = UIKeyboardTypeEmailAddress;
    [toView addSubview:tf];
    
    
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
    
    addButton = [[UIButton alloc] initWithFrame:CGRectMake(WIDTH-45, 0, 45, 45)];
    addButton.backgroundColor = [UIColor whiteColor];
    addButton.tintColor = [ca userColor];
    [addButton addTarget:self action:@selector(_addAttach) forControlEvents:UIControlEventTouchUpInside];
    addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [subView addSubview:addButton];
    
    self.attachButton = addButton;
    
    UITextView* tvS = [[UITextView alloc] initWithFrame:CGRectMake(label.frame.size.width + 10, 5.5, WIDTH - 40 - (label.frame.size.width + 10), 34)];
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

    UIView* bdView = [[UIView alloc] initWithFrame:CGRectMake(0, currentPosY, WIDTH, 34 + 8 + 19*3)];
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
        
        
        UITextView* oldtv = [[UITextView alloc] initWithFrame:CGRectMake(8, 4, WIDTH-16, 50)];
        oldtv.textColor = [UIColor blackColor];
        oldtv.backgroundColor = [UIColor clearColor];
        oldtv.font = [UIFont systemFontOfSize:15];
        oldtv.editable = NO;
        oldtv.scrollEnabled = NO;
        [oldView addSubview:oldtv];
        
        Person* from = [[Persons sharedInstance] getPersonID:self.mail.fromMail.fromPersonID];
        NSString* wrote = NSLocalizedString(@"wrote", @"wrote");
        
        NSString* oldcontent = [NSString stringWithFormat:@"%@ %@ :\n\n%@\n", from.name, wrote, self.mail.fromMail.content];
        oldtv.text = oldcontent;
        
        [oldtv sizeToFit];

        CGRect f = oldView.frame;
        f.size.height = oldtv.frame.size.height + 20;
        oldView.frame = f;

        
        UIImage* rBack = [[UIImage imageNamed:@"cell_mail_unread"] resizableImageWithCapInsets:UIEdgeInsetsMake(44, 44, 44, 44)];
        UIImageView* iv = [[UIImageView alloc] initWithImage:[rBack imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        
        CGRect ivf = oldtv.frame;
        ivf.origin.y -= 5;
        iv.frame = ivf;
        iv.tintColor = [UIGlobal standardLightGrey];
        [oldView insertSubview:iv belowSubview:oldtv];
        
        [contentView addSubview:oldView];
        oldView.tag = ContentOld;
    }
    
    [self _createCCcontent];
    
    [self _fillTitle];
    
    [self _fixContentSize];
    
    [self _updateAttachView];
    
    
    // TODO add send by cocoamail ?
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

// TODO this method is in ConversationViewController too (and partially in AttachmentsViewController) : factorize it !!!
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
        
        UILabel* n = [[UILabel alloc] initWithFrame:CGRectMake(65, posY + 17, WIDTH - 65 - 44, 20)];
        n.font = [UIFont systemFontOfSize:16];
        n.textColor = [UIColor blackColor];
        n.backgroundColor = v.backgroundColor;
        [v addSubview:n];
        n.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UILabel* s = [[UILabel alloc] initWithFrame:CGRectMake(65, posY + 38, WIDTH - 65 - 44, 20)];
        s.font = [UIFont systemFontOfSize:12];
        s.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
        s.backgroundColor = v.backgroundColor;
        [v addSubview:s];
        s.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(6, posY + 11, 50, 50)];
        iv.backgroundColor = v.backgroundColor;
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [v addSubview:iv];
        iv.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        
        n.text = a.name;
        s.text = a.size;
        iv.image = [a miniature];
        
        UIButton* del = [[UIButton alloc] initWithFrame:CGRectMake(WIDTH - 51, posY + 10, 53.f, 50.f)];
        del.tag = idx;
        UIImage* img = [[UIImage imageNamed:@"delete_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [del addTarget:self action:@selector(_delAttach:) forControlEvents:UIControlEventTouchUpInside];
        [del setImage:img forState:UIControlStateNormal];
        del.tintColor = [[Accounts sharedInstance] currentAccount].userColor;
        [v addSubview:del];
        
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
    UIColor* currentAccountColor = [[Accounts sharedInstance] currentAccount].userColor;
    
    UIView* ccView = [self.contentView viewWithTag:ContentCC];
    
    CGFloat delta = 0.f;
    
    /*
    NSMutableArray* fakeIDs = [NSMutableArray arrayWithArray:self.mail.toPersonID];
    [fakeIDs addObjectsFromArray:self.mail.toPersonID];
    [fakeIDs addObjectsFromArray:self.mail.toPersonID];
    */
    
//    if (fakeIDs.count > 0) {
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
        //ccButton.backgroundColor = [UIColor whiteColor];
        ccButton.layer.cornerRadius = 16.5;
        ccButton.layer.masksToBounds = YES;
        ccButton.layer.borderColor = currentAccountColor.CGColor;
        ccButton.layer.borderWidth = 1.f;
        [ccButton addTarget:self action:@selector(_ccButton:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage* ccoff = [[UIImage imageNamed:@"editmail_cc"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage* ccon = [[UIImage imageNamed:@"editmail_cci"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [ccButton setImage:ccoff forState:UIControlStateNormal];
        [ccButton setImage:ccon forState:UIControlStateSelected];
        ccButton.tintColor = currentAccountColor;
        [ccView addSubview:ccButton];
        
        ccButton.selected = self.personsAreHidden;
        
        nextPosX += stepX;
        
        NSInteger idx = 0;
        
        for (NSNumber* val in self.mail.toPersonID) {
//        for (NSNumber* val in fakeIDs) {
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
    f.size.height = height;
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
    
    if (textView == self.subjectTextView) {
        [self _manageSendButton];
    }
    
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
    
    [self _manageSendButton];
    
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


#pragma mark - TextField Delegate

-(void) textFieldDidBeginEditing:(UITextField *)textField
{
    //[ViewController presentAlertWIP:@"search UI"];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

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
    Account* ca = [[Accounts sharedInstance] currentAccount];
    
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
    
    ac.view.tintColor = ca.userColor;
    
    ViewController* vc = [ViewController mainVC];
    [vc presentViewController:ac animated:YES completion:nil];
    
}

-(void) _addPerson
{
    [ViewController presentAlertWIP:@"go to list view…"];
}

-(void) _tapTitle:(UITapGestureRecognizer*)tgr
{
    if (tgr.enabled==NO || tgr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    Account* ca = [[Accounts sharedInstance] currentAccount];
    
    
    UINavigationItem* ni = self.navBar.items.firstObject;
    UILabel* lbl = (UILabel*)ni.titleView;
    NSString* currentTitle = lbl.text;
    
    UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (Account* a in [Accounts sharedInstance].accounts) {
    
        if ([a.userMail isEqualToString:@"all"]) {
            continue;
        }
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:a.userMail style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction* aa) {
                                                                  
                                                                  UINavigationItem* ni = self.navBar.items.firstObject;
                                                                  
                                                                  UILabel* lbl = (UILabel*)ni.titleView;
                                                                  lbl.text = a.userMail;
                                                                  [lbl sizeToFit];
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
    
    ac.view.tintColor = ca.userColor;
    
    ViewController* vc = [ViewController mainVC];
    [vc presentViewController:ac animated:YES completion:nil];
    
}


#pragma mark - Scroll View Delegate

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        [self.navBar computeBlur];
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
    mail.textAlignment = NSTextAlignmentCenter;
    mail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    mail.text = p.email;
    
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


-(void) _closeAndThen:(void(^)())action
{
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         
                         self.frame = self.baseFrame;
                         self.badge.frame = self.bounds;
                         
                         self.backgroundView.alpha = 0.;
                         
                     }
                     completion:^(BOOL fini){
                         //self.voile.hidden = NO;
                         self.expanded = NO;
                         if (action != nil) {
                             action();
                         }
                     }];
    
    [UIView animateWithDuration:0.15 delay:0.
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.badge.alpha = 1.;
                     }
                     completion:nil];
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
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         
                         CGRect f = self.frame;
                         f.origin.x = minX;
                         f.size.width = lastPosX - minX;
                         self.frame = f;
                         
                         
                         f = self.badge.frame;
                         f.origin.x = self.baseFrame.origin.x - minX;
                         self.badge.frame = f;
                         
                         self.backgroundView.alpha = 1.;
                         
                     }
                     completion:^(BOOL fini){
                         self.expanded = YES;
                     }];
    
    [UIView animateWithDuration:0.15 delay:0.1
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.badge.alpha = 0.;
                     }
                     completion:nil];
    
    
}


@end

