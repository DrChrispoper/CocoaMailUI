//
//  Parser.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 15/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Parser.h"

#import <UIKit/UIKit.h>

#import "Mail.h"

@interface Parser ()

@property (nonatomic, strong) NSOperationQueue* QUEUE;

@property (nonatomic, strong) NSMutableArray* fables;
@property (nonatomic, strong) NSMutableArray* allConversations;

@end


@implementation Parser

+(Parser*) sharedParser
{
    static dispatch_once_t once;
    static Parser* sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}



-(instancetype) init
{
    self = [super init];
    
    self.QUEUE = [[NSOperationQueue alloc] init];
    self.QUEUE.maxConcurrentOperationCount = 1;
    
    return self;
}


-(void) parseFables
{
    NSString* tmpDir = NSTemporaryDirectory();
    NSLog(@"%@",tmpDir);
    
    self.fables = [[NSMutableArray alloc] initWithCapacity:250];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (NSInteger i=1; i<248; i++) {
            
            NSBlockOperation* bop = [NSBlockOperation blockOperationWithBlock:^{
                [self parseFable:i];
            }];
            
            [self.QUEUE addOperation:bop];
        }
        
        
        NSBlockOperation* bop = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"%lu fables", (unsigned long)self.fables.count);
            
            NSString* path = [tmpDir stringByAppendingPathComponent:@"fables.txt"];
            [self.fables writeToFile:path atomically:YES];
            
        }];
        
        
        [self.QUEUE addOperation:bop];
        
    });
    
    
}




-(void) parseFable:(NSInteger)withID
{
    NSLog(@"parse fable %ld", (long)withID);
    
    NSString* urlStr = [NSString stringWithFormat:@"http://www.lafontaine.net/lesFables/afficheFable.php?id=%ld", (long)withID];
    NSURL* url = [NSURL URLWithString:urlStr];
    
    NSString* pageHTML = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:nil];
    
    NSString* titleStart = @"<title>";
    NSString* titleEnd = @"</title>";
    
    NSRange range = [pageHTML rangeOfString:titleStart];
    
    NSString* reste = [pageHTML substringFromIndex:range.location + range.length];
    
    range = [reste rangeOfString:titleEnd];
    
    NSString* titleFound = [[reste substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    reste = [reste substringFromIndex:range.location+range.length];
    
    
//    NSLog(@"%@", titleFound);
    
    NSString* div0 = @"<div id=\"boiteTexte\">";
    
    range = [reste rangeOfString:div0];
    reste = [reste substringFromIndex:range.location + range.length];
    
    NSString* div1 = @"<div style=\"background-color:#E5E5E5;text-align:left;\"><div style=\"margin-left:20px\">";
    NSString* div2 = @"</div>";
    
    range = [reste rangeOfString:div1];
    reste = [reste substringFromIndex:range.location + range.length];
    
    range = [reste rangeOfString:div2];
    
    NSString* contentFound = [reste substringToIndex:range.location];
    
    NSAttributedString* attrContent = [[NSAttributedString alloc] initWithData:[contentFound dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
    
//    NSLog(@"%@", contentFound);
//    NSLog(@"%@", attrContent.string);
    
    
    if (titleFound.length>0) {
        
        NSDictionary* fable = @{@"title":titleFound, @"content":attrContent.string};
        [self.fables addObject:fable];
        
    }
}

-(void) fillFromFile
{
    if (self.fables != nil) {
        return;
    }
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"fables" ofType:@"txt"];
    //self.fables = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    NSMutableArray* array = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    NSMutableArray* res = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (NSDictionary* fable in array) {
        
        NSString* title = [fable[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString* content = fable[@"content"];
        
        NSMutableString* resContent = [[NSMutableString alloc] init];

        NSArray* lines = [content componentsSeparatedByString:@"\n"];
        
        for (NSString* line in lines) {

            NSString* l = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if (l.length>0) {
                [resContent appendString:l];
                [resContent appendString:@" "];
            }
            else {
                [resContent appendString:@"\n"];
            }
        }
        
        
        [res addObject:@{@"title":title, @"content":resContent}];
    }

    self.fables = res;
    
}

-(NSMutableArray*) getAllConversations
{
    if (self.allConversations) {
        return self.allConversations;
    }
    
    [self fillFromFile];
    
    NSMutableArray* res = [[NSMutableArray alloc] initWithCapacity:100];
    
    NSTimeInterval step = -60*61*5 + 7;
    NSInteger current = 0;
    
    for (NSDictionary* fable in self.fables) {
        
        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:step*current];
        
        Conversation* conv = [[Conversation alloc] init];
        conv.mails = [Mail mailsWithInfos:fable when:date];;

        [res addObject:conv];
        
        current++;
    }
    
    self.allConversations = res;
    
    return res;    
}

-(void) cleanConversations
{
    self.allConversations = nil;
}


@end

