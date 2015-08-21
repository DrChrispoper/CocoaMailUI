//
//  EditMailViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 21/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "EditMailViewController.h"

#import "Accounts.h"

@interface EditMailViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) UIView* contentView;
@property (nonatomic, weak) UIScrollView* scrollView;

@property (nonatomic, weak) WhiteBlurNavBar* navBar;

@end



@implementation EditMailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    WhiteBlurNavBar* navBar = [[WhiteBlurNavBar alloc] initWithWidth:screenBounds.size.width];
    
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil/*mail.title*/];
    
    UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"back_off" andHighlighted:@"back_on"];
    [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    
    Accounts* allAccounts = [Accounts sharedInstance];
    
    Account* ca = [allAccounts currentAccount];
    if ([ca.userMail isEqualToString:@"all"]) {
        ca = [allAccounts.accounts firstObject];
    }
    
    UILabel* titleView = [WhiteBlurNavBar titleViewForItemTitle:ca.userMail];
    
    if (allAccounts.accounts.count>1) {
        titleView.userInteractionEnabled = YES;
        UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapTitle:)];
        [titleView addGestureRecognizer:tgr];
    }
    item.titleView = titleView;
    
    [navBar pushNavigationItem:item animated:NO];
    
    
    UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 5000)];
    contentView.backgroundColor = [UIColor clearColor];
    
    
    UIScrollView* sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.contentSize = contentView.frame.size;
    [sv addSubview:contentView];
    sv.backgroundColor = self.view.backgroundColor;
    self.contentView = contentView;
    
    [self.view addSubview:sv];
    sv.delegate = self;
    self.scrollView = sv;
    
    [self.view addSubview:navBar];
    self.navBar = navBar;
    
    [navBar createWhiteMaskOverView:self.scrollView withOffset:0.f];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) cleanBeforeGoingBack
{
    self.scrollView.delegate = nil;
}


-(void) _tapTitle:(UITapGestureRecognizer*)tgr
{
    if (tgr.enabled==NO || tgr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    
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
        [ac addAction:defaultAction];
    }

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel
                                                          handler:nil];
    [ac addAction:defaultAction];
    
    
    ViewController* vc = [ViewController mainVC];
    [vc presentViewController:ac animated:YES completion:nil];
    
}


-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navBar computeBlur];
}


@end
