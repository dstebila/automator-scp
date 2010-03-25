//
//  DSUploadWithSCP.h
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>
#import "DSUploadWithSCP_version.h"

#define kDSUploadWithSCPVersionCheckURL @"http://automator-scp.googlecode.com/files/Upload%20with%20scp%20latest%20version.txt"

@interface DSUploadWithSCP : AMBundleAction {
	IBOutlet NSButton* checkForNewVersionButton;
	IBOutlet NSButton* downloadNewVersionButton;
	IBOutlet NSTextField* noNewVersionLabel;
	IBOutlet NSTextField* failCheckNewVersionLabel;
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

- (IBAction)checkForNewVersionSelector:(id)sender;

@end