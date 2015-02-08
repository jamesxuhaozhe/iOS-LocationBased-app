//
//  CategoryPickerViewController.m
//  MyLocations
//
//  Created by Matthijs on 11-10-13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import "CategoryPickerViewController.h"

@implementation CategoryPickerViewController
{
  NSArray *_categories;
  NSIndexPath *_selectedIndexPath;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _categories = @[
    @"No Category",
    @"Apple Store",
    @"Bar",
    @"Bookstore",
    @"Club",
    @"Grocery Store",
    @"Historic Building",
    @"House",
    @"Icecream Vendor",
    @"Landmark",
    @"Park"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"PickedCategory"]) {
    UITableViewCell *cell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    self.selectedCategoryName = _categories[indexPath.row];
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

  NSString *categoryName = _categories[indexPath.row];
  cell.textLabel.text = categoryName;

  if ([categoryName isEqualToString:self.selectedCategoryName]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedIndexPath = indexPath;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row != _selectedIndexPath.row) {
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;

    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:_selectedIndexPath];
    oldCell.accessoryType = UITableViewCellAccessoryNone;

    _selectedIndexPath = indexPath;
  }
}

@end
