//
//  MailListViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 16/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "MailListViewController.h"

#import "ConversationTableViewCell.h"
#import "Parser.h"
#import "Mail.h"
#import "Accounts.h"

@interface MailListViewController () <UITableViewDataSource, UITableViewDelegate, ConversationCellDelegate>

@property (nonatomic, strong) NSMutableArray* convByDay;
@property (nonatomic, weak) UITableView* table;

@property (nonatomic, strong) NSString* folderName;

@property (nonatomic, strong) NSMutableSet* selectedCells;

@property (nonatomic, strong) Person* onlyPerson;

@property (nonatomic) BOOL presentAttach;

@property (nonatomic) FolderType folder;

@end



@implementation MailListViewController

-(instancetype) initWithName:(NSString*)name
{
    self = [super init];    
    self.folderName = name;
    self.selectedCells = [[NSMutableSet alloc] initWithCapacity:25];
    return self;
}

-(instancetype) initWithFolder:(FolderType)folder
{
    NSString* name = nil;
    if (folder.type == FolderTypeUser) {
        name = [[Accounts sharedInstance] currentAccount].userFolders[folder.idx];
    }
    else {
        name = [Accounts systemFolderNames][folder.type];
    }
    
    self = [self initWithName:name];
    self.folder = folder;
    return self;
}


-(instancetype) initWithPerson:(Person*)person
{
    self = [self initWithName:person.name];
    
    self.onlyPerson = person;
    self.folder = FolderTypeWith(FolderTypeAll, 0);
    
    return self;
}

-(BOOL) istheSame:(MailListViewController*)other
{
    if (self.onlyPerson!=nil) {
        return self.onlyPerson == other.onlyPerson;
    }
    
    if (self.folder.type != FolderTypeUser) {
        return (self.folder.type == other.folder.type);
    }
    else if (other.folder.type == FolderTypeUser) {
        return other.folder.idx == self.folder.idx;
    }
    
    return NO;
}


-(void) _applyTrueTitleViewTo:(UINavigationItem*)item
{
    UILabel* l = [WhiteBlurNavBar titleViewForItemTitle:self.folderName];
    /*
    if (self.onlyPerson==nil) {
        l.textColor = [[Accounts sharedInstance] currentAccount].userColor;
    }
     */
    item.titleView = l;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    [self setupData];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    item.leftBarButtonItem = [self backButtonInNavBar];
    
    [self _applyTrueTitleViewTo:item];
    
    if (self.presentAttach) {
        UIButton* attach = [WhiteBlurNavBar navBarButtonWithImage:@"attachment_off" andHighlighted:@"attachment_on"];
        [attach addTarget:self action:@selector(_attach) forControlEvents:UIControlEventTouchUpInside];
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:attach];
    }
    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       screenBounds.size.height - 20)
                                                      style:UITableViewStyleGrouped];

    
    CGFloat offsetToUse = 44.f;
    
    if (self.onlyPerson) {
        
        UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, -92, screenBounds.size.width, 92)];
        header.backgroundColor = [UIColor whiteColor];
        
        
        UIView* badge = [self.onlyPerson badgeView];
        badge.center = CGPointMake(33 + 13, 46);
        badge.transform = CGAffineTransformMakeScale(2.f, 2.f);
        [header addSubview:badge];
        
        UILabel* l = [[UILabel alloc] initWithFrame:CGRectMake(26+66, 31, screenBounds.size.width - (66+26) - 13, 30)];
        l.backgroundColor = header.backgroundColor;
        l.text = self.onlyPerson.email;
        l.font = [UIFont systemFontOfSize:16];
        l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [header addSubview:l];
        
        
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 0.5)];
        line.backgroundColor = [UIGlobal standardLightGrey];
        
        line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [header addSubview:line];
        
        [table addSubview:header];
        
        offsetToUse += 92;
    }

    table.contentInset = UIEdgeInsetsMake(offsetToUse, 0, 60, 0);
    
    table.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0,0.5);
    table.allowsSelection = false;
    table.rowHeight = 90;
    table.separatorStyle = UITableViewCellSeparatorStyleNone;
    table.backgroundColor = [UIGlobal standardLightGrey];
    
    [self.view addSubview:table];
    
    [self setupNavBarWith:item overMainScrollView:table];

    table.dataSource = self;
    table.delegate = self;
    self.table = table;
    
    [self addPullToRefreshWithDelta:0];
}


