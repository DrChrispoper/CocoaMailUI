//
//  InViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 26/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "InViewController.h"

@interface InViewController ()

@property (nonatomic, weak) UIScrollView* mainScrollView;

@property (nonatomic, strong) PullToRefresh* pullToRefresh;


@end



@implementation InViewController

-(void) setupNavBarWith:(UINavigationItem*)item overMainScrollView:(UIScrollView*)mainScrollView
{
    self.mainScrollView = mainScrollView;
    
    WhiteBlurNavBar* navBar = [[WhiteBlurNavBar alloc] initWithWidth:mainScrollView.frame.size.width];
    
    if (item.rightBarButtonItem==nil) {
        UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"empty_pixel" andHighlighted:@"empty_pixel"];
        [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    }

    if (item.leftBarButtonItem==nil) {
        UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"empty_pixel" andHighlighted:@"empty_pixel"];
        [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
        item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    }
    
    
    [navBar pushNavigationItem:item animated:NO];
    
    UIView* navBarSupport = [[UIView alloc] initWithFrame:navBar.bounds];
    navBarSupport.backgroundColor = [UIColor clearColor];
    navBarSupport.clipsToBounds = YES;
    [navBarSupport addSubview:navBar];
    
    [self.view addSubview:navBarSupport];
    self.navBar = navBar;
 
    self.navBar.frame = CGRectInset(self.navBar.frame, -3, 0);
    
    [navBar createWhiteMaskOverView:mainScrollView withOffset:mainScrollView.contentInset.top];
}

-(void) addPullToRefreshWithDelta:(CGFloat)delta
{
    self.pullToRefresh = [[PullToRefresh alloc] init];
    self.pullToRefresh.delta = delta;
}

#pragma  mark - Actions

-(void) cleanBeforeGoingBack
{
    // clean delegates
}

-(BOOL) haveCocoaButton
{
    return YES;
}

-(void) _back
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kBACK_NOTIFICATION object:nil];
}

#pragma mark - Defaut Delegate

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navBar computeBlur];
    [self.pullToRefresh scrollViewDidScroll:scrollView];
    
    if (!scrollView.isDecelerating) {
        [[ViewController mainVC] closeCocoaButtonIfNeeded];
    }
    
}

-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pullToRefresh scrollViewDidEndDragging:scrollView];
}




@end

