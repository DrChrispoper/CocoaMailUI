//
//  Accounts.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 11/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "Accounts.h"
#import "Mail.h"
#import "Parser.h"

@interface Account ()

-(void) _fakeCreateFoldersContent;

@property (nonatomic, strong) NSMutableArray* allsMails;

@property (nonatomic, strong) NSArray* userFoldersContent;
@property (nonatomic, strong) NSArray* systemFoldersContent;

@end


@implementation Accounts

+(Accounts*) sharedInstance
{
    static dispatch_once_t once;
    static Accounts* sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.quickSwipeType = QuickSwipeReply;
        
        Account* a1 = [self _createAccountMail:@"jean@lafontaine.com" color:[UIColor colorWithRed:1.f green:0.49f blue:0.01f alpha:1.f] code:@"JF"];
        a1.userFolders = @[@"Bills", @"Mum & Dad"];
        Account* a2 = [self _createAccountMail:@"jlf@google.com" color:[UIColor colorWithRed:0.07f green:0.71f blue:0.02f alpha:1.f] code:@"JLF"];
        a2.userFolders = @[@"Bill Murray"];
        Account* a3 = [self _createAccountMail:@"jeanlf@yahoo.com" color:[UIColor colorWithRed:0.01f green:0.49f blue:1.f alpha:1.f] code:@"DOM"];
        a3.userFolders = @[@"Owen Wilson"];
        Account* a4 = [self _createAccountMail:@"jean.pro@cocoamail.com" color:[UIColor colorWithRed:1.f green:0.07f blue:0.01f alpha:1.f] code:@"PRO"];
        a4.userFolders = @[@"Marty McFly", @"Doc Brown", @"Biff Tannen"];
        
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

-(void) fakeInitContent
{
    [self _fakeCreateFoldersContent];
}

-(void) releaseContent
{
    self.allsMails = nil;
    self.userFoldersContent = nil;
    self.systemFoldersContent = nil;
}


-(void) _fakeCreateFoldersContent
{
    if (self.allsMails != nil) {
        return;
    }
    
    [[Parser sharedParser] cleanConversations];    
    self.allsMails = [[Parser sharedParser] getAllConversations];
    
    // create structure
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:7];
    for (int i=0; i<7; i++) {
        [array addObject:[[NSMutableIndexSet alloc] init]];
    }
    self.systemFoldersContent = array;
    
    const NSInteger limite = self.userFolders.count;
    NSMutableArray* arrayU = [[NSMutableArray alloc] initWithCapacity:limite];
    for (int i=0; i<limite; i++) {
        [arrayU addObject:[[NSMutableIndexSet alloc] init]];
    }
    self.userFoldersContent = arrayU;
    //
    
    
    FolderType Finbox = FolderTypeWith(FolderTypeInbox, 0);
    FolderType Ffav = FolderTypeWith(FolderTypeFavoris, 0);
    //FolderType Fsent = FolderTypeWith(FolderTypeSent, 0);
    FolderType Fdrafts = FolderTypeWith(FolderTypeDrafts, 0);
    FolderType Fall = FolderTypeWith(FolderTypeAll, 0);
    FolderType Fdeleted = FolderTypeWith(FolderTypeDeleted, 0);
    FolderType FSpam = FolderTypeWith(FolderTypeSpam, 0);
    
    NSUInteger idx = 0;
    
    for (Conversation* c in self.allsMails) {
        
        NSInteger hasard = rand()%100;
    
        [self _addIdx:idx inArray:Fall];
        
        if (hasard<5) {
            for (Mail* m in c.mails) {
                m.isFav = YES;
            }
            [self _addIdx:idx inArray:Ffav];
            [self _addIdx:idx inArray:Finbox];
        }
        else if (hasard<6) {
            [self _addIdx:idx inArray:Fdrafts];
        }
        else if (hasard<10) {
            [self _addIdx:idx inArray:Fdeleted];
        }
        else if (hasard<15) {
            [self _addIdx:idx inArray:FSpam];
        }
        else if (hasard<35) {
            // user
            
            FolderType Fuser = FolderTypeWith(FolderTypeUser, rand()%self.userFoldersContent.count);
            [self _addIdx:idx inArray:Fuser];
            
        }
        else if (hasard < 95) {
            [self _addIdx:idx inArray:Finbox];
        }
        // else archived in all only
        
        idx++;
    }
        
}