-(void) _attach
{
    Conversation* c = [[Conversation alloc] init];
    // keep only mail sent by onlyPerson with attachment
    NSMutableArray* tmp = [NSMutableArray arrayWithCapacity:500];
    for (NSDictionary* d in self.convByDay) {
        NSArray* convs = d[@"list"];
        
        for (Conversation* c in convs) {
            for (Mail* m in c.mails) {
                if ([m haveAttachment]) {
                    if ([[Persons sharedInstance] getPersonID:m.fromPersonID] == self.onlyPerson) {
                        [tmp addObject:m];
                    }
                }
            }
        }
    }
    
    c.mails = tmp;

    // to have the right title in next VC
    [c firstMail].title = self.onlyPerson.name;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_CONVERSATION_ATTACHMENTS_NOTIFICATION object:nil
                                                      userInfo:@{kPRESENT_CONVERSATION_KEY:c}];
}


-(void) cleanBeforeGoingBack
{
    self.table.delegate = nil;
    self.table.dataSource = nil;    
}


-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self isPresentingDrafts]) {
        [self setupData];
    }
    
    [self.table reloadData];
}


-(void) setupData
{
    NSArray* mails = [[[Accounts sharedInstance] currentAccount] getConversationsForFolder:self.folder];
    //NSArray* mails = [[Parser sharedParser] getAllConversations];
    
    // sort them by day
    NSString* currentDay = @"noDay";
    NSInteger currentIdx = -1;
    
    NSMutableArray* construct = [NSMutableArray arrayWithCapacity:100];
    
    for (Conversation* conv in mails) {
        
        NSString* convDay = [[conv firstMail] day];
        
        if (self.onlyPerson!=nil) {
            NSInteger mid = [conv firstMail].fromPersonID;
            Person* p = [[Persons sharedInstance] getPersonID:mid];
            
            if (p != self.onlyPerson) {
                continue;
            }
            
            if (self.presentAttach==NO) {
                self.presentAttach = [conv haveAttachment];
            }
        }
        
        if ([convDay isEqualToString:currentDay]) {
            NSDictionary* current = construct[currentIdx];
            NSMutableArray* list = current[@"list"];
            [list addObject:conv];
        }
        else {
            currentIdx++;
            currentDay = convDay;
            NSDictionary* current = @{@"list": [NSMutableArray arrayWithObject:conv], @"day":currentDay};
            [construct addObject:current];
        }
    }

    self.convByDay = construct;
}


#pragma mark - Cell Delegate

-(BOOL) isPresentingDrafts
{
    return self.folder.type == FolderTypeDrafts;
}


-(UIImageView*) imageViewForQuickSwipeAction
{
    NSArray* imgNames = @[@"swipe_archive", @"swipe_delete", @"swipe_reply_single", @"swipe_unread", @"swipe_inbox"];
    NSInteger swipetype = [Accounts sharedInstance].quickSwipeType;
    
    FolderType type;
    if (swipetype==QuickSwipeArchive) {
        type.type = FolderTypeAll;
    }
    else if (swipetype==QuickSwipeDelete){
        type.type = FolderTypeDeleted;
    }
    
    if (self.folder.type == type.type) {
        swipetype = 4;
    }
    
    
    if ([self isPresentingDrafts]) {
        swipetype = 1;
    }
    
    UIImageView* arch = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgNames[swipetype]]];
    if (swipetype==QuickSwipeReply) {
        arch.highlightedImage = [UIImage imageNamed:@"swipe_reply_all"];
    }
    return arch;
}


-(void) unselectAll
{
    [UIView setAnimationsEnabled:NO];
    
    UINavigationItem* item =self.navBar.items.lastObject;
    [self _applyTrueTitleViewTo:item];
    [self.navBar setNeedsDisplay];
    [UIView setAnimationsEnabled:YES];
    
    NSArray* visibles = self.table.visibleCells;
    for (ConversationTableViewCell* cell in visibles) {
        if ([self.selectedCells containsObject:[cell currentID]]) {
            [cell animatedClose];
        }
    }
    [self.selectedCells removeAllObjects];
}



