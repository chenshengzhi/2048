//
//  M2ArchivesViewController.m
//  m2048
//
//  Created by shengzhichen on 15/5/10.
//  Copyright (c) 2015年 Danqing. All rights reserved.
//

#import "M2ArchivesViewController.h"
#import "NSFileManager-Utilities.h"
#import "SVProgressHUD.h"
#import "M2StateModel.h"
#import "NSDate+Helper.h"
#import "M2GameManager.h"

@interface M2ArchivesViewController ()

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation M2ArchivesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [SVProgressHUD show];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        weakSelf.dataSource = [[M2StateModel archivedModels] mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [SVProgressHUD dismiss];
            [weakSelf.tableView reloadData];
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    if (indexPath.row < self.dataSource.count) {
        M2StateModel *model = self.dataSource[indexPath.row];
        cell.textLabel.text = [model.date string];
        cell.detailTextLabel.text = [@(model.score) description];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.dataSource.count) {
        M2StateModel *model = self.dataSource[indexPath.row];
        [self dismissViewControllerAnimated:YES completion:^{
            [[M2GameManager manager] loadFromArchive:model];
        }];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
{
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if (indexPath.row < self.dataSource.count) {
            M2StateModel *model = self.dataSource[indexPath.row];
            
            if ([NSFileManager fileExist:model.filePath]) {
                [NSFileManager deleteFile:model.filePath];
            }
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

@end
