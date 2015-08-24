//
//  Mail.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 16/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Attachments.h"


@interface Mail : NSObject

@property (nonatomic) NSInteger fromPersonID;
@property (nonatomic, strong) NSArray* toPersonID;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* content;

@property (nonatomic, strong) NSDate* date;

@property (nonatomic, strong) NSString* day;
@property (nonatomic, strong) NSString* hour;

@property (nonatomic, strong) NSString* mailID;

@property (nonatomic, strong) NSArray* attachments;

@property (nonatomic) BOOL isFav;

@property (nonatomic) BOOL isRead;

@property (nonatomic, strong) Mail* fromMail;

+(NSArray*) mailsWithInfos:(NSDictionary*)infos when:(NSDate*)date;

-(BOOL) haveAttachment;

-(Mail*) replyMail:(BOOL)replyAll;
-(Mail*) transfertMail;

@end




@interface Conversation : NSObject

@property (nonatomic, strong) NSArray* mails;

-(Mail*) firstMail;

-(BOOL) haveAttachment;

@end

