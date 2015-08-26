//
//  Parser.h
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 15/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Parser : NSObject

+(Parser*) sharedParser;

//-(void) parseFables;

-(NSMutableArray*) getAllConversations;
-(void) cleanConversations;


@end
