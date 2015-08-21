//
//  ViewController.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 14/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "UIGlobal.h"
#import "WhiteBlurNavBar.h"


#define kPRESENT_FOLDER_NOTIFICATION @"kPRESENT_FOLDER_NOTIFICATION"
#define kPRESENT_FOLDER_NAME @"kPRESENT_FOLDER_NAME"
#define kPRESENT_FOLDER_PERSON @"kPRESENT_FOLDER_PERSON"

#define kPRESENT_CONVERSATION_NOTIFICATION @"kPRESENT_CONVERSATION_NOTIFICATION"
#define kPRESENT_CONVERSATION_KEY @"kCONV_KEY"

#define kACCOUNT_CHANGED_NOTIFICATION @"kACCOUNT_CHANGED_NOTIFICATION"

#define kPRESENT_CONTACTS_NOTIFICATION @"kPRESENT_CONTACTS_NOTIFICATION"
#define kPRESENT_MAIL_KEY @"kPRESENT_MAIL_KEY"

#define kPRESENT_CONVERSATION_ATTACHMENTS_NOTIFICATION @"kPRESENT_CONVERSATION_ATTACHMENTS_NOTIFICATION"
//#define kPRESENT_CONVERSATION_KEY @"kCONV_KEY"

#define kPRESENT_EDITMAIL_NOTIFICATION @"kPRESENT_EDITMAIL_NOTIFICATION"
//#define kPRESENT_MAIL_KEY @"kPRESENT_MAIL_KEY"

#define kPRESENT_SETTINGS_NOTIFICATION @"kPRESENT_SETTINGS_NOTIFICATION"

#define kBACK_NOTIFICATION @"kBACK_NOTIFICATION"



@interface InViewController : UIViewController

-(void) _back;
-(void) cleanBeforeGoingBack;

@end


@interface ViewController : UIViewController

+(ViewController*) mainVC;

-(void) refreshCocoaButton;

+(void) presentAlertWIP:(NSString*)message;

@end



