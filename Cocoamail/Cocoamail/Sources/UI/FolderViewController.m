//
//  FolderViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 14/07/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "FolderViewController.h"

#import "Accounts.h"

@interface FolderViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView* table;
@property (nonatomic, weak) UIButton* settingsButton;

@end

@implementation FolderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    Account* currentAccount = [[Accounts sharedInstance] currentAccount];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];
    
    UIButton* settingsBtn = [WhiteBlurNavBar navBarButtonWithImage:@"settings_off" andHighlighted:@"settings_on"];
    [settingsBtn addTarget:self action:@selector(_settings) forControlEvents:UIControlEventTouchUpInside];
    item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsBtn];
    self.settingsButton = settingsBtn;
    
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:currentAccount.userMail];

    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       screenBounds.size.height-20)
                                                      style:UITableViewStyleGrouped];
    table.contentInset = UIEdgeInsetsMake(44-30, 0, 0, 0);
    table.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    table.backgroundColor = [UIGlobal standardLightGrey];
    
    [self.view addSubview:table];
    
    [self setupNavBarWith:item overMainScrollView:table];

    table.dataSource = self;
    table.delegate = self;    
    self.table = table;
    
    [self addPullToRefreshWithDelta:30];
}


-(void) _endPickSettingsColor:(UIColor*)color
{
    Account* account = [[Accounts sharedInstance] currentAccount];
    account.userColor = color;
    
    [[ViewController mainVC] refreshCocoaButton];
    
    [self.table reloadData];
    [self.table setContentOffset:CGPointMake(0, -self.table.contentInset.top) animated:YES];
    self.settingsButton.selected = false;
    [self.navBar computeBlurForceNew];
}


-(void) _settings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_SETTINGS_NOTIFICATION object:nil];
}

#pragma mark - Table Datasource


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Account* ac = [[Accounts sharedInstance] currentAccount];
    
    return (section==0) ? ac.systemFolders.count : ac.userFolders.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row==0) ? 44.5f : 44.0f;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    
    NSString* text = @"";
    NSString* imageName = nil;
    
    Account* cac = [[Accounts sharedInstance] currentAccount];
    
    if (indexPath.section == 0) {
        
        UIColor* colorBubble = nil;
        
        int count = [[cac systemFolders][indexPath.row] intValue];
        text = [Accounts systemFolderNames][indexPath.row];
        imageName = [Accounts systemFolderIcons][indexPath.row];
        
        switch (indexPath.row) {
            case 0:
                colorBubble = cac.userColor;
                break;
            case 1:
                colorBubble = [UIColor whiteColor];
                break;
            case 3:
                colorBubble = [UIGlobal bubbleFolderGrey];
                break;
            default:
                break;
        }
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noID"];
        
        if (colorBubble != nil && count>0) {
            
            UILabel* counter = [[UILabel alloc] initWithFrame:CGRectMake(100, (cell.frame.size.height-23)/2, 200, 23)];
            counter.backgroundColor = colorBubble;
            counter.text = [NSString stringWithFormat:@"%d", count];
            
            
            counter.textColor = [UIColor whiteColor];
            
            if (counter.textColor == counter.backgroundColor) {
                counter.textColor = [UIGlobal bubbleFolderGrey];
            }
            
            counter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            counter.layer.cornerRadius = 11.5;
            counter.layer.masksToBounds = YES;
            [counter sizeToFit];
            
            counter.textAlignment = NSTextAlignmentCenter;
            
            CGRect f = counter.frame;
            f.size.width += 14;
            f.size.height = 23;
            f.origin.x = cell.frame.size.width - 16 - f.size.width;
            counter.frame = f;

            [cell addSubview:counter];
            
        }
        
        
        
    }
    else {

        imageName = [Accounts userFolderIcon];
        text = [cac userFolders][indexPath.row];
        
        NSString* reuseID = @"kCellAccountPerso";
        
        cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
        
        if (cell==nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID];
        }
        
    }

    cell.textLabel.text = text;
    UIImage* img = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.image = img;
    cell.imageView.tintColor = cac.userColor;
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return (section==0) ? nil : @"My Folders";
}


#pragma mark Table Delegate

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* name = nil;
    if (indexPath.section == 0) {
        name = [Accounts systemFolderNames][indexPath.row];
    }
    else {
        Account* cac = [[Accounts sharedInstance] currentAccount];
        name = [cac userFolders][indexPath.row];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_FOLDER_NOTIFICATION object:nil userInfo:@{kPRESENT_FOLDER_NAME:name}];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
