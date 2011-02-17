//
//  StationDetailMeteoViewController.m
//  WindMobile
//
//  Created by Stefan Hochuli Paychère on 15.02.11.
//  Copyright 2011 Pistache Software. All rights reserved.
//

#import "StationDetailMeteoViewController.h"
#import "StationInfo.h"
#import "StationData.h"
#import "WindMobileHelper.h"
#import "iPadHelper.h"
#import "MapViewController.h"
#import "WindTrendChartViewController.h"
#import "WindPlotController.h"

#define DegreeToRadian(x) ((x) * M_PI / 180.0f)

@implementation StationDetailMeteoViewController
@synthesize stationInfo;
@synthesize stationData;
//@synthesize stationName;
@synthesize lastUpdated;
@synthesize altitude;
@synthesize windAverage;
@synthesize windMax;
@synthesize windDirectionArrow;
@synthesize windHistoryMin;
@synthesize windHistoryAverage;
@synthesize windHistoryMax;
@synthesize airTemperature;
@synthesize airHumidity;
@synthesize windTrendContainer;
@synthesize windTrendCtrl;
@synthesize graphView;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	
	// Update main info
	self.title = stationInfo.name;
	self.altitude.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"ALTITUDE_FORMAT", 
																			   @"WindMobile", nil),
						  self.stationInfo.altitude];
	
	// Invalidate all values
	NSString* NA = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	self.lastUpdated.text = NA;
	self.windAverage.text = NA;
	self.windMax.text = NA;
	self.windHistoryMin.text = NA;
	self.windHistoryMax.text = NA;
	self.windHistoryAverage.text = NA;
	self.airTemperature.text = NA;
	self.airHumidity.text = NA;
	
	// Insert wind trend chart
	windTrendCtrl = [[WindTrendChartViewController alloc] initWithNibName:@"WindTrendChartViewController" bundle:nil];
	//windTrend.view.bounds = self.windTrendContainer.frame;
	windTrendCtrl.view.frame = self.windTrendContainer.bounds;
	[self.windTrendContainer addSubview:windTrendCtrl.view];
	
	// load content
	[self refreshContent:self];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration {
	// Prepare for rotation
	if([iPadHelper isIpad]){} else {
		WindPlotController *graph ;
		switch(toInterfaceOrientation){
			case UIInterfaceOrientationLandscapeLeft:
			case UIInterfaceOrientationLandscapeRight:
				graph = [[WindPlotController alloc] initWithNibName:@"WindPlotController" bundle:nil];
				graph.stationInfo = self.stationInfo;
				graph.drawAxisSet = YES;
				graph.isInCell = NO;
				
				// display view
				graph.view.frame = self.view.bounds;
				self.graphView = graph.view; // save for future reference
				[self.view addSubview:graph.view];
				break;
			case UIInterfaceOrientationPortrait:
			case UIInterfaceOrientationPortraitUpsideDown:
				[self.graphView removeFromSuperview];
				break;
		}
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	// reset proper views	
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Station Details methods

- (IBAction)refreshContent:(id)sender {
	//[self.tableView reloadData];
	
	[self startRefreshAnimation];
	
	if(client == nil){
		client = [[[WMReSTClient alloc] init ]retain];
	}
	
	// (re-)load content
	[client asyncGetStationData:self.stationInfo.stationID forSender:self];
}

- (void)stationData:(StationData*)aStationData{
	[self stopRefreshAnimation];
	
	self.stationData = aStationData;
	windTrendCtrl.windData = aStationData.windDirection;
	
	// refresh data
	self.lastUpdated.text = self.stationData.lastUpdate;
	switch (self.stationData.statusEnum) {
		case StationDataStatusRed:
			self.lastUpdated.textColor = [UIColor redColor];
			break;
		case StationDataStatusOrange:
			self.lastUpdated.textColor = [UIColor orangeColor];
			break;
		default:
			self.lastUpdated.textColor = [UIColor whiteColor];
			break;
	}
	
	if(self.stationData.windAverage != nil){
		self.windAverage.text = self.stationData.windAverage;
	} else {
		self.windAverage.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	if(self.stationData.windMax != nil){
		self.windMax.text = self.stationData.windMax;
	} else {
		self.windMax.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	if(self.stationData.windTrend != nil){
		float direction = [self.stationData.windTrend floatValue];
		CGAffineTransform xform = CGAffineTransformMakeRotation(DegreeToRadian(direction));
		//NSLog(@"Direction: %f", direction);
		self.windDirectionArrow.transform = xform;
	}
	
	if(self.stationData.windHistoryMin != nil){
		self.windHistoryMin.text = self.stationData.windHistoryMin;
	} else {
		self.windHistoryMin.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	if(self.stationData.windHistoryMax != nil){
		self.windHistoryMax.text = self.stationData.windHistoryMax;
	} else {
		self.windHistoryMax.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	if(self.stationData.windHistoryAverage != nil){
		self.windHistoryAverage.text = self.stationData.windHistoryAverage;
	} else {
		self.windHistoryAverage.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	if(self.stationData.airTemperature != nil){
		self.airTemperature.text = self.stationData.airTemperature;
	} else {
		self.airTemperature.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	if(self.stationData.airHumidity != nil){
		self.airHumidity.text = self.stationData.airHumidity;
	} else {
		self.airHumidity.text = NSLocalizedStringFromTable(@"NOT_AVAILABLE", @"WindMobile", nil);
	}
	
	
	[self.view setNeedsDisplay];
}

- (void)requestError:(NSString*) message details:(NSMutableDictionary *)error{
	[self stopRefreshAnimation];
}

- (void)startRefreshAnimation{
	// Remove refresh button
	self.navigationItem.rightBarButtonItem = nil;
	
	// activity indicator
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
	[activityIndicator startAnimating];
	UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[activityIndicator release];
	self.navigationItem.rightBarButtonItem = activityItem;
}

- (void)stopRefreshAnimation{
	// Stop animation
	self.navigationItem.rightBarButtonItem = nil;
	
	// Put Refresh button on the top left
	//if([iPadHelper isIpad]){} else {
	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																				 target:self 
																				 action:@selector(refreshContent:)];
	self.navigationItem.rightBarButtonItem = refreshItem;
	//}
	
	// Map button
	if([iPadHelper isIpad]){
		UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																					 target:self 
																					 action:@selector(refreshContent:)];
		self.navigationItem.rightBarButtonItem = refreshItem;
	} else { // iPhone
		UIBarButtonItem *showActionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																						  target:self 
																						  action:@selector(showActionSheet:)];
		self.navigationItem.rightBarButtonItem = showActionButton;
	}
}

- (IBAction)showMap:(id)sender{
	if([iPadHelper isIpad] == NO){
		MapViewController *mapVC = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
		// push controller
		[self.navigationController pushViewController:mapVC animated:YES];
		if(self.stationInfo != nil){
			[mapVC addAnnotation:self.stationInfo];
		}
	}
	
}

- (IBAction)showActionSheet:(id)sender{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self 
													cancelButtonTitle:NSLocalizedStringFromTable(@"CANCEL", @"WindMobile", nil)
											   destructiveButtonTitle:nil 
													otherButtonTitles:NSLocalizedStringFromTable(@"SHOW_IN_MAPS", @"WindMobile",nil),
								  NSLocalizedStringFromTable(@"REFRESH", @"WindMobile",nil),
								  nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showFromTabBar:self.tabBarController.tabBar];
	[actionSheet release];
	
}

#pragma mark -
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 0:
			[self showMap:self];
			break;
		case 1:
			[self refreshContent:self];
			break;
		default:
			break;
	}
}

@end