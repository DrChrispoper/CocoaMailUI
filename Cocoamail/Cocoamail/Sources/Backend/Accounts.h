//
//  Accounts.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 11/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Persons.h"

@class Account;

@interface Accounts : NSObject

+(Accounts*) sharedInstance;

+(NSArray*) systemFolderNames;
+(NSArray*) systemFolderIcons;
+(NSString*) userFolderIcon;

@property (nonatomic) NSInteger quickSwipeType;
@property (nonatomic) BOOL navBarBlurred;


@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic) NSInteger currentAccountIdx;

-(Account*) currentAccount;

@end

@interface Account : NSObject

@property (nonatomic, strong) NSString* codeName;
@property (nonatomic, strong) NSString* userMail;
@property (nonatomic, strong) UIColor* userColor;

@property (nonatomic, strong) NSArray* userFolders;
@property (nonatomic, strong) NSArray* systemFolders;

@property (nonatomic, strong) Person* person;

@property (nonatomic) BOOL isAllAccounts;

@end
