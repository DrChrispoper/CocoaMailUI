//
//  Accounts.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 11/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Accounts.h"

@implementation Accounts

+(Accounts*) sharedInstance
{
    static dispatch_once_t once;
    static Accounts* sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.quickSwipeType = 2;
        
        Account* a1 = [self _createAccountMail:@"jean@lafontaine.com" color:[UIColor colorWithRed:1.f green:0.49f blue:0.01f alpha:1.f] code:@"JF"];
        Account* a2 = [self _createAccountMail:@"jlf@google.com" color:[UIColor colorWithRed:0.07f green:0.71f blue:0.02f alpha:1.f] code:@"JLF"];
        Account* a3 = [self _createAccountMail:@"jeanlf@yahoo.com" color:[UIColor colorWithRed:0.01f green:0.49f blue:1.f alpha:1.f] code:@"DOM"];
        Account* a4 = [self _createAccountMail:@"jean.pro@cocoamail.com" color:[UIColor colorWithRed:1.f green:0.07f blue:0.01f alpha:1.f] code:@"PRO"];
        Account* all = [self _createAllAccountsFrom:@[a1, a2, a3, a4]];
        sharedInstance.accounts = @[a1, a2, a3, a4, all];
    });
    return sharedInstance;    
}


+(Account*) _createAccountMail:(NSString*)mail color:(UIColor*)color code:(NSString*)code
{
    Account* ac = [[Account alloc] init];
    ac.userMail = mail;
    ac.userColor = color;
    ac.codeName = code;
    
    ac.systemFolders = @[@(394),@(48),@(0),@(3),@(0),@(0),@(0)];
    ac.userFolders = @[@"Bills", @"Mun & Dad", @"Bill Murray", @"Owen Wilson", @"Marty McFly", @"Doc Brown", @"Biff Tannen"];
    ac.person = [Person createWithName:mail email:ac.userMail icon:nil codeName:code];
    [[Persons sharedInstance] registerPersonWithNegativeID:ac.person];
    
    return ac;
}


+(Account*) _createAllAccountsFrom:(NSArray*)accounts
{
    Account* ac = [[Account alloc] init];
    ac.userMail = NSLocalizedString(@"All accounts", @"All accounts");
    ac.userColor = [UIColor blackColor];
    ac.codeName = @"ALL";
    ac.isAllAccounts = YES;
    NSMutableArray* counters = [NSMutableArray arrayWithCapacity:7];
    for (int i=0; i<7; i++) {
    
        NSInteger c = 0;
        for (Account* a in accounts) {
            c += [a.systemFolders[i] integerValue];
        }
        
        [counters addObject:@(c)];
    }
    ac.systemFolders = counters;
    
    NSMutableArray* userfolders = [NSMutableArray arrayWithCapacity:50];
    for (Account* a in accounts) {
        [userfolders addObjectsFromArray:a.userFolders];
    }
    
    ac.userFolders = userfolders;
    ac.person = [Person createWithName:ac.userMail email:ac.userMail icon:nil codeName:ac.codeName];
    [[Persons sharedInstance] registerPersonWithNegativeID:ac.person];
    
    return ac;
}

-(Account*) currentAccount
{
    return self.accounts[self.currentAccountIdx];
}



+(NSArray*) systemFolderNames
{
    return @[NSLocalizedString(@"Inbox", @"Inbox"),
             NSLocalizedString(@"Favoris", @"Favoris"),
             NSLocalizedString(@"Sent", @"Sent"),
             NSLocalizedString(@"Drafts", @"Drafts"),
             NSLocalizedString(@"All emails", @"All emails"),
             NSLocalizedString(@"Deleted", @"Deleted"),
             NSLocalizedString(@"Spam",@"Spam")];
}

+(NSArray*) systemFolderIcons
{
    return @[@"inbox_off", @"favoris_off", @"sent_off", @"draft_off", @"all_off", @"delete_off", @"spam_off"];
}

+(NSString*) userFolderIcon
{
    return @"folder_off";
}


@end




@implementation Account



@end
