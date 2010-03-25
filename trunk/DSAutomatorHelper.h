//
//  DSAutomatorHelper.h
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>

@interface DSAutomatorHelper : NSObject {
}

+ (NSDictionary *)constructAutomatorError:(NSString *)message;

+ (void)checkForNewVersion:(NSString *)product 
	  currentVersionString:(NSString *)currentVersionString
					   url:(NSURL *)url 
  checkForNewVersionButton:(NSButton *)checkForNewVersionButton
  downloadNewVersionButton:(NSButton *)downloadNewVersionButton
		 noNewVersionLabel:(NSTextField *)noNewVersionLabel
  failCheckNewVersionLabel:(NSTextField *)failCheckNewVersionLabel;

@end