-(void)_commonRemoveCell:(NSIndexPath*)ip
{
    // change in model
    NSDictionary* dayInfos = self.convByDay[ip.section];
    NSMutableArray* ma = dayInfos[@"list"];
    [ma removeObjectAtIndex:ip.row];
    
    // change in UI
    if (ma.count<1) {
        [self.convByDay removeObjectAtIndex:ip.section];
        
        NSIndexSet* set = [NSIndexSet indexSetWithIndex:ip.section];
        [self.table deleteSections:set withRowAnimation:UITableViewRowAnimationLeft];
    }
    else {
        [self.table deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationLeft];
    }
 
    // TODO deleting cells disturb the nav bar blur cache !!!
    
}

-(void) _removeCell:(ConversationTableViewCell *)cell
{
    NSIndexPath* ip = [self.table indexPathForCell:cell];
    [self _commonRemoveCell:ip];
    [self cell:cell isChangingDuring:0.3];
}

-(void) leftActionDoneForCell:(ConversationTableViewCell *)cell
{
    NSIndexPath* indexPath = [self.table indexPathForCell:cell];
    NSDictionary* mailsDay = self.convByDay[indexPath.section];
    NSArray* convs = mailsDay[@"list"];
    Conversation* conv = convs[indexPath.row];
    
    QuickSwipeType swipetype = [Accounts sharedInstance].quickSwipeType;
    
    switch (swipetype) {
        case QuickSwipeReply:
        {
            Mail* m = [conv firstMail];
            Mail* repm = [m replyMail:[cell isReplyAll]];
            [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_EDITMAIL_NOTIFICATION object:nil userInfo:@{kPRESENT_MAIL_KEY:repm}];
            break;
        }
        case QuickSwipeMark:
        {
            break;
        }
        default:
        {
            // QuickSwipeArchive / QuickSwipeDelete
            FolderType type;
            type.type = (swipetype==QuickSwipeArchive) ? FolderTypeAll : FolderTypeDeleted;
            
            // back action
            if (self.folder.type == type.type) {
                type.type = FolderTypeInbox;
            }
            
            Account* ac = [[Accounts sharedInstance] currentAccount];
            if ([ac moveConversation:conv from:self.folder to:type]) {
                [self _removeCell:cell];
            }
            
            break;
        }
    }
    
}

-(void) cell:(ConversationTableViewCell*)cell isChangingDuring:(double)timeInterval;
{
    CGPoint point = CGPointMake(100, self.table.contentOffset.y + self.table.contentInset.top);
    CGRect bigger = CGRectInset(cell.frame, -500, 0);
    
    if (CGRectContainsPoint(bigger, point)) {
        [self.navBar computeBlurForceNewDuring:timeInterval];
    }
}


-(void) _manageCocoaButton
{
    CocoaButton* cb = [CocoaButton sharedButton];
    UINavigationItem* item =self.navBar.items.lastObject;
    const NSInteger nbSelected = self.selectedCells.count;
    
    if (nbSelected==0) {
        [cb forceCloseHorizontal];
        [self _applyTrueTitleViewTo:item];
    }
    else {
        if (nbSelected==1) {
            [cb forceOpenHorizontal];
        }
        
        UILabel* l = [[UILabel alloc] init];
        NSString* formatString = NSLocalizedString(@"%d Selected", @"%d Selected");
        l.text = [NSString stringWithFormat:formatString, nbSelected];
        l.textColor = [[Accounts sharedInstance] currentAccount].userColor;
        [l sizeToFit];
        item.titleView = l;        
    }
    
    [self.navBar setNeedsDisplay];
}

-(void) cellIsSelected:(ConversationTableViewCell*)cell
{
    NSString* ID = [cell currentID];
    [self.selectedCells addObject:ID];
    [self _manageCocoaButton];
}

-(void) cellIsUnselected:(ConversationTableViewCell*)cell
{
    NSString* ID = [cell currentID];
    [self.selectedCells removeObject:ID];
    [self _manageCocoaButton];    
}

-(UIPanGestureRecognizer*) tableViewPanGesture
{
    return self.table.panGestureRecognizer;
}


