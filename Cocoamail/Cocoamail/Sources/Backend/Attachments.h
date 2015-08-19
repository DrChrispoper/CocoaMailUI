//
//  Attachments.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 17/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Attachment : NSObject

@property (nonatomic, strong) NSString* imageName;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* size;

@end


@interface Attachments : NSObject

+(Attachments*) sharedInstance;

-(Attachment*) getAttachmentID:(NSInteger)idx;

-(NSInteger) randomID;


@end
