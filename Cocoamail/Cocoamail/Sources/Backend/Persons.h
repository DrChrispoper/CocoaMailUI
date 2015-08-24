//
//  Persons.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 13/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class Person;

@interface Persons : NSObject

+(Persons*) sharedInstance;

-(Person*) getPersonID:(NSInteger)idx;

-(NSInteger) randomID;

-(void) registerPersonWithNegativeID:(Person*)p;

-(NSInteger) addPerson:(Person*)person;

@property (nonatomic) NSInteger idxMorePerson;

-(NSArray*) allPersons;
-(NSInteger) indexForPerson:(Person*)p;


@end


@interface Person : NSObject

@property (nonatomic, strong) NSString* name;

@property (nonatomic, strong) NSString* email;

-(UIView*) badgeView;

+(Person*) createWithName:(NSString*)name email:(NSString*)mail icon:(NSString*)icon codeName:(NSString*)codeName;

@end
