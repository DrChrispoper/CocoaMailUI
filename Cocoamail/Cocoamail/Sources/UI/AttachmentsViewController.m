//
//  AttachmentsViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 17/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "AttachmentsViewController.h"

#import "WhiteBlurNavBar.h"
#import "Persons.h"


@interface AttachmentsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView* table;
@property (nonatomic, weak) WhiteBlurNavBar* navBar;

@property (nonatomic, strong) NSArray* mailsWithAttachment;

@end



@interface AttachmentsCell : UITableViewCell

@property (nonatomic, weak) UILabel* name;
@property (nonatomic, weak) UILabel* size;
@property (nonatomic, weak) UIImageView* mini;


@end



@implementation AttachmentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    WhiteBlurNavBar* navBar = [[WhiteBlurNavBar alloc] initWithWidth:screenBounds.size.width];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];//[self.conversation firstMail].title];
    
    UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"back_off" andHighlighted:@"back_on"];
    [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    
    UILabel* l = [WhiteBlurNavBar titleViewForItemTitle:[self.conversation firstMail].title];
    
    UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attachment_off"]];
    
    UIView* support = [[UIView alloc] initWithFrame:CGRectMake(0, 0, l.frame.size.width + iv.frame.size.width + 2.f, 33.f)];
    support.backgroundColor = [UIColor clearColor];
    [support addSubview:iv];
    iv.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    CGRect r = l.frame;
    r.origin.x = iv.frame.size.width + 2.f;
    r.origin.y = floorf((33.f - r.size.height) / 2.f);
    l.frame = r;
    [support addSubview:l];
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if (support.frame.size.width > screenBounds.size.width - 55.f) {
        r = support.frame;
        r.size.width = screenBounds.size.width - 55.f;
        support.frame = r;
    }
    
    item.titleView = support;
    
    [navBar pushNavigationItem:item animated:NO];
    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       screenBounds.size.height-20)
                                                      style:UITableViewStyleGrouped];
    table.contentInset = UIEdgeInsetsMake(45, 0, 60, 0);
    table.scrollIndicatorInsets = UIEdgeInsetsMake(45, 0, 0, 0);
    
    table.backgroundColor = [UIColor whiteColor];
    
    //table.rowHeight = 72.5f;
    
    [self.view addSubview:table];
    [self.view addSubview:navBar];
    
    [navBar createWhiteMaskOverView:table withOffset:45];
    
    self.navBar = navBar;
    
    
    [self _setupData];
    
    table.dataSource = self;
    table.delegate = self;
    
    table.clipsToBounds = NO;
    self.table = table;
    
}


-(void) _setupData
{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:self.conversation.mails.count];
    
    for (Mail* m in self.conversation.mails) {
        if ([m haveAttachment]) {
            [res addObject:m];
        }
    }
    
    self.mailsWithAttachment = res;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) cleanBeforeGoingBack
{
    self.table.delegate = nil;
    self.table.dataSource = nil;    
}


#pragma mark - Table Datasource


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.mailsWithAttachment.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    Mail* m = self.mailsWithAttachment[section];
    return m.attachments.count;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    Mail* m = self.mailsWithAttachment[indexPath.section];
    Attachment* at = m.attachments[indexPath.row];
    
    
    NSString* reuseID = @"kAttchCellID";
    
    AttachmentsCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    
    if (cell == nil) {
        cell = [[AttachmentsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID];
    }
    
    cell.name.text = at.name;
    cell.size.text = at.size;
    cell.mini.image = [UIImage imageNamed:at.imageName];
    /*
    cell.imageView.image = [UIImage imageNamed:at.imageName];
    cell.textLabel.text = at.name;
    cell.detailTextLabel.text = at.size;
    */
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row==0) ? 73.f : 72.5f;
}


#pragma mark Table Delegate

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navBar computeBlur];
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.f;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView* support = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    support.backgroundColor = tableView.backgroundColor;
    
    support.clipsToBounds = NO;
    
    UIView* lineT = [[UIView alloc] initWithFrame:CGRectMake(0, -0.5, support.frame.size.width, 0.5)];
    lineT.backgroundColor = [UIColor colorWithWhite:0.69 alpha:1.0];
    [support addSubview:lineT];
    
    UIView* lineB = [[UIView alloc] initWithFrame:CGRectMake(0, 44, support.frame.size.width, 0.5)];
    lineB.backgroundColor = lineT.backgroundColor;
    [support addSubview:lineB];
    
    
    Mail* m = self.mailsWithAttachment[section];
    
    Person* p = [[Persons sharedInstance] getPersonID:m.fromPersonID];

    UIView* badge = [p badgeView];
    
    CGRect f = badge.frame;
    f.origin.x = 5.5;
    f.origin.y = 5.5;
    badge.frame = f;
    [support addSubview:badge];
    badge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    UILabel* t = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, 300, 44)];
    t.backgroundColor = support.backgroundColor;
    t.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
    t.font = [UIFont systemFontOfSize:12];
    t.text = m.day;
    [t sizeToFit];
    
    f = t.frame;
    f.origin.x = support.frame.size.width - f.size.width - 10.f;
    f.size.height = 44.f;
    t.frame = f;
    
    [support addSubview:t];
    t.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    
    UILabel* h = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, t.frame.origin.x - 44, 44)];
    h.backgroundColor = support.backgroundColor;
    h.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
    h.font = [UIFont systemFontOfSize:16];
    h.text = p.name;
    [support addSubview:h];
    h.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    
    return support;
}



-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
//    return indexPath;
}

/*
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
*/



@end




@implementation AttachmentsCell

-(instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    self.contentView.backgroundColor = [UIColor whiteColor];
    const CGFloat WIDTH = self.contentView.frame.size.width;
    
    UILabel* n = [[UILabel alloc] initWithFrame:CGRectMake(90, 17, WIDTH - 90 - 44, 20)];
    n.font = [UIFont systemFontOfSize:16];
    n.textColor = [UIColor blackColor];
    n.backgroundColor = self.contentView.backgroundColor;
    [self.contentView addSubview:n];
    n.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.name = n;
    
    UILabel* s = [[UILabel alloc] initWithFrame:CGRectMake(90, 38, WIDTH - 90 - 44, 20)];
    s.font = [UIFont systemFontOfSize:12];
    s.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
    s.backgroundColor = self.contentView.backgroundColor;
    [self.contentView addSubview:s];
    s.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.size = s;
    
    UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(90-50-15, 11, 50, 50)];
    iv.backgroundColor = self.contentView.backgroundColor;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:iv];
    iv.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    self.mini = iv;
    
    self.separatorInset = UIEdgeInsetsMake(0, 91, 0, 0);
    
    
    UIButton* d = [[UIButton alloc] initWithFrame:CGRectMake(WIDTH-33.f-10.f, 20.f, 33.f, 33.f)];
    [d setImage:[UIImage imageNamed:@"forward_off"] forState:UIControlStateNormal];
    [d setImage:[UIImage imageNamed:@"forward_on"] forState:UIControlStateHighlighted];
    d.backgroundColor = self.contentView.backgroundColor;
    [self.contentView addSubview:d];
    d.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    d.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    return self;
}


@end

