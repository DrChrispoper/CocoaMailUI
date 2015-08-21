//
//  CocoaButton.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 11/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CocoaButton;

@protocol CocoaButtonDatasource

-(NSArray*) buttonsWideFor:(CocoaButton*)cocoabutton;
-(NSArray*) buttonsHorizontalFor:(CocoaButton*)cocoabutton;

@end


@interface CocoaButton : UIView

+(instancetype) sharedButton;

@property (nonatomic, weak) id<CocoaButtonDatasource> datasource;

-(void) forceCloseButton;
-(void) updateColor;
-(void) openHorizontal;

-(void) forceCloseHorizontal;
-(void) forceOpenHorizontal;

-(void) replaceMainButton:(UIButton*)button;


-(void) closeHorizontalButton:(UIButton*)button refreshCocoaButtonAndDo:(void (^)())action;

@end
