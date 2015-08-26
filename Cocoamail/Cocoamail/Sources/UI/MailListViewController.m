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
#import "PullToRefresh.h"

@interface MailListViewController () <UITableViewDataSource, UITableViewDelegate, ConversationCellDelegate>

@property (nonatomic, strong) NSMutableArray* convByDay;
@property (nonatomic, weak) UITableView* table;
@property (nonatomic, weak) WhiteBlurNavBar* navBar;

@property (nonatomic, strong) NSString* folderName;

@property (nonatomic, strong) NSMutableSet* selectedCells;

@property (nonatomic, strong) Person* onlyPerson;

@property (nonatomic) BOOL presentAttach;

@property (nonatomic, strong) PullToRefresh* pullToRefresh;



@end



@implementation MailListViewController

-(instancetype) initWithName:(NSString*)name
{
    self = [super init];    
    self.folderName = name;
    
    self.selectedCells = [[NSMutableSet alloc] initWithCapacity:25];
    
    return self;
}

-(instancetype) initWithPerson:(Person*)person
{
    self = [self initWithName:person.name];
    
    self.onlyPerson = person;
    
    return self;
}


-(void) _applyTrueTitleViewTo:(UINavigationItem*)item
{
    UILabel* l = [WhiteBlurNavBar titleViewForItemTitle:self.folderName];
    if (self.onlyPerson==nil) {
        l.textColor = [[Accounts sharedInstance] currentAccount].userColor;
    }
    item.titleView = l;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIGlobal standardLightGrey];
    
    [self setupData];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    WhiteBlurNavBar* navBar = [[WhiteBlurNavBar alloc] initWithWidth:screenBounds.size.width];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil/*self.folderName*/];
    
    UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"back_off" andHighlighted:@"back_on"];
    [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    [self _applyTrueTitleViewTo:item];
    
    if (self.presentAttach) {
        UIButton* attach = [WhiteBlurNavBar navBarButtonWithImage:@"attachment_off" andHighlighted:@"attachment_on"];
        [attach addTarget:self action:@selector(_attach) forControlEvents:UIControlEventTouchUpInside];
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:attach];
    }
    
    [navBar pushNavigationItem:item animated:NO];
    
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
    [self.view addSubview:navBar];
    
    self.navBar = navBar;
    self.table = table;
    
    [self.navBar createWhiteMaskOverView:self.table withOffset:offsetToUse];
    
    table.dataSource = self;
    table.delegate = self;
    
    self.pullToRefresh = [[PullToRefresh alloc] init];
                          
    
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
    [self.table reloadData];
}


-(void) setupData
{
    NSArray* mails = [[Parser sharedParser] getAllConversations];
    
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Cell Delegate

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



-(void) _removeCell:(ConversationTableViewCell *)cell
{
    NSIndexPath* ip = [self.table indexPathForCell:cell];
    
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
    
    [self cell:cell isChangingDuring:0.3];
}

-(void) leftActionDoneForCell:(ConversationTableViewCell *)cell
{
    NSInteger swipetype = [Accounts sharedInstance].quickSwipeType;
    
    
    if (swipetype==2) {
        NSIndexPath* indexPath = [self.table indexPathForCell:cell];
        
        NSDictionary* mailsDay = self.convByDay[indexPath.section];
        NSArray* convs = mailsDay[@"list"];
        Conversation* conv = convs[indexPath.row];
        
        Mail* m = [conv firstMail];
        Mail* repm = [m replyMail:[cell isReplyAll]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_EDITMAIL_NOTIFICATION object:nil userInfo:@{kPRESENT_MAIL_KEY:repm}];
    }
    else if (swipetype == 3) {
        
    }
    else {
        [self _removeCell:cell];
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
    // TWEAK
    if (section == 0) {
        return NSLocalizedString(@"Today", @"Today");
    }
    else if (section == 1) {
        return NSLocalizedString(@"Yesterday", @"Yesterday");
    }
    //
    
    NSDictionary* dayContent = self.convByDay[section];
    return dayContent[@"day"];
}

#pragma mark Table Delegate


-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navBar computeBlur];
    
    [self.pullToRefresh scrollViewDidScroll:scrollView];
}


-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pullToRefresh scrollViewDidEndDragging:scrollView];
}




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
    
    NSArray* content = @[@"swipe_cocoabutton_delete", @"swipe_cocoabutton_archive", @"swipe_cocoabutton_folder", @"swipe_cocoabutton_spam"];
    
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

-(void) _chooseAction:(UIButton*)button
{
    //NSLog(@"choose action %d", button.tag);
    
    [self unselectAll];
    [[CocoaButton sharedButton] forceCloseButton];
}


-(NSArray*) buttonsWideFor:(CocoaButton*)cocoabutton
{
    return nil;
}






@end
