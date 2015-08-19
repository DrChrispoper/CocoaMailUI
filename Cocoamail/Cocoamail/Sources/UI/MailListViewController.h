//
//  MailListViewController.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 16/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CocoaButton.h"
#import "Persons.h"

@interface MailListViewController : UIViewController <CocoaButtonDatasource>

-(instancetype) initWithName:(NSString*)name;
-(instancetype) initWithPerson:(Person*)person;

@end
