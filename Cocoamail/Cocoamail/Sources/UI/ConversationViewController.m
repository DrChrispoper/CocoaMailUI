//
//  ConversationViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 03/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "ConversationViewController.h"

#import "Persons.h"
#import "Accounts.h"


@class SingleMailView;

@protocol SingleMailViewDelegate <NSObject>

-(Mail*) mailDisplayed:(SingleMailView*)mailView;
-(void) mailView:(SingleMailView*)mailView changeHeight:(CGFloat)deltaHeight;
-(void) makeConversationFav:(BOOL)isFav;

@end



@interface ConversationViewController () <UIScrollViewDelegate, SingleMailViewDelegate>

@property (nonatomic, weak) UIView* contentView;
@property (nonatomic, weak) UIScrollView* scrollView;

@property (nonatomic, strong) NSMutableArray* allMailViews;

@end



@interface SingleMailView : UIView

-(void) setupWithText:(NSString*)texte extended:(BOOL)extended;

@property (nonatomic, strong) NSString* textContent;
@property (nonatomic, weak) id<SingleMailViewDelegate> delegate;

@property (nonatomic) CGFloat posXtoUsers;
@property (nonatomic, weak) UIImageView* favori;
@property (nonatomic, weak) UIImageView* markAsRead;

@property (nonatomic) NSInteger idxInConversation;

@property (nonatomic, weak) UIButton* favoriBtn;

-(void) updateFavUI:(BOOL)isFav;

@end





@implementation ConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //
    Persons* p = [Persons sharedInstance];
    if (p.idxMorePerson == 0) {
        Person* more = [Person createWithName:nil email:nil icon:@"recipients_off" codeName:nil];
        p.idxMorePerson = [p addPerson:more];
    }
    // TODO put it elsewhere
    
    
    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    Mail* mail = [self.conversation firstMail];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    item.leftBarButtonItem = [self backButtonInNavBar];

    if ([self.conversation haveAttachment]) {
        UIButton* attach = [WhiteBlurNavBar navBarButtonWithImage:@"attachment_off" andHighlighted:@"attachment_on"];
        [attach addTarget:self action:@selector(_attach) forControlEvents:UIControlEventTouchUpInside];
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:attach];
    }
    
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:mail.title];
    
    [self _setup];
    
    [self setupNavBarWith:item overMainScrollView:self.scrollView];
}


-(void) cleanBeforeGoingBack
{
    self.scrollView.delegate = nil;    
}


-(void) _attach
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_CONVERSATION_ATTACHMENTS_NOTIFICATION object:nil
                                                      userInfo:@{kPRESENT_CONVERSATION_KEY:self.conversation}];
}

-(NSArray*) nextViewControllerInfos
{
    if ([self.conversation haveAttachment]) {
        return @[kPRESENT_CONVERSATION_ATTACHMENTS_NOTIFICATION, self.conversation];
    }
    
    return [super nextViewControllerInfos];
}



