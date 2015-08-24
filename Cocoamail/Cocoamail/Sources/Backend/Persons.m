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

@property (nonatomic, strong) NSMutableArray* alls;
@property (nonatomic, strong) NSMutableArray* allsNeg;

@end


@interface Person ()

@property (nonatomic, strong) NSString* codeName;
@property (nonatomic, strong) NSString* imageName;
@property (nonatomic) NSInteger userAccountID;

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

    NSArray* mails = @[@"adam.sandler@gmail.com", @"bstiller@gmail.com", @"bill@murray.com",
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
        Person* p = [Person createWithName:names[idx] email:mails[idx] icon:image codeName:codeNames[idx]];
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


-(NSInteger) addPerson:(Person*)person
{
    [self.alls addObject:person];
    return (self.alls.count - 1);
}


-(void) registerPersonWithNegativeID:(Person*)p
{
    p.userAccountID = self.allsNeg.count;
    [self.allsNeg addObject:p];
}

-(NSArray*) allPersons
{
    NSMutableArray* res = [[NSMutableArray alloc] initWithCapacity:self.alls.count + self.allsNeg.count];
    
    for (Person* p in self.alls) {
        if (p.email.length>0 && [p.email rangeOfString:@"@"].location != NSNotFound) {
            [res addObject:p];
        }
    }

    for (Person* p in self.allsNeg) {
        if (p.email.length>0 && [p.email rangeOfString:@"@"].location != NSNotFound) {
            [res addObject:p];
        }
    }
    
    return res;
}

-(NSInteger) indexForPerson:(Person*)p
{
    NSInteger idx = [self.alls indexOfObject:p];
    if (idx == NSNotFound) {
        idx = -[self.allsNeg indexOfObject:p];
    }
    return idx;
}



@end



@implementation Person

+(Person*) createWithName:(NSString*)name email:(NSString*)mail icon:(NSString*)icon codeName:(NSString*)codeName
{
    Person* p = [[Person alloc] init];
    
    p.name = name;
    p.imageName = (icon.length>0) ? icon : nil;
    p.codeName = codeName;
    p.email = mail;
    
    return p;
}


-(UIView*) badgeView
{
    if (self.imageName == nil) {
        
        UILabel* perso = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
        perso.backgroundColor = [UIGlobal noImageBadgeColor];
        
        if (self.userAccountID>0) {
            Account* a = [[Accounts sharedInstance] accounts][self.userAccountID-1];
            perso.backgroundColor = a.userColor;
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
        
        if (self.codeName==nil && self.email==nil && self.name==nil) {
            // "…" icon
            iv.image = [[UIImage imageNamed:self.imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            iv.tintColor = [UIGlobal noImageBadgeColor];
        }
        else {
            iv.image = [UIImage imageNamed:self.imageName];
        }
        
        
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.layer.cornerRadius = 16.5;
        iv.layer.masksToBounds = YES;
        
        return iv;
    }
    
}


@end
