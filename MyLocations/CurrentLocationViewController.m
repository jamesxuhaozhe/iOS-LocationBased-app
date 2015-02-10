//
//  FirstViewController.m
//  MyLocations
//
//  Created by Matthijs on 08-10-13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import "CurrentLocationViewController.h"
#import "LocationDetailsViewController.h"

@interface CurrentLocationViewController ()

@end

@implementation CurrentLocationViewController
{
  CLLocationManager *_locationManager;
  CLLocation *_location;
  
  BOOL _updatingLocation;
  NSError *_lastLocationError;
  
  CLGeocoder *_geocoder;
  CLPlacemark *_placemark;
  BOOL _performingReverseGeocoding;
  NSError *_lastGeocodingError;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    _locationManager = [[CLLocationManager alloc] init];
    _geocoder = [[CLGeocoder alloc] init];

    // For testing. Uncomment this line to use any location you want,
    // without having to use the Simulator's Location menu.
    //_location = [[CLLocation alloc] initWithLatitude:37.785834 longitude:-122.406417];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self updateLabels];
  [self configureGetButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getLocation:(id)sender
{
  if (_updatingLocation) {
    [self stopLocationManager];
  } else {
    _location = nil;
    _lastLocationError = nil;
    _placemark = nil;
    _lastGeocodingError = nil;

    [self startLocationManager];
  }

  [self updateLabels];
  [self configureGetButton];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"TagLocation"]) {
    UINavigationController *navigationController = segue.destinationViewController;
    LocationDetailsViewController *controller = (LocationDetailsViewController *)navigationController.topViewController;
    controller.coordinate = _location.coordinate;
    controller.placemark = _placemark;
      controller.managedObjectContext = self.managedObjectContext;
  }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  NSLog(@"didFailWithError %@", error);

  // The kCLErrorLocationUnknown error means the location manager was unable
  // to obtain a location right now. We will keep trying until we do find a
  // location or receive a more serious error.
  if (error.code == kCLErrorLocationUnknown) {
    return;
  }

  [self stopLocationManager];
  _lastLocationError = error;

  [self updateLabels];
  [self configureGetButton];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  CLLocation *newLocation = [locations lastObject];

  NSLog(@"didUpdateLocations %@", newLocation);

  // If the time at which the new location object was determined is too long
  // ago (5 seconds in this case), then this is a cached result. We'll ignore
  // these cached locations because they may be out of date.
  if ([newLocation.timestamp timeIntervalSinceNow] < -5.0) {
    return;
  }

  // Ignore invalid measurements.
  if (newLocation.horizontalAccuracy < 0) {
    return;
  }

  // Calculate the distance between the new reading and the old one. If this
  // is the first reading then there is no previous location to compare to
  // and we set the distance to a very large number (MAXFLOAT).
  CLLocationDistance distance = MAXFLOAT;
  if (_location != nil) {
    distance = [newLocation distanceFromLocation:_location];
  }

  // Only perform the following code if the new location provides a more
  // precise reading than the previous one, or if it's the very first.
  if (_location == nil || _location.horizontalAccuracy > newLocation.horizontalAccuracy) {

    // Put the new coordinates on the screen.
    _lastLocationError = nil;
    _location = newLocation;
    [self updateLabels];

    // We're done if the new location is accurate enough.
    if (newLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) {
      NSLog(@"*** We're done!");
      [self stopLocationManager];
      [self configureGetButton];

      // We'll force a reverse geocoding for this final result if we
      // haven't already done this location.
      if (distance > 0) {
        _performingReverseGeocoding = NO;
      }
    }

    // We're not supposed to perform more than one reverse geocoding
    // request at once, so only continue if we're not already busy.
    if (!_performingReverseGeocoding) {
      NSLog(@"*** Going to geocode");

      // Start a new reverse geocoding request and update the screen
      // with the results (a new placemark or error message).
      _performingReverseGeocoding = YES;
      [_geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"*** Found placemarks: %@, error: %@", placemarks, error);

        _lastGeocodingError = error;
        if (error == nil && [placemarks count] > 0) {
          _placemark = [placemarks lastObject];
        } else {
          _placemark = nil;
        }

        _performingReverseGeocoding = NO;
        [self updateLabels];
      }];
    }

  // If the distance did not change significantly since last time and it has
  // been a while since we've received the previous reading (10 seconds) then
  // assume this is the best it's going to be and stop fetching the location.
  } else if (distance < 1.0) {
    NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:_location.timestamp];
    if (timeInterval > 10) {
      NSLog(@"*** Force done!");
      [self stopLocationManager];
      [self updateLabels];
      [self configureGetButton];
    }
  }
}