-(void) _setup
{
    
    CGFloat posY = 44.f + 5;
    
    
    UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 10000)];
    contentView.backgroundColor = [UIColor clearColor];
  
    // title
    UILabel* lbl = [[UILabel alloc] initWithFrame:self.view.bounds];
    lbl.text = [self.conversation firstMail].title;
    lbl.numberOfLines = 0;
    lbl.textColor = [UIColor whiteColor];
    //lbl.font = [UIFont boldSystemFontOfSize:16];
    //lbl.textAlignment = NSTextAlignmentCenter;
    lbl.font = [UIFont systemFontOfSize:16];
    lbl.textAlignment = NSTextAlignmentNatural;
    
    [lbl sizeToFit];
    
    CGRect tf = lbl.frame;
    tf.size = CGSizeMake(self.view.bounds.size.width-16, tf.size.height+36);
    tf.origin = CGPointMake(8, -tf.size.height + 30);
    lbl.frame = tf;
    
    
    UIView* supportTitle = [[UIView alloc] initWithFrame:tf];
    
    supportTitle.backgroundColor = [UIColor colorWithWhite:180./255. alpha:1.0];
    supportTitle.layer.cornerRadius = 20;
    supportTitle.layer.masksToBounds = YES;
    
    tf.origin = CGPointMake(8, 15);
    tf.size.width -= 16;
    tf.size.height -= 30;
    lbl.frame = tf;
    lbl.backgroundColor = supportTitle.backgroundColor;
    
    [supportTitle addSubview:lbl];
    
    [contentView addSubview:supportTitle];
    //
    
    self.allMailViews = [NSMutableArray arrayWithCapacity:self.conversation.mails.count];
    
    NSInteger idx = 0;
    for (Mail* m in self.conversation.mails) {
    
        NSString* day = m.day;
        NSString* hour = m.hour;
        NSString* mail = m.content;

        posY = [self _addHeaderDay:day hour:hour atYPos:posY inView:contentView];
        posY = [self _addMail:mail withIndex:idx extended:(idx==0) atYPos:posY inView:contentView];
        
        idx++;
    }
    
    CGRect f = contentView.frame;
    f.size.height = posY + 44.f;
    contentView.frame = f;
    
    
    if (contentView.frame.size.height > self.view.bounds.size.height - 40.f) {
        f.size.height += 40.f;
        contentView.frame = f;
    }
    
    
    UIScrollView* sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.contentSize = contentView.frame.size;
    [sv addSubview:contentView];
    sv.backgroundColor = self.view.backgroundColor;
    sv.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    self.contentView = contentView;
    
    [self.view addSubview:sv];
    sv.delegate = self;
    sv.alwaysBounceVertical = YES;
    self.scrollView = sv;
}


-(Mail*) mailDisplayed:(SingleMailView*)mailView;
{
    return self.conversation.mails[mailView.idxInConversation];
}

-(void) makeConversationFav:(BOOL)isFav
{
    Account* ac = [[Accounts sharedInstance] currentAccount];
    [ac manage:self.conversation isFav:isFav];
    
    for (SingleMailView* smv in self.allMailViews) {
        [smv updateFavUI:isFav];
    }
}


-(void) mailView:(SingleMailView*)mailView changeHeight:(CGFloat)deltaHeight
{
    
    CGFloat limite = mailView.frame.origin.y;
    
    for (UIView* v in self.contentView.subviews) {
        
        if (v.frame.origin.y > limite) {
            CGRect f = v.frame;
            f.origin.y += deltaHeight;
            v.frame = f;
        }
    }
    
    UIView* lastView = self.contentView.subviews.lastObject;
    CGFloat maxY = lastView.frame.origin.y + lastView.frame.size.height;
    
    CGRect ctF = self.contentView.frame;
    ctF.size.height = maxY + 44;
    self.contentView.frame = ctF;
    
    if (self.contentView.frame.size.height > self.view.bounds.size.height - 40.f) {
        ctF.size.height += 40.f;
        self.contentView.frame = ctF;
    }
    
    
    self.scrollView.contentSize = self.contentView.frame.size;
    
    
}



-(CGFloat) _addMail:(NSString*)mail withIndex:(NSInteger)idx extended:(BOOL)extended atYPos:(CGFloat)posY inView:(UIView*)v
{
    
    CGFloat WIDTH = self.view.bounds.size.width;
    
    SingleMailView* smv = [[SingleMailView alloc] initWithFrame:CGRectMake(0, posY, WIDTH, 100)];
    smv.idxInConversation = idx;
    smv.delegate = self;
    
    [smv setupWithText:mail extended:extended];
    
    CGFloat height = smv.bounds.size.height;
    [v addSubview:smv];
    
    [self.allMailViews addObject:smv];
    
    return posY + height + 2;
}



