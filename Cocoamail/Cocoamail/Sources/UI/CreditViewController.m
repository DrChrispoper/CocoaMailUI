//
//  CreditViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 06/09/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "CreditViewController.h"

@interface CreditViewController ()

@end

@implementation CreditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    item.leftBarButtonItem = [self backButtonInNavBar];
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle: NSLocalizedString(@"CocoaMail 1.0", @"CocoaMail 1.0")];
    
    [self setupSimpleNavBarWith:item andWidth:screenBounds.size.width];
        
}



-(BOOL) haveCocoaButton
{
    return NO;
}

@end
