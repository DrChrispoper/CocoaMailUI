//
//  CreditContentViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 06/09/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "CreditContentViewController.h"

@interface CreditContentViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) UIView* contentView;
@property (nonatomic, weak) UIScrollView* scrollView;

@property (nonatomic, strong) NSString* barTitle;

@property (nonatomic, strong) NSArray* btnActions;

@end



@implementation CreditContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    item.leftBarButtonItem = [self backButtonInNavBar];
    
    [self _setup];

    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:self.barTitle];
    
    [self setupNavBarWith:item overMainScrollView:self.scrollView];
}


-(void) cleanBeforeGoingBack
{
    self.scrollView.delegate = nil;
}

-(BOOL) haveCocoaButton
{
    return NO;
}


-(void) _setup
{
    
    NSString* image;
    NSString* text;
    NSString* name;
    
    NSInteger limite = -1;
    
    if ([self.type isEqualToString:@"RF"]) {
        image = @"cocoamail";
        text = @"";
        name = @"Reinald Freling";
        self.barTitle = @"Product Design";
        self.btnActions = @[@"TWITTER", @"MAIL", @"LINKEDIN", @"FACEBOOK"];
        limite = 400;
    }
    else if ([self.type isEqualToString:@"CH"]) {
        image = @"cocoamail";
        text = @"";
        name = @"Christopher Hockley";
        self.barTitle = @"Development";
        self.btnActions = @[@"TWITTER", @"MAIL", @"LINKEDIN"];
        limite = 650;
    }
    else if ([self.type isEqualToString:@"CB"]) {
        image = @"cocoamail";
        text = @"";
        name = @"Christophe Branche";
        self.barTitle = @"UI/UX Design";
        self.btnActions = @[@"MAIL", @"LINKEDIN"];
        limite = 350;
    }
    else if ([self.type isEqualToString:@"PCC"]) {
        image = @"cocoamail";
        text = @"";
        name = @"Pascal Costa-Cunha";
        self.barTitle = @"Helping hand";
        self.btnActions = @[@"LINKEDIN"];
        limite = 200;
    }
    else if ([self.type isEqualToString:@"T"]) {
        image = nil;
        text = @"";
        name = nil;
        self.barTitle = @"Thanks";
    }
    
    text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus vel tempor ligula, et convallis ante. Integer finibus odio laoreet dignissim vestibulum. Morbi facilisis hendrerit libero vel aliquam. Donec ligula lectus, pharetra sed mi nec, rutrum sodales leo. Etiam volutpat, enim ac aliquet eleifend, lectus nisl ultricies ipsum, sed auctor nisl est non quam. Maecenas vel dolor vel quam tincidunt condimentum. Quisque faucibus nisl eget erat convallis, in aliquet ipsum efficitur. Donec mollis nisi eu luctus semper. Nam aliquam ex ex, vel ornare lacus facilisis nec. Integer dignissim libero eu congue bibendum. Vivamus malesuada quam erat, eu suscipit enim facilisis nec.\n\nQuisque eget quam mauris. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc a urna augue. Sed consequat ut mauris in tincidunt. Duis vel erat mi. Quisque commodo id mauris id blandit. Nulla ut tellus quis metus venenatis rutrum eu ac ex. Interdum et malesuada fames ac ante ipsum primis in faucibus. Mauris laoreet ipsum euismod lacus convallis, sed pharetra nisi ullamcorper.\n\nIn at porttitor magna. Aliquam tincidunt lectus sed nisi finibus malesuada. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Proin scelerisque leo quis dui placerat, quis bibendum lacus semper. Nunc vitae nulla eget sem porta ultricies. Donec vel suscipit nulla. Sed nec metus quis massa venenatis viverra.\n\nIn ac congue libero, quis tristique neque. Cras faucibus quis lectus vitae tristique. Integer congue tempor leo ut semper. Ut lacinia, lacus sit amet condimentum luctus, lorem magna laoreet augue, vitae posuere arcu nibh quis orci. Pellentesque tempor diam metus, ac posuere eros condimentum nec. Donec massa turpis, bibendum non eros non, suscipit ornare leo. Nam rutrum, magna at vehicula tincidunt, dolor ex bibendum risus, eget iaculis lorem neque vel risus. Curabitur placerat, tellus ac rutrum eleifend, ipsum urna sodales massa, vitae consectetur orci nunc quis augue. Duis id orci eget nisl lobortis consectetur eu et dui. Suspendisse at tincidunt ex. Sed fermentum euismod nulla, at mattis metus. Maecenas ac varius nibh, a sodales mauris.\n\nQuisque vitae erat scelerisque ante faucibus feugiat. Curabitur urna neque, bibendum ut venenatis at, tincidunt at nunc. Phasellus sagittis eu tellus nec tempor. Donec sodales sollicitudin rutrum. Donec ac leo a orci pretium volutpat at ac nisi. Sed pellentesque arcu neque, quis vestibulum orci pulvinar eget. Phasellus vehicula felis a efficitur pellentesque. Donec imperdiet nulla accumsan purus mattis consequat. Quisque malesuada est sed justo pharetra hendrerit. Sed pretium feugiat sapien, quis viverra eros feugiat vitae. Cras tincidunt orci quis fringilla pharetra.";
    
    if (limite>0) {
        text = [text substringToIndex:limite];
    }
    
    
    CGFloat posY = 44.f ;
    
    UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 10000)];
    contentView.backgroundColor = [UIColor clearColor];
    
    CGFloat WIDTH = contentView.frame.size.width;
    
    if (image != nil) {
        
        UIView* bigOne = [[UIView alloc] initWithFrame:CGRectMake(0, posY, WIDTH, 160)];
        
        bigOne.backgroundColor = self.view.backgroundColor;
        
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:image]];
        
        CGPoint c = CGPointMake(WIDTH/2, 60);
        iv.center = c;
        [bigOne addSubview:iv];
        
        CGFloat WIDTH_LBL = 240;
        
        UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake((WIDTH - WIDTH_LBL) / 2. , 105, WIDTH_LBL, 50)];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.text = name;
        lbl.numberOfLines = 0;
        [bigOne addSubview:lbl];
        lbl.textAlignment = NSTextAlignmentCenter;
        
        [contentView addSubview:bigOne];
        posY += bigOne.frame.size.height;
    }

    UITextView* tv = [[UITextView alloc] initWithFrame:CGRectMake(0, posY, WIDTH-32, 200)];
    tv.font = [UIFont systemFontOfSize:15];
    tv.scrollEnabled = NO;
    tv.userInteractionEnabled = NO;
    tv.text = text;
    [tv setEditable:NO];
    [tv sizeToFit];
    
    UIView* supportTV = [[UIView alloc] initWithFrame:CGRectInset(tv.frame, -16, -25)];
    supportTV.backgroundColor = [UIColor whiteColor];
    [supportTV addSubview:tv];

    CGRect f = supportTV.frame;
    f.origin.x = 0;
    f.origin.y = posY;
    f.size.width = WIDTH;
    supportTV.frame = f;
    
    f = tv.frame;
    f.size.width = WIDTH - 32;
    f.origin.x = 16;
    f.origin.y = 25;
    tv.frame = f;
    
    posY += supportTV.frame.size.height;
    [contentView addSubview:supportTV];
    
    if (self.btnActions.count>0) {
        
        CGFloat height = MAX(60, self.view.frame.size.height - 20 - posY);
        
        UIView* iconView = [[UIView alloc] initWithFrame:CGRectMake(0, posY, WIDTH, height)];
        iconView.backgroundColor = [UIColor whiteColor];
        
        NSMutableArray* btns = [NSMutableArray arrayWithCapacity:self.btnActions.count];
        
        for (NSString* action in self.btnActions) {

            NSString* imgNameOff = nil;
            NSString* imgNameOn = nil;
            
            if ([action isEqualToString:@"TWITTER"]) {
                imgNameOff = @"credits_twitter_off";
                imgNameOn = @"credits_twitter_on";
            }
            else if ([action isEqualToString:@"LINKEDIN"]) {
                imgNameOff = @"credits_linkedin_off";
                imgNameOn = @"credits_linkedin_on";
            }
            else if ([action isEqualToString:@"MAIL"]) {
                imgNameOff = @"edit_off";
                imgNameOn = @"edit_on";
            }
            else if ([action isEqualToString:@"FACEBOOK"]) {
                imgNameOff = @"credits_facebook_off";
                imgNameOn = @"credits_facebook_on";
            }
            
            UIButton* b = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
            [b setImage:[[UIImage imageNamed:imgNameOff] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [b setImage:[[UIImage imageNamed:imgNameOn]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
            [b addTarget:self action:@selector(_tapButton:) forControlEvents:UIControlEventTouchUpInside];
            
            b.tintColor = [UIGlobal noImageBadgeColor];
            b.tag = btns.count;
            [btns addObject:b];
        }
        
        CGFloat stepX = WIDTH / (btns.count + 1);
        CGFloat posX = 0;
        for (UIButton* b in btns) {
            posX += stepX;
            b.center = CGPointMake(posX, height - 40);
            [iconView addSubview:b];
            
            CGRect bf = b.frame;
            bf.origin.x = floorf(bf.origin.x);
            b.frame = bf;
        }
        
        [contentView addSubview:iconView];
        posY += iconView.frame.size.height;
        
    }
    
    CGRect fcv = contentView.frame;
    fcv.size.height = posY + 20.f;
    contentView.frame = fcv;
    
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

-(void) _tapButton:(UIButton*)button
{
    [ViewController presentAlertWIP:@"manage actions here…"];
}


@end
