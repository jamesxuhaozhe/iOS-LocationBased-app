//
//  LocationDetailsViewController.m
//  MyLocations
//
//  Created by Matthijs on 11-10-13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import "LocationDetailsViewController.h"
#import "CategoryPickerViewController.h"
#import "HudView.h"

@interface LocationDetailsViewController () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *latitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *longitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@end

@implementation LocationDetailsViewController
{
  NSString *_descriptionText;
  NSString *_categoryName;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    _descriptionText = @"";
    _categoryName = @"No Category";
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.descriptionTextView.text = _descriptionText;
  self.categoryLabel.text = _categoryName;

  self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", self.coordinate.latitude];
  self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", self.coordinate.longitude];

  if (self.placemark != nil) {
    self.addressLabel.text = [self stringFromPlacemark:self.placemark];
  } else {
    self.addressLabel.text = @"No Address Found";
  }

  self.dateLabel.text = [self formatDate:[NSDate date]];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
}

- (void)hideKeyboard:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (indexPath != nil && indexPath.section == 0 && indexPath.row) {
        return;
    }
    
    [self.descriptionTextView resignFirstResponder];
}

- (NSString *)stringFromPlacemark:(CLPlacemark *)placemark
{
  return [NSString stringWithFormat:@"%@ %@, %@, %@ %@, %@",
    placemark.subThoroughfare, placemark.thoroughfare,
    placemark.locality, placemark.administrativeArea,
    placemark.postalCode, placemark.country];
}

- (NSString *)formatDate:(NSDate *)theDate
{
  static NSDateFormatter *formatter = nil;
  if (formatter == nil) {
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
  }

  return [formatter stringFromDate:theDate];
}

- (IBAction)done:(id)sender
{
  NSLog(@"Description '%@'", _descriptionText);
    HudView *hudView = [HudView hudInView:self.navigationController.view animated: YES];
    hudView.text = @"Tagged";

    [self performSelector:@selector(closeScreen) withObject:nil
               afterDelay:0.6];
}

- (IBAction)cancel:(id)sender
{
  [self closeScreen];
}

- (void)closeScreen
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"PickCategory"]) {
    CategoryPickerViewController *controller = segue.destinationViewController;
    controller.selectedCategoryName = _categoryName;
  }
}

- (IBAction)categoryPickerDidPickCategory:(UIStoryboardSegue *)segue
{
  CategoryPickerViewController *viewController = segue.sourceViewController;
  _categoryName = viewController.selectedCategoryName;
  self.categoryLabel.text = _categoryName;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 0 && indexPath.row == 0) {
    return 88;
  } else if (indexPath.section == 2 && indexPath.row == 2) {

    // UILabels can display their content in multiple rows but this takes
    // some trickery. We first say to the label: this is your width, now
    // try to fit all the text in there (sizeToFit). This resizes both the
    // label's width and height.

    CGRect rect = CGRectMake(100, 10, 205, 10000);
    self.addressLabel.frame = rect;
    [self.addressLabel sizeToFit];

    // We want the width to remain at 205 points, so we resize the label
    // afterwards to the proper dimensions.
    rect.size.height = self.addressLabel.frame.size.height;
    self.addressLabel.frame = rect;

    return self.addressLabel.frame.size.height + 20;
  } else {
    return 44;
  }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1) {
        return indexPath;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self.descriptionTextView becomeFirstResponder];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)theTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  _descriptionText = [theTextView.text stringByReplacingCharactersInRange:range withString:text];
  return YES;
}

- (void)textViewDidEndEditing:(UITextView *)theTextView
{
  _descriptionText = theTextView.text;
}



@end
