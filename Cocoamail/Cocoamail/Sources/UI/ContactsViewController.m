//
//  ContactsViewController.m
//  Cocoamail
//
//  Created by Pascal Costa-Cunha on 16/08/2015.
//  Copyright (c) 2015 cocoasoft. All rights reserved.
//

#import "ContactsViewController.h"

#import "WhiteBlurNavBar.h"
#import "Persons.h"


@interface ContactsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView* table;
@property (nonatomic, weak) WhiteBlurNavBar* navBar;

@end



@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    WhiteBlurNavBar* navBar = [[WhiteBlurNavBar alloc] initWithWidth:screenBounds.size.width];
    
    UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:nil];//@"Contacts"];
    
    UIButton* back = [WhiteBlurNavBar navBarButtonWithImage:@"back_off" andHighlighted:@"back_on"];
    [back addTarget:self action:@selector(_back) forControlEvents:UIControlEventTouchUpInside];
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    item.titleView = [WhiteBlurNavBar titleViewForItemTitle:@"Contacts"];
    
    [navBar pushNavigationItem:item animated:NO];
    
    UITableView* table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       screenBounds.size.width,
                                                                       screenBounds.size.height-20)
                                                      style:UITableViewStyleGrouped];
    table.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    table.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    table.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:table];
    [self.view addSubview:navBar];
    
    [navBar createWhiteMaskOverView:table withOffset:44];
    
    self.navBar = navBar;
    
    table.dataSource = self;
    table.delegate = self;
    
    table.clipsToBounds = NO;
    self.table = table;
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


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.mail.toPersonID.count;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    Person* person = [[Persons sharedInstance] getPersonID:[self.mail.toPersonID[indexPath.row] integerValue]];
    
    
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    UIView* v = [person badgeView];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(33.f, 33.f), NO, [UIScreen mainScreen].scale);
    //[v drawViewHierarchyInRect:CGRectMake(0.f, 0.f, 33.f, 33.f) afterScreenUpdates:NO];
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cell.imageView.image = img;
    [cell.imageView addSubview:v];
    cell.textLabel.text = person.name;
    
    return cell;
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
    return CGFLOAT_MIN;
}


-(NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Person* person = [[Persons sharedInstance] getPersonID:[self.mail.toPersonID[indexPath.row] integerValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPRESENT_FOLDER_NOTIFICATION object:nil userInfo:@{kPRESENT_FOLDER_PERSON:person}];
    //[ViewController presentAlertWIP:@"go to user view"];
}




@end
