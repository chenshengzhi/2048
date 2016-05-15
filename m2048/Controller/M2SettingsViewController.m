//
//  M2SettingsViewController.m
//  m2048
//
//  Created by Danqing on 3/16/14.
//  Copyright (c) 2014 Danqing. All rights reserved.
//

#import "M2SettingsViewController.h"
#import "M2SettingsDetailViewController.h"
#import "SVProgressHUD.h"
#import "M2ArchivesViewController.h"
#import "M2GameManager.h"

@interface M2SettingsViewController ()

@end


@implementation M2SettingsViewController {
    IBOutlet UITableView *_tableView;
    NSArray *_titles;
    NSArray *_keys;
    NSArray *_optionSelections;
    NSArray *_optionsNotes;
    NSArray *_archives;
}


# pragma mark - Set up

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}


- (void)commonInit {
    _titles = @[M2LocalizedString(@"GameType"), M2LocalizedString(@"BoardSize"), M2LocalizedString(@"Theme")];
    
    _keys = @[@"Game Type", @"Board Size", @"Theme"];
    
    _archives = @[M2LocalizedString(@"Save"), M2LocalizedString(@"LoadArchives")];
    
    _optionSelections = @[@[M2LocalizedString(@"Powers2"), M2LocalizedString(@"Powers3"), M2LocalizedString(@"Fibonacci")],
                          @[@"3 x 3", @"4 x 4", @"5 x 5"],
                          @[@"Default", @"Vibrant", @"Joyful"]];
    
    _optionsNotes = @[@"For Fibonacci games, a tile can be joined with a tile that is one level above or below it, but not to one equal to it. For Powers of 3, you need 3 consecutive tiles to be the same to trigger a merge!",
                      @"The smaller the board is, the harder! For 5 x 5 board, two tiles will be added every round if you are playing Powers of 2.",
                      @"Choose your favorite appearance and get your own feeling of 2048! More (and higher quality) themes are in the works so check back regularly!"];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [GSTATE scoreBoardColor];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Settings Detail Segue"]) {
        M2SettingsDetailViewController *sdvc = segue.destinationViewController;
        
        NSInteger index = [_tableView indexPathForSelectedRow].row;
        sdvc.title = [_titles objectAtIndex:index];
        sdvc.key = [_keys objectAtIndex:index];
        sdvc.options = [_optionSelections objectAtIndex:index];
        sdvc.footer = [_optionsNotes objectAtIndex:index];
    }
}

# pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return _titles.count;
        case 1:
            return _archives.count;
        case 2:
            return 1;
        case 3:
            return 1;
        default:
            return 0;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return M2LocalizedString(@"ChangingSettingsNote");
    }
    return @"";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Settings Cell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.section == 0) {
        cell.textLabel.text = [_titles objectAtIndex:indexPath.row];
        
        NSInteger index = [Settings integerForKey:[_keys objectAtIndex:indexPath.row]];
        cell.detailTextLabel.text = [[_optionSelections objectAtIndex:indexPath.row] objectAtIndex:index];
        cell.detailTextLabel.textColor = [GSTATE scoreBoardColor];
    } else if (indexPath.section == 1) {
        cell.textLabel.text = [_archives objectAtIndex:indexPath.row];
        
        cell.detailTextLabel.text = @"";
    } else if (indexPath.section == 2) {
        cell.textLabel.text = M2LocalizedString(@"About2048");
        cell.detailTextLabel.text = @"";
    } else if (indexPath.section == 3) {
        cell.textLabel.text = M2LocalizedString(@"SetpBack");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = @"";
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [self performSegueWithIdentifier:@"Settings Detail Segue" sender:nil];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            if ([[M2GameManager manager] saveCurrentState]) {
                [SVProgressHUD showSuccessWithStatus:M2LocalizedString(@"Success")];
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [SVProgressHUD showErrorWithStatus:M2LocalizedString(@"Failure")];
            }
        } else {
            //TODO:从存档载入
            M2ArchivesViewController *vc = [[M2ArchivesViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if (indexPath.section == 2) {
        [self performSegueWithIdentifier:@"About Segue" sender:nil];
    } else if (indexPath.section == 3) {
        [self dismissViewControllerAnimated:YES completion:^{
            [[M2GameManager manager] stepBack];
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