#pragma mark - Table Datasource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.convByDay.count;
}


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* dayContent = self.convByDay[section];
    NSArray* content = dayContent[@"list"];
    return content.count;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary* mailsDay = self.convByDay[indexPath.section];
    NSArray* convs = mailsDay[@"list"];
    Conversation* conv = convs[indexPath.row];
    
    NSString* idToUse = (conv.mails.count>1) ? kCONVERSATION_CELL_ID : kMAIL_CELL_ID;
    
    ConversationTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:idToUse];
    
    if (cell == nil) {
        cell = [[ConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:idToUse];
        [cell setupWithDelegate:self];
    }

    
    BOOL isSelected = [self.selectedCells containsObject:[conv firstMail].mailID];
    [cell fillWithConversation:conv isSelected:isSelected];
    
    return cell;
}


-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* dayContent = self.convByDay[section];
    NSString* dateS = dayContent[@"day"];
    
    NSInteger idx = [Mail isTodayOrYesterday:dateS];
    if (idx == 0) {
        return NSLocalizedString(@"Today", @"Today");
    }
    else if (idx == -1) {
        return NSLocalizedString(@"Yesterday", @"Yesterday");
    }
    return dateS;
}

#pragma mark Table Delegate

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView* support = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 24)];
    support.backgroundColor = tableView.backgroundColor;
    
    UILabel* h = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 300, 24)];
    h.backgroundColor = support.backgroundColor;
    h.textColor = [UIColor colorWithWhite:0.58 alpha:1.0];
    h.text =  [self tableView:tableView titleForHeaderInSection:section];
    h.font = [UIFont systemFontOfSize:13];
    [support addSubview:h];
    return support;
}

-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - CocoaButton

-(NSArray*) buttonsHorizontalFor:(CocoaButton*)cocoaButton
{
    const CGRect baseRect = cocoaButton.bounds;
    UIColor* color = [[Accounts sharedInstance] currentAccount].userColor;
    
    
    NSInteger folderType = self.folder.type;
    
    NSString* delete_icon = @"swipe_cocoabutton_delete";
    NSString* archive_icon = @"swipe_cocoabutton_archive";
    NSString* spam_icon = @"swipe_cocoabutton_spam";
    NSString* inbox_icon = @"swipe_inbox";
    
    
    NSArray* content = @[delete_icon];
    
    if (![self isPresentingDrafts]) {
        
        if (folderType==FolderTypeAll) {
            archive_icon = inbox_icon;
        }
        else if (folderType==FolderTypeDeleted) {
            delete_icon = inbox_icon;
        }
        else if (folderType==FolderTypeSpam) {
            spam_icon = inbox_icon;
        }
        
        content = @[delete_icon, archive_icon, @"swipe_cocoabutton_folder", spam_icon];
    }
    
    NSMutableArray* buttons = [NSMutableArray arrayWithCapacity:content.count];
    
    NSInteger idx = 0;
    for (NSString* iconName in content) {
        
        UIButton* b = [[UIButton alloc] initWithFrame:baseRect];
        b.backgroundColor = color;
    
        b.layer.cornerRadius = 22;
        b.layer.masksToBounds = YES;
        
        b.tag = idx;
        [b addTarget:self action:@selector(_chooseAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconName]];
        iv.center = b.center;
        CGFloat scale = 44.f / 33.f;
        iv.transform = CGAffineTransformMakeScale(scale, scale);
        
        [b addSubview:iv];
        
        [buttons addObject:b];
        
        idx++;
    }
    
    
    UIButton* b = [[UIButton alloc] initWithFrame:baseRect];
    b.backgroundColor = color;
    [b setImage:[UIImage imageNamed:@"swipe_cocoabutton_close"] forState:UIControlStateNormal];
    [b setImage:[UIImage imageNamed:@"swipe_cocoabutton_close"] forState:UIControlStateHighlighted];
    b.layer.cornerRadius = 22;
    b.layer.masksToBounds = YES;
    [b addTarget:self action:@selector(_closeActions) forControlEvents:UIControlEventTouchUpInside];
    [cocoaButton replaceMainButton:b];
    
    return buttons;
}

