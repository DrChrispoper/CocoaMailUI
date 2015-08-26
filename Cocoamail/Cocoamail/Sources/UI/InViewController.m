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
    [navBar pushNavigationItem:item animated:NO];
    [self.view addSubview:navBar];
    self.navBar = navBar;
    
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

