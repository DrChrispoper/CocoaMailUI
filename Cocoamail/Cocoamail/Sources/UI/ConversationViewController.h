//
//  ConversationViewController.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 03/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Mail.h"
#import "CocoaButton.h"

@interface ConversationViewController : UIViewController <CocoaButtonDatasource>

@property (nonatomic, strong) Conversation* conversation;

@end