-(void) _addIdx:(NSUInteger)idx inArray:(FolderType)type
{
    NSMutableIndexSet* set = nil;
    if (type.type == FolderTypeUser) {
        set = self.userFoldersContent[type.idx];
    }
    else {
        set = self.systemFoldersContent[type.type];
    }
    [set addIndex:idx];
}


-(NSArray*) getConversationsForFolder:(FolderType)type
{

    NSMutableIndexSet* set = nil;
    if (type.type == FolderTypeUser) {
        set = self.userFoldersContent[type.idx];
    }
    else {
        set = self.systemFoldersContent[type.type];
    }
    
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:[set count]];
    
    [self.allsMails enumerateObjectsAtIndexes:set
                                      options:0
                                   usingBlock:^(id obj, NSUInteger idx, BOOL* stop){
                                       [res addObject:obj];
                                   }];
    
    return res;
    
}

-(void) sendMail:(Mail*)mail
{
    NSInteger index = self.allsMails.count;
    
    [mail sendMail];
    
    Conversation* c = [[Conversation alloc] init];
    c.mails = @[mail];
    [self.allsMails addObject:c];
    
    [self _addIdx:index inArray:FolderTypeWith(FolderTypeSent, 0)];
}


-(BOOL) moveConversation:(Conversation*)conversation from:(FolderType)folderFrom to:(FolderType)folderTo
{
    
    NSUInteger idx = [self.allsMails indexOfObject:conversation];
    
    NSMutableIndexSet* setTo = nil;
    if (folderTo.type == FolderTypeUser) {
        setTo = self.userFoldersContent[folderTo.idx];
    }
    else {
        setTo = self.systemFoldersContent[folderTo.type];
    }
    
    switch (folderTo.type) {
        case FolderTypeInbox:
        case FolderTypeAll:
        case FolderTypeDeleted:
        case FolderTypeSpam:
        case FolderTypeUser:
            break;
        default:
            NSLog(@"move to this folder not implemented");
            return NO;
            break;
    }
    
    NSMutableIndexSet* setFrom = nil;
    if (folderFrom.type == FolderTypeUser) {
        setFrom = self.userFoldersContent[folderFrom.idx];
    }
    else {
        setFrom = self.systemFoldersContent[folderFrom.type];
    }
    
    BOOL remove = YES;
    
    switch (folderFrom.type) {
        case FolderTypeFavoris:
        case FolderTypeAll:
            remove = NO;
            break;
        case FolderTypeInbox:
        case FolderTypeDeleted:
        case FolderTypeSpam:
        case FolderTypeUser:
            break;
        default:
            NSLog(@"move from this folder not implemented");
            return NO;
            break;
    }
    
    if (remove) {
        [setFrom removeIndex:idx];
    }
    [setTo addIndex:idx];
    
    return remove;
}

-(NSInteger) unreadInInbox
{
    NSArray* a = [self getConversationsForFolder:FolderTypeWith(FolderTypeInbox, 0)];
    
    NSInteger count = 0;
    for (Conversation* c in a) {
        
        if (![c firstMail].isRead) {
            count++;
        }
    }
    
    return count;
}

-(void) manage:(Conversation*)conversation isFav:(BOOL)isFav;
{
    Mail* mail = [conversation firstMail];
    
    NSUInteger idx = [self.allsMails indexOfObject:conversation];
    NSMutableIndexSet * set = self.systemFoldersContent[FolderTypeFavoris];
    if (!isFav && mail.isFav) {
        [set removeIndex:idx];
    }
    else if (isFav) {
        [set addIndex:idx];
    }
    
    for (Mail* m in conversation.mails) {
        m.isFav = isFav;
    }
//    mail.isFav = isFav;
}



@end
