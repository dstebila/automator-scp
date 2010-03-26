//
//  DSAutomatorHelper.m
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import "DSAutomatorHelper.h"

@implementation DSAutomatorHelper

+ (NSDictionary *)constructAutomatorError:(NSString *)message {
	
	NSArray *objsArray = [NSArray arrayWithObjects:
						  [NSNumber numberWithInt:errOSAGeneralError], 
						  [NSString stringWithFormat:@"%@\n", message], 
						  nil];
	NSArray *keysArray = [NSArray arrayWithObjects:NSAppleScriptErrorNumber,
						  NSAppleScriptErrorMessage, nil];
	
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObjects:objsArray forKeys:keysArray];	
	return errorInfo;
	
}

+ (void)checkForNewVersion:(NSString *)product 
	  currentVersionString:(NSString *)currentVersionString
					   url:(NSURL *)url 
  checkForNewVersionButton:(NSButton *)checkForNewVersionButton
  downloadNewVersionButton:(NSButton *)downloadNewVersionButton
		 noNewVersionLabel:(NSTextField *)noNewVersionLabel
  failCheckNewVersionLabel:(NSTextField *)failCheckNewVersionLabel {

	// hide the check buttom
	[checkForNewVersionButton setTransparent:YES];
	[checkForNewVersionButton setEnabled:NO];
	
	// download the file listing the newest version
	NSError *downloadError;
	NSString *newVersionString = [NSString stringWithContentsOfURL:url
														  encoding:NSASCIIStringEncoding 
															 error:&downloadError];
	
	if (newVersionString == nil) {
		[failCheckNewVersionLabel setHidden:NO];
		NSLog(@"%@: error downloading version information: %@", product, [downloadError localizedDescription]);
	} else {
		// compute the current version
		NSScanner *currentVersionScanner = [NSScanner scannerWithString:currentVersionString];
		double currentVersion = 0.0;
		if (![currentVersionScanner scanDouble:&currentVersion]) {
			[failCheckNewVersionLabel setHidden:NO];
			NSLog(@"%@: error scanning current version string", product);
			return;
		}
		// compute the newest version
		NSScanner *newVersionScanner = [NSScanner scannerWithString:newVersionString];
		double newVersion;
		if (![newVersionScanner scanDouble:&newVersion]) {
			[failCheckNewVersionLabel setHidden:NO];
			NSLog(@"%@: error scanning new version string", product);
			return;
		}
		// display result
		if (newVersion > currentVersion) {
			[downloadNewVersionButton setEnabled:YES];
			[downloadNewVersionButton setHidden:NO];
		} else {
			[noNewVersionLabel setHidden:NO];
		}
	}

}

@end