-(void) _closeActions
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self unselectAll];
                     }];
    [[CocoaButton sharedButton] forceCloseButton];
}




-(void) _executeMoveOnSelectedCellsTo:(FolderType)toFolder
{
    // find the conversations
    NSMutableArray* res = [[NSMutableArray alloc] initWithCapacity:self.selectedCells.count];
    NSMutableArray* resIP = [[NSMutableArray alloc] initWithCapacity:self.selectedCells.count];
    
    NSInteger section = 0;
    for (NSDictionary* mailsDay in self.convByDay) {
        NSArray* convs = mailsDay[@"list"];
        NSInteger row = 0;
        
        for (Conversation* conv in convs) {
            
            NSString* mailID = [conv firstMail].mailID;
            if ([self.selectedCells containsObject:mailID]) {
                [res addObject:conv];
                [resIP addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
            
            row++;
        }
        
        if (res.count == self.selectedCells.count) {
            break;
        }
        section++;
    }
    // TODO find a less expensive way to do that
    
    
    BOOL animDissapear = NO;
    
    Account* ac = [[Accounts sharedInstance] currentAccount];
    for (Conversation* conv in res) {
        if ([ac moveConversation:conv from:self.folder to:toFolder]) {
            animDissapear = YES;
        }
    }
    
    if (animDissapear) {
        
        [self.table beginUpdates];
        
        for (NSIndexPath* ip in [resIP reverseObjectEnumerator]) {
            [self _commonRemoveCell:ip];
        }
        
        NSArray* cells = self.table.visibleCells;
        for (ConversationTableViewCell* cell in cells) {
            if ([self.selectedCells containsObject:[cell currentID]]) {
                [self cell:cell isChangingDuring:0.3];
            }
        }
        
        [self.table endUpdates];
        
        UINavigationItem* item = self.navBar.items.lastObject;
        [self _applyTrueTitleViewTo:item];
        
    }
    else {
        [self unselectAll];
    }
    
    [self.selectedCells removeAllObjects];
    [[CocoaButton sharedButton] forceCloseButton];
}




-(void) _chooseAction:(UIButton*)button
{
    [CocoaButton animateHorizontalButtonCancelTouch:button];
    
    FolderType toFolder;
    toFolder.idx = 0;
    BOOL doNothing = NO;
    
    switch (button.tag) {
        case 0:
            toFolder.type = (self.folder.type == FolderTypeDeleted) ? FolderTypeInbox : FolderTypeDeleted;
            break;
        case 1:
            toFolder.type = (self.folder.type == FolderTypeAll) ? FolderTypeInbox : FolderTypeAll;
            break;
        case 2:
        {
            doNothing = YES;
            
            UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            NSInteger idx = 0;
            for (NSString* folder in [[Accounts sharedInstance] currentAccount].userFolders) {
                
                if (self.folder.type == FolderTypeUser && idx == self.folder.idx) {
                    continue;
                }
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:folder style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction* aa) {
                                                                          [self _executeMoveOnSelectedCellsTo:FolderTypeWith(FolderTypeUser, idx)];
                                                                      }];
                [ac addAction:defaultAction];
            }
            
            if (ac.actions.count == 0) {
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Create a folder" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction* aa) {
                                                                          // TODO …
                                                                      }];
                [ac addAction:defaultAction];
            }
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel
                                                                  handler:nil];
            [ac addAction:defaultAction];
            
            ac.view.tintColor = [UIColor blackColor];
            
            ViewController* vc = [ViewController mainVC];
            [vc presentViewController:ac animated:YES completion:nil];
            
            break;
        }
        case 3:
            toFolder.type = (self.folder.type == FolderTypeSpam) ? FolderTypeInbox : FolderTypeSpam;
            break;
        default:
            [ViewController presentAlertWIP:@"It's a bug!!"];
            NSLog(@"WTF !!!");
            doNothing = YES;
            break;
    }
    
    if (!doNothing) {
        [self _executeMoveOnSelectedCellsTo:toFolder];
    }
}


-(NSArray*) buttonsWideFor:(CocoaButton*)cocoabutton
{
    return nil;
}

-(BOOL) automaticCloseFor:(CocoaButton*)cocoabutton
{
    return self.selectedCells.count == 0;
}

@end
