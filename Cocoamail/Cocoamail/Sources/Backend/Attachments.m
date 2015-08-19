//
//  Attachments.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 17/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Attachments.h"


@interface Attachments ()

@property (nonatomic, strong) NSArray* alls;

@end


@implementation Attachments

+(Attachments*) sharedInstance
{
    static dispatch_once_t once;
    static Attachments* sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


-(instancetype) init
{
    self = [super init];
    
    
    NSArray* names = @[@"Plein d'animaux.jpg", @"livre.jpg", @"renard & cicogne.jpg",
                       @"CD.jpg", @"portrait.pjg", @"image.jpg",
                       @"ane N&B.jpg", @"couverture.jpg", @"Grenouilles.jpg",
                       @"GustaveDoré.jpg", @"livreEnfant.jpg", @"Le lièvre et la tortue.jpg"];
    
    NSArray* size = @[@"368 Ko", @"1.12 Mo", @"615 Ko",
                      @"843 Ko", @"348 Ko", @"94 Ko",
                      @"208 Ko", @"167 Ko", @"648 Ko",
                      @"503 Ko", @"1.38 Mo", @"942 Ko"];
    
    NSMutableArray* tmp = [[NSMutableArray alloc] initWithCapacity:names.count];
    
    NSInteger idx = 0;
    for (NSString* name in names) {
        
        Attachment* at = [[Attachment alloc] init];
        at.name = name;
        at.size = size[idx];
        at.imageName = [NSString stringWithFormat:@"img%ld", (long)(idx+1)];
        
        [tmp addObject:at];
        idx++;
    }
    
    
    names = @[@"fable1.mp3", @"fable2.mp3", @"fable2.mp3", @"fable4.mp3",
              @"fable1.m4v", @"fable2.avi", @"fable3.mp4", @"fable4.mov",
              @"fable1.doc", @"fables.zip", @"fable2.doc", @"fable.ppt"];
    
    size = @[@"368 Ko", @"1.12 Mo", @"615 Ko", @"843 Ko",
             @"1.68 Mo", @"3.74 Mo", @"2.8 Mo", @"3.12 Mo",
             @"648 Ko", @"503 Ko", @"742 Ko", @"942 Ko"];
    
    idx = 0;
    for (NSString* name in names) {
        
        Attachment* at = [[Attachment alloc] init];
        at.name = name;
        at.size = size[idx];
        
        if (idx<4) {
            at.imageName = @"pj_audio";
        }
        else if (idx<8) {
            at.imageName = @"pj_video";
        }
        else {
            at.imageName = @"pj_other";
        }
        
        [tmp addObject:at];
        idx++;
    }
    
    
    self.alls = tmp;
    
    return self;
}


-(NSInteger) randomID
{
    NSInteger max = self.alls.count;
    return rand() % max;
}


-(Attachment*) getAttachmentID:(NSInteger)idx;
{
    return self.alls[idx];
}



@end





@implementation Attachment


@end