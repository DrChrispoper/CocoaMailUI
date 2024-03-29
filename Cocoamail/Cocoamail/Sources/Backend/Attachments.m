//
//  Attachments.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 17/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Attachments.h"

#import "Accounts.h"
#import "ViewController.h"


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

-(UIImage*) miniature
{
    if (self.image != nil) {
        return self.image;
    }
    
    return [UIImage imageNamed:self.imageName];
}


@end




@interface AttachmentView ()

@property (nonatomic, weak) UILabel* name;
@property (nonatomic, weak) UILabel* size;
@property (nonatomic, weak) UIImageView* mini;
@property (nonatomic, weak) UIButton* btn;

@property (nonatomic) NSInteger internalState;
@property (nonatomic, weak) UIImageView* circleView;

@property (nonatomic) BOOL fakeIgnoreNextEnd;


@end


@implementation AttachmentView


-(instancetype) initWithWidth:(CGFloat)width leftMarg:(CGFloat)margin;
{
    CGRect frame = CGRectMake(0, 0, width, 72);
    
    self = [super initWithFrame:frame];
    
    self.backgroundColor = [UIColor whiteColor];
    
    
    const CGFloat posX = 64 + margin;
    
    UILabel* n = [[UILabel alloc] initWithFrame:CGRectMake(posX, 17, width - posX - 44, 20)];
    n.font = [UIFont systemFontOfSize:16];
    n.textColor = [UIColor blackColor];
    n.backgroundColor = self.backgroundColor;
    [self addSubview:n];
    n.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.name = n;
    
    UILabel* s = [[UILabel alloc] initWithFrame:CGRectMake(posX, 38, width - posX - 44, 20)];
    s.font = [UIFont systemFontOfSize:12];
    s.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
    s.backgroundColor = self.backgroundColor;
    [self addSubview:s];
    s.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.size = s;
    
    UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(posX-60, 11, 50, 50)];
    iv.backgroundColor = self.backgroundColor;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:iv];
    iv.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    self.mini = iv;
    
    UIButton* d = [[UIButton alloc] initWithFrame:CGRectMake(width-33.f-10.f, 20.f, 33.f, 33.f)];
    d.backgroundColor = self.backgroundColor;
    [self addSubview:d];
    d.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.btn = d;
    
    return self;
    
}

-(void) buttonActionType:(AttachmentViewAction)type
{
    switch (type) {
        case AttachmentViewActionNone:
            self.btn.hidden = YES;
            self.internalState = -1;
            break;
            
        case AttachmentViewActionDonwload:
        {
            [self.btn setImage:[UIImage imageNamed:@"download_off"] forState:UIControlStateNormal];
            [self.btn setImage:[UIImage imageNamed:@"download_on_stop"] forState:UIControlStateHighlighted];
            [self.btn addTarget:self action:@selector(_applyButtonDownload:) forControlEvents:UIControlEventTouchUpInside];
            self.internalState = 0;
            break;
        }
        case AttachmentViewActionGlobalTap:
        {
            self.btn.hidden = YES;
            [self.btn removeFromSuperview];
            
            UIButton* tapAttach = [[UIButton alloc] initWithFrame:CGRectMake(0, 1.f, self.frame.size.width - 32, 71.f)];
            tapAttach.layer.cornerRadius = 8.f;
            tapAttach.backgroundColor = [UIColor clearColor];
            tapAttach.layer.masksToBounds = YES;
            
            [tapAttach addTarget:self action:@selector(_touchButton:) forControlEvents:UIControlEventTouchDown];
            [tapAttach addTarget:self action:@selector(_touchButton:) forControlEvents:UIControlEventTouchDragEnter];
            [tapAttach addTarget:self action:@selector(_cancelTouchButton:) forControlEvents:UIControlEventTouchDragExit];
            [tapAttach addTarget:self action:@selector(_cancelTouchButton:) forControlEvents:UIControlEventTouchCancel];
            [tapAttach addTarget:self action:@selector(_applyButton:) forControlEvents:UIControlEventTouchUpInside];
            
            [self addSubview:tapAttach];
            
            self.btn = tapAttach;
            
            self.internalState = -1;
            break;
        }
        case AttachmentViewActionDelete:
        {
            UIImage* img = [[UIImage imageNamed:@"delete_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.btn setImage:img forState:UIControlStateNormal];
            [self.btn setImage:nil forState:UIControlStateHighlighted];
            self.btn.tintColor = [[Accounts sharedInstance] currentAccount].userColor;
            self.internalState = -1;
            
            break;
        }
        default:
            self.internalState = -1;
            self.btn.hidden = NO;
            break;
    }
}

-(void) addActionTarget:(id)target selector:(SEL)selector andTag:(NSInteger)tag
{
    self.btn.tag = tag;
    [self.btn addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

-(void) fillWith:(Attachment*)at
{
    self.name.text = at.name;
    self.size.text = at.size;
    self.mini.image = [at miniature];
}


-(void)_timerCercle:(NSTimer*)t
{
    if (self.internalState!=1) {
        [t invalidate];
    }
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.circleView.transform = CGAffineTransformRotate(self.circleView.transform, M_PI);
                     }
                     completion:nil];
    
}

-(void) beginActionDownload
{
    if (self.internalState == 0) {
        [self _applyButtonDownload:self.btn];
    }
}



-(void)_applyButtonDownload:(UIButton*)b
{
    if (self.internalState == 0) {
    
        self.internalState = 1;
    
        [self.btn setImage:[UIImage imageNamed:@"download_on_stop"] forState:UIControlStateNormal];
        
        
        UIImageView* cercle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download_on_circle"]];
        cercle.backgroundColor = [UIColor clearColor];
        [b addSubview:cercle];
        self.circleView = cercle;
        
        NSTimer* t = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_timerCercle:) userInfo:nil repeats:YES];
        [self _timerCercle:t];
        
        // fake async
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (self.fakeIgnoreNextEnd) {
                self.fakeIgnoreNextEnd = NO;
                return;
            }
            
            if (self.internalState==1) {
                [self.circleView removeFromSuperview];
                self.circleView = nil;
                
                [self.btn setImage:[UIImage imageNamed:@"download_export_off"] forState:UIControlStateNormal];
                [self.btn setImage:[UIImage imageNamed:@"download_export_on"] forState:UIControlStateHighlighted];
                self.internalState = 2;
            }
            
        });
        //
        
    }
    else if (self.internalState==1) {
        self.internalState = 0;
        self.fakeIgnoreNextEnd = YES;
        
        [self.circleView removeFromSuperview];
        self.circleView = nil;
        
        [self.btn setImage:[UIImage imageNamed:@"download_off"] forState:UIControlStateNormal];
        [self.btn setImage:[UIImage imageNamed:@"download_on_stop"] forState:UIControlStateHighlighted];
        
    }
    else {
        // internalState == 2
        
        [ViewController presentAlertWIP:@"open attachment…"];
        
    }
}

-(void)_touchButton:(UIButton*)button
{
    button.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.25];
}

-(void)_cancelTouchButton:(UIButton*)button
{
    button.backgroundColor = [UIColor clearColor];
}

-(void)_applyButton:(UIButton*)button
{
    [self _cancelTouchButton:button];
}



@end


