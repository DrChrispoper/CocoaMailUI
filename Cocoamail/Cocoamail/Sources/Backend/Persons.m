//
//  Persons.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 13/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Persons.h"

#import "UIGlobal.h"
#import "Accounts.h"


@interface Persons ()

@property (nonatomic, strong) NSArray* alls;
@property (nonatomic, strong) NSMutableArray* allsNeg;

@end


@interface Person ()

@property (nonatomic, strong) NSString* codeName;
@property (nonatomic, strong) NSString* imageName;
@property (nonatomic) BOOL isTheUser;

@end




@implementation Persons

+(Persons*) sharedInstance
{
    static dispatch_once_t once;
    static Persons* sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


-(instancetype) init
{
    self = [super init];
    
    NSArray* images = @[@"adam-sandler", @"ben-stiller", @"bill-murray",
                        @"doc-helmetbrown", @"jonah-hill", @"marty-mcfly",
                        @"owen-wilson", @"robert-downey-jr", @"seth-rogen",
                        @"vince-vaughn", @"will-ferrell", @"zach-galifianakis",
                        @"", @"", @"" ];

    NSArray* mails = @[@"adam.sandler@gmail.com", @"bstiller@gmail.Com", @"bill@murray.com",
                       @"helmet.brown@futur.com", @"hill@benny.com", @"marty@futur.com",
                       @"owenwilson@gmail.com", @"robert@downey.jr", @"srogen@gmail.com",
                       @"vv@gmail.com", @"will.ferrell@yahoo.com", @"zgalifianakis@yahoo.com",
                       @"address@mail.com", @"prenom.nom@yahoo.com", @"someone@mail.com"];
    
    NSArray* names = @[@"Adam Sandler", @"Ben Stiller", @"Bill Murray",
                       @"Doc Helmet Brown", @"Jonah Hill", @"Marty McFly",
                       @"Owen Wilson", @"Robert Downey Jr", @"Seth Rogen",
                       @"Vince Vaughn", @"Will Ferrell", @"Zach Galifianakis",
                       @"address@mail.com", @"Prénom Nom", @"Someone"];

    NSArray* codeNames = @[@"AS", @"BS", @"BM",
                       @"DHB", @"JH", @"MCF",
                       @"OW", @"RDJ", @"SR",
                       @"VV", @"WF", @"ZG",
                       @"ADR", @"PN", @"S"];
    
    NSMutableArray* tmp = [[NSMutableArray alloc] initWithCapacity:images.count];
    
    NSInteger idx = 0;
    for (NSString* image in images) {
        Person* p = [Person createWithName:names[idx] icon:image codeName:codeNames[idx]];
        p.email = mails[idx];
        [tmp addObject:p];
        idx++;
    }
    
    self.alls = tmp;
    self.allsNeg = [NSMutableArray arrayWithCapacity:6];
    [self.allsNeg addObject:[[Person alloc] init]];
    return self;
}


-(NSInteger) randomID
{
    NSInteger max = self.alls.count;
    return rand() % max;
}


-(Person*) getPersonID:(NSInteger)idx
{
    
    if (idx<0) {
        return  self.allsNeg[-idx];
    }
    
    return self.alls[idx];
}


-(void) registerPersonWithNegativeID:(Person*)p
{
    p.isTheUser = YES;
    [self.allsNeg addObject:p];
}



@end



@implementation Person

+(Person*) createWithName:(NSString*)name icon:(NSString*)icon codeName:(NSString*)codeName
{
    Person* p = [[Person alloc] init];
    
    p.name = name;
    p.imageName = (icon.length>0) ? icon : nil;
    p.codeName = codeName;
    
    return p;
}


-(UIView*) badgeView
{
    if (self.imageName == nil) {
        
        UILabel* perso = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
        perso.backgroundColor = [UIGlobal noImageBadgeColor];
        
        if (self.isTheUser) {
            perso.backgroundColor = [[Accounts sharedInstance] currentAccount].userColor;
        }
        
        perso.text = self.codeName;
        perso.textAlignment = NSTextAlignmentCenter;
        perso.textColor = [UIColor whiteColor];
        perso.layer.cornerRadius = 16.5;
        perso.layer.masksToBounds = YES;
        perso.font = [UIFont systemFontOfSize:12];
        
        return perso;
    }
    else {
        
        UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
        iv.image = [UIImage imageNamed:self.imageName];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.layer.cornerRadius = 16.5;
        iv.layer.masksToBounds = YES;
        
        return iv;
    }
    
}


@end