-(CGFloat) _addHeaderDay:(NSString*)day hour:(NSString*)hour atYPos:(CGFloat)posY inView:(UIView*)v
{
    CGFloat WIDTH = self.view.bounds.size.width;
    
    UIView* support = [[UIView alloc] initWithFrame:CGRectMake(0, posY, WIDTH, 20.f)];
    support.backgroundColor = [UIColor clearColor];
    [v addSubview:support];
    
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 160, 18)];
    lbl.backgroundColor = self.view.backgroundColor;
    lbl.text = day;
    lbl.textColor = [UIColor colorWithWhite:0.58 alpha:1.0];
    lbl.font = [UIFont systemFontOfSize:13];
    [support addSubview:lbl];
    
    UILabel* lblH = [[UILabel alloc] initWithFrame:CGRectMake(WIDTH - 160 - 10, 0, 160, 18)];
    lblH.backgroundColor = self.view.backgroundColor;
    lblH.text = hour;
    lblH.textColor = [UIColor blackColor];
    lblH.textAlignment = NSTextAlignmentRight;
    lblH.textColor = [UIColor colorWithWhite:0.58 alpha:1.0];
    lblH.font = [UIFont systemFontOfSize:13];
    [support addSubview:lblH];
    
    if (posY>50.f) {
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/2.f - 1.f, -2.f, 2.f, 21.f)];
        line.backgroundColor = [UIColor whiteColor];
        [support addSubview:line];
    }
    
    return posY + 19.f;
}


-(NSArray*) buttonsWideFor:(CocoaButton*)cocoabutton
{
    UIButton* b1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b1 setImage:[UIImage imageNamed:@"edit_off"] forState:UIControlStateNormal];
    [b1 setImage:[UIImage imageNamed:@"edit_on"] forState:UIControlStateHighlighted];
    [b1 addTarget:self action:@selector(_editMail) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton* b2 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b2 setImage:[UIImage imageNamed:@"button_archive_off"] forState:UIControlStateNormal];
    [b2 setImage:[UIImage imageNamed:@"button_archive_on"] forState:UIControlStateHighlighted];

    UIButton* b3 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b3 setImage:[UIImage imageNamed:@"button_folder_off"] forState:UIControlStateNormal];
    [b3 setImage:[UIImage imageNamed:@"button_folder_on"] forState:UIControlStateHighlighted];
    
    UIButton* b4 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
    [b4 setImage:[UIImage imageNamed:@"button_delete_off"] forState:UIControlStateNormal];
    [b4 setImage:[UIImage imageNamed:@"button_delete_on"] forState:UIControlStateHighlighted];
    
    // TODO buttons behaviour
    
    return @[b1, b2, b3, b4];
}

-(void) _editMail
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_EDITMAIL_NOTIFICATION object:nil];
}

-(NSArray*) buttonsHorizontalFor:(CocoaButton*)cocoabutton
{
    return nil;
}

-(BOOL) automaticCloseFor:(CocoaButton *)cocoabutton
{
    return YES;
}

-(BOOL) cocoabuttonLongPress:(CocoaButton *)cocoabutton
{
    return NO;
}


@end






@implementation SingleMailView