- (NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark
{
  return [NSString stringWithFormat:@"%@ %@\n%@ %@ %@",
    thePlacemark.subThoroughfare, thePlacemark.thoroughfare,
    thePlacemark.locality, thePlacemark.administrativeArea,
    thePlacemark.postalCode];
}

- (void)updateLabels
{
  // If we have a location object then we will always show its coordinates,
  // even if we're still fetching a more accurate location at the same time.
  if (_location != nil) {
    self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", _location.coordinate.latitude];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", _location.coordinate.longitude];
    self.tagButton.hidden = NO;
    self.messageLabel.text = @"";

    // Once we have a location, we try to reverse geocode it and show the
    // results in the address label.
    if (_placemark != nil) {
      self.addressLabel.text = [self stringFromPlacemark:_placemark];
    } else if (_performingReverseGeocoding) {
      self.addressLabel.text = @"Searching for Address...";
    } else if (_lastGeocodingError != nil) {
      self.addressLabel.text = @"Error Finding Address";
    } else {
      self.addressLabel.text = @"No Address Found";
    }

  // If we have no location yet, then we're either waiting for the user to
  // press the button to start, still get our first location fix, or we ran
  // into an error situation.
  } else {
    self.latitudeLabel.text = @"";
    self.longitudeLabel.text = @"";
    self.addressLabel.text = @"";
    self.tagButton.hidden = YES;

    NSString *statusMessage;
    if (_lastLocationError != nil) {
      if ([_lastLocationError.domain isEqualToString:kCLErrorDomain] && _lastLocationError.code == kCLErrorDenied) {
        statusMessage = @"Location Services Disabled";
      } else {
        statusMessage = @"Error Getting Location";
      }
    } else if (![CLLocationManager locationServicesEnabled]) {
      statusMessage = @"Location Services Disabled";
    } else if (_updatingLocation) {
      statusMessage = @"Searching...";
    } else {
      statusMessage = @"Press the Button to Start";
    }

    self.messageLabel.text = statusMessage;
  }
}

- (void)configureGetButton
{
  if (_updatingLocation) {
    [self.getButton setTitle:@"Stop" forState:UIControlStateNormal];
  } else {
    [self.getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
  }
}

- (void)startLocationManager
{
  if ([CLLocationManager locationServicesEnabled]) {

    // Tell the location manager to start fetching the location.
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [_locationManager startUpdatingLocation];
    _updatingLocation = YES;

    // Schedule the method didTimeOut: to be called one 1 minute from now.
    // If we haven't obtained a location by then, it's unlikely we ever
    // will and we'll show an error message to the user.
    [self performSelector:@selector(didTimeOut:) withObject:nil afterDelay:60];
  }
}

- (void)stopLocationManager
{
  if (_updatingLocation) {

    // Make sure the didTimeOut: method won't be called anymore.
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didTimeOut:) object:nil];

    // Tell the location manager we no longer want to receive updates.
    [_locationManager stopUpdatingLocation];
    _locationManager.delegate = nil;
    _updatingLocation = NO;
  }
}

- (void)didTimeOut:(id)obj
{
  NSLog(@"*** Time out");

  // We get here whether we've obtained a location or not. If there no
  // location was obtained by this time, then we stop the location manager
  // from giving us updates and we'll show an error message to the user.
  if (_location == nil) {
    [self stopLocationManager];

	// Create an NSError object so that the UI shows an error message.
    _lastLocationError = [NSError errorWithDomain:@"MyLocationsErrorDomain" code:1 userInfo:nil];

    [self updateLabels];
    [self configureGetButton];
  }
}

@end
