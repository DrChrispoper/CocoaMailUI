//
//  Mail.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 16/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Mail.h"

#import "Persons.h"
#import "Accounts.h"

@implementation Mail

static NSInteger s_nextMailID = 1;

static NSDateFormatter* s_df_day = nil;
static NSDateFormatter* s_df_hour = nil;


+(void) initialize
{
    s_df_day = [[NSDateFormatter alloc] init];
    s_df_day.dateStyle = NSDateFormatterMediumStyle;
    s_df_day.timeStyle = NSDateFormatterNoStyle;
    
    s_df_hour = [[NSDateFormatter alloc] init];
    s_df_hour.dateStyle = NSDateFormatterNoStyle;
    s_df_hour.timeStyle = NSDateFormatterShortStyle;
    
    // to init attahcments
    [Attachments sharedInstance];
}


+(NSArray*) mailsWithInfos:(NSDictionary*)infos when:(NSDate*)date
{

    Mail* mail = [[Mail alloc] init];
    
    mail.fromPersonID = [[Persons sharedInstance] randomID];
    mail.date = date;
    mail.title = infos[@"title"];
    
    NSString* content = infos[@"content"];
    
    NSMutableArray* tmp = [NSMutableArray arrayWithCapacity:5];
    
    while (rand()%3 != 0) {
        NSInteger idx = [[Persons sharedInstance] randomID];
        if (idx != mail.fromPersonID && ![tmp containsObject:@(idx)]) {
            [tmp addObject:@(idx)];
        }
    }
    
    NSInteger idx = -(1+[Accounts sharedInstance].currentAccountIdx);
    
    [tmp addObject:@(idx)];
    
    mail.toPersonID = tmp;
    
    mail.day = [s_df_day stringFromDate:date];
    mail.hour = [s_df_hour stringFromDate:date];
    
    // fake but stable
    mail.mailID = [NSString stringWithFormat:@"%ld", (long)s_nextMailID++];
//    mail.haveAttachment = (rand() % 4 == 0);
    [self _addAttachmentsTo:mail];
    [self _setIsRead:mail];
    //
    
    if (content.length >= 800) {
        
        NSMutableArray* res = [[NSMutableArray alloc] initWithCapacity:content.length/800];
        
        [res addObject:mail];
        
        NSDate* currentDate = date;
        NSString* contentStr = content;
        NSInteger nextIndex = 800;
        
        while (contentStr.length>nextIndex) {
            
            NSString* next = [contentStr substringFromIndex:nextIndex];
            NSString* current = [contentStr substringToIndex:nextIndex];
            
            if (mail.content==nil) {
                mail.content = current;
            }
            else {
                
                Mail* mailIn = [self _subMailForm:mail withDate:currentDate andContent:current];
                [res addObject:mailIn];
            }

            contentStr = next;
            currentDate = [currentDate dateByAddingTimeInterval:-60*61*10+3];
            
        }

        Mail* mailIn = [self _subMailForm:mail withDate:currentDate andContent:contentStr];
        [res addObject:mailIn];
        
        return res;
    }
    else {
        mail.content = content;
        
        return @[mail];
    }
    
}


+(void) _setIsRead:(Mail*)mail
{
    if ([mail.date timeIntervalSinceNow] > -60*60*50) {
        mail.isRead = NO;
    }
    else {
        mail.isRead = (rand()%4 != 0);
    }
    
    
}

+(Mail*) _subMailForm:(Mail*)mail withDate:(NSDate*)date andContent:(NSString*)content
{
    Mail* mailIn = [[Mail alloc] init];
    
    NSInteger rnd = rand() % mail.toPersonID.count;
    
    mailIn.fromPersonID = [mail.toPersonID[rnd] integerValue];
    NSMutableArray* other = [mail.toPersonID mutableCopy];
    [other replaceObjectAtIndex:rnd withObject:@(mail.fromPersonID)];
    mailIn.toPersonID = other;
    
    mailIn.date = date;
    mailIn.title = mail.title;
    
    mailIn.day = [s_df_day stringFromDate:date];
    mailIn.hour = [s_df_hour stringFromDate:date];
    
    mailIn.content = content;
    
    // fake but stable
    mailIn.mailID = [NSString stringWithFormat:@"%ld", (long)s_nextMailID++];
    //mailIn.haveAttachment = (rand() % 4 == 0);
    [self _addAttachmentsTo:mailIn];
    [self _setIsRead:mailIn];
    //
    
    return mailIn;
}

+(void) _addAttachmentsTo:(Mail*)mail
{
    
    NSMutableArray* tmp = [NSMutableArray arrayWithCapacity:10];
    
    Attachments* ag = [Attachments sharedInstance];
    
    while (rand()%2==0) {
        Attachment* at = [ag getAttachmentID:[ag randomID]];
        [tmp addObject:at];
    }
    
    
    if (tmp.count>0) {
        mail.attachments = tmp;
    }
    else {
        mail.attachments = nil;
    }
    
}


-(BOOL) haveAttachment
{
    return self.attachments.count>0;
}


-(Mail*) replyMail:(BOOL)replyAll
{
    Mail* mail = [[Mail alloc] init];
    
    mail.title = self.title;
    mail.fromPersonID = -(1+[Accounts sharedInstance].currentAccountIdx);
  
    if (replyAll) {
        
        NSMutableArray* currents = [self.toPersonID mutableCopy];
        
        [currents addObject:@(self.fromPersonID)];
        [currents removeObject:@(mail.fromPersonID)];
        
        mail.toPersonID = currents;
        
    }
    else {
        mail.toPersonID = @[@(self.fromPersonID)];
    }
  
    mail.content = @"";
    mail.date = [NSDate date];
    mail.day = [s_df_day stringFromDate:mail.date];
    mail.hour = [s_df_hour stringFromDate:mail.date];
    mail.attachments = nil;
    mail.isFav = false;
    mail.isRead = false;
    
    mail.fromMail = self;
    
    // fake but stable
    mail.mailID = [NSString stringWithFormat:@"%ld", (long)s_nextMailID++];
    //
    
    return mail;
}


-(Mail*) transfertMail
{
    Mail* mail = [self replyMail:NO];
    mail.toPersonID = nil;
    mail.attachments = self.attachments;
    
    return mail;
}

@end


@implementation Conversation

-(Mail*) firstMail
{
    return [self.mails firstObject];
}

-(BOOL) haveAttachment
{
    for (Mail* m in self.mails) {
        if ([m haveAttachment]) {
            return true;
        }
    }
    
    return false;
}



@end