-(void) setupWithText:(NSString*)texte extended:(BOOL)extended;
{

    [self.subviews.firstObject removeFromSuperview];
    
    Mail* mail = [self.delegate mailDisplayed:self];
    Person* person = [[Persons sharedInstance] getPersonID:mail.fromPersonID];
    
    self.textContent = texte;
    
    CGFloat WIDTH = self.bounds.size.width;
    
    UIImage* rBack = [[UIImage imageNamed:@"cell_mail_unread"] resizableImageWithCapInsets:UIEdgeInsetsMake(22, 30, 22, 30)];
    UIImageView* inIV = [[UIImageView alloc] initWithImage:rBack];
    
    CGFloat height = (extended) ? 100 : 44;
    
    inIV.frame = CGRectMake(8 , 0 , WIDTH - 16, height);
    
    UILabel* n = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, inIV.bounds.size.width - 88, 45)];
    n.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
    n.font = [UIFont systemFontOfSize:16];
    n.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [inIV addSubview:n];
    
    UIView* perso = [[UIView alloc] initWithFrame:CGRectMake(5.5, 5.5, 33, 33)];
    perso.backgroundColor = [UIColor clearColor];
    perso.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [perso addSubview:[person badgeView]];
    [inIV addSubview:perso];
    
    
    CGFloat xPos = inIV.bounds.size.width - 33.f - 5.5;
    CGFloat step = 33.f + 1.f;
    
    if (extended) {
        
        NSArray* subarray = mail.toPersonID;
        if (mail.toPersonID.count>3) {
            NSRange r;
            r.length = 2;
            r.location = mail.toPersonID.count - 2;
            
            NSMutableArray* tmp = [[mail.toPersonID subarrayWithRange:r] mutableCopy];
            
            [tmp insertObject:@([Persons sharedInstance].idxMorePerson) atIndex:0];
            subarray = tmp;
        }
        
        for (NSNumber* userID in subarray) {
            
            Person* p = [[Persons sharedInstance] getPersonID:[userID integerValue]];
            UIView* perso = [[UIView alloc] initWithFrame:CGRectMake(xPos, 5.5, 33, 33)];
            perso.backgroundColor = [UIColor clearColor];
            perso.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [perso addSubview:[p badgeView]];
            [inIV addSubview:perso];
            
            xPos -= step;
        }
        
        self.favori = nil;
    }
    else {
        
        UIImageView* fav = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_favoris_off"] highlightedImage:[UIImage imageNamed:@"cell_favoris_on"]];
        CGRect f = fav.frame;
        f.origin.x = xPos;
        f.origin.y = 5.5;
        fav.frame = f;
        fav.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [inIV addSubview:fav];
        self.favori = fav;
        fav.highlighted = [mail isFav];
        
        xPos -= step;
    }
    self.posXtoUsers = xPos + 33.f;
    
    
    UIView* sep = [[UIView alloc] initWithFrame:CGRectMake(0, 44, inIV.bounds.size.width, 1)];
    sep.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    sep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [inIV addSubview:sep];
    
    
    
    if (extended) {
        
        UIFont* textFont = [UIFont systemFontOfSize:16];
        
        CGSize size = [texte boundingRectWithSize:CGSizeMake(WIDTH - 30, 5000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:textFont} context:nil].size;
        size.width = ceilf(size.width);
        size.height = ceilf(size.height);
        
        
        const CGFloat topBorder = 14.f;
        
        UILabel* text = [[UILabel alloc] initWithFrame:CGRectMake(8, 48.f + topBorder, size.width, size.height)];
        text.text = texte;
        text.font = textFont;
        text.numberOfLines = 0;
        text.textAlignment = NSTextAlignmentJustified;
        [inIV addSubview:text];
        
        CGRect f = inIV.frame;
        f.size.height = 90 + size.height + topBorder * 2.f;
        inIV.frame = f;
        
        height = f.size.height;
        
        n.text = person.name;

        f = n.frame;
        f.size.width = self.posXtoUsers - f.origin.x;
        n.frame = f;

        UIView* av = [self _createAttachments:mail.attachments];
        if (av != nil) {
            
            CGRect f = inIV.frame;
            f.size.height += av.frame.size.height + 30;
            inIV.frame = f;
            
            f = av.frame;
            f.origin.y = height - 45 + 15;
            av.frame = f;
            
            height = inIV.frame.size.height;
            [inIV addSubview:av];
        }
        
        
    }
    else {
        n.text = [texte stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    inIV.userInteractionEnabled = YES;
    
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_extend:)];
    [inIV addGestureRecognizer:tgr];
    
    inIV.clipsToBounds = YES;
    
    
    CGRect f = self.frame;
    f.size.height = height;
    self.frame = f;

    
    self.favoriBtn = nil;
    if (extended) {
        NSArray* btns = @[@"unread_o", @"forward_o", @"reply_o", @"replyall_o", @"cell_favoris_o"];
        
        
        CGRect baseFrame = CGRectMake(5.5f, height-33.f-5.5f, 33.f, 33.f);
        
        CGFloat stepX = ((inIV.frame.size.width - 33.f - 5.5f) - baseFrame.origin.x ) / 4.f;
        
        NSInteger idxTag = 1;
        
        for (NSString* name in btns) {
            
            UIButton* b = [[UIButton alloc] initWithFrame:baseFrame];
            UIImage* onImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@n", name]];
            
            [b setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@ff", name]] forState:UIControlStateNormal];
            [b setImage:onImg forState:UIControlStateHighlighted];
            [b setImage:onImg forState:UIControlStateSelected];
            [b setImage:onImg forState:UIControlStateSelected | UIControlStateHighlighted];
            [inIV addSubview:b];
            
            baseFrame.origin.x = floorf(baseFrame.origin.x + stepX);
            
            
            if (name == [btns lastObject]) {
                [b addTarget:self action:@selector(_fav:) forControlEvents:UIControlEventTouchUpInside];
                b.selected = mail.isFav;
                self.favoriBtn = b;
            }
            else if (name == [btns firstObject]) {
                [b addTarget:self action:@selector(_masr:) forControlEvents:UIControlEventTouchUpInside];
                b.selected = mail.isRead;
            }
            else {
                b.tag = idxTag++;
                
                [b addTarget:self action:@selector(_openEdit:) forControlEvents:UIControlEventTouchUpInside];
            }
            
        }
    }
    
    [self addSubview:inIV];
}

