//
//  Attachments.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 17/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Attachment : NSObject

@property (nonatomic, strong) NSString* imageName;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* size;
@property (nonatomic, strong) UIImage* image;

-(UIImage*) miniature;

@end


@interface Attachments : NSObject

+(Attachments*) sharedInstance;

-(Attachment*) getAttachmentID:(NSInteger)idx;

-(NSInteger) randomID;


@end