-(void) updateFavUI:(BOOL)isFav
{
    self.favoriBtn.selected = isFav;
    self.favori.highlighted = isFav;
}


-(UIView*) _createAttachments:(NSArray*)attachs
{
    if (attachs.count==0) {
        return nil;
    }
    
    CGFloat WIDTH = self.bounds.size.width;
    
    const CGFloat stepY = 73.f;
    
    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(8, 0, WIDTH - 32, stepY * attachs.count)];
    v.backgroundColor = [UIColor whiteColor];
    CGFloat posY = 0.f;
    
    NSInteger idx = 0;
    for (Attachment* a in attachs) {
        
        AttachmentView* av = [[AttachmentView alloc] initWithWidth:WIDTH-32 leftMarg:0];
        CGRect f = av.frame;
        f.origin.y = posY;
        av.frame = f;
        
        [av fillWith:a];
        [av buttonActionType:AttachmentViewActionDonwload];
        [v addSubview:av];
        
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, posY, WIDTH - 32, 0.5)];
        line.backgroundColor = [UIGlobal standardLightGrey];
        [v addSubview:line];
        
        idx++;
        posY += stepY;
    }
    
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, posY, WIDTH - 32, 0.5)];
    line.backgroundColor = [UIGlobal standardLightGrey];
    [v addSubview:line];
    
    
    return v;
}


-(void)_openEdit:(UIButton*)button
{
    Mail* m = [self.delegate mailDisplayed:self];
    
    Mail* repm = nil;
    
    if (button.tag==1) {
        repm = [m transfertMail];
    }
    else if (button.tag==2) {
        repm = [m replyMail:NO];
    }
    else {
        repm = [m replyMail:YES];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_EDITMAIL_NOTIFICATION object:nil userInfo:@{kPRESENT_MAIL_KEY:repm}];
}

-(void) _masr:(UIButton*)button
{
    Mail* mail = [self.delegate mailDisplayed:self];
    mail.isRead = !mail.isRead;
    button.selected = mail.isRead;
}

-(void) _fav:(UIButton*)button
{
    Mail* mail = [self.delegate mailDisplayed:self];
    [self.delegate makeConversationFav:!mail.isFav];
}



-(void) _extend:(UITapGestureRecognizer*)tgr
{
    
    if (tgr.enabled==false || tgr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIView* mailView = tgr.view;
    
    CGPoint pos = [tgr locationInView:mailView];
    
    if (pos.y < 45) {
        
        
        if (pos.x < 45) {
            Mail* mail = [self.delegate mailDisplayed:self];
            Person* person = [[Persons sharedInstance] getPersonID:mail.fromPersonID];
            [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_FOLDER_NOTIFICATION object:nil userInfo:@{kPRESENT_FOLDER_PERSON:person}];
            return;
        }
        
        if (pos.x > self.posXtoUsers) {
            
            if (self.bounds.size.height>50) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_CONTACTS_NOTIFICATION object:nil userInfo:@{kPRESENT_MAIL_KEY:[self.delegate mailDisplayed:self]}];
            }
            else {
                Mail* mail = [self.delegate mailDisplayed:self];
                [self.delegate makeConversationFav:!mail.isFav];
            }
            return;
        }
        
        
        CGFloat nextHeight = 44.f;
        
        if (mailView.bounds.size.height>50) {
            [self setupWithText:self.textContent extended:NO];
            nextHeight = 44.f;
        }
        else {
            [self setupWithText:self.textContent extended:YES];
            nextHeight = self.bounds.size.height;
        }
        
        CGFloat diff = nextHeight - mailView.frame.size.height;
        
        CGRect f = mailView.frame;
        f.size.height = nextHeight;
        mailView.frame = f;
        
        
        [self.delegate mailView:self changeHeight:diff];
        
    }
    
}


@end

