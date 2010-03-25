//
//  DSUploadWithSCP.m
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import "DSAutomatorHelper.h"
#import "DSSCP.h"
#import "DSUploadWithSCP.h"

@implementation DSUploadWithSCP

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo {

	// get parameters from interface
	NSMutableDictionary *parameters = [self parameters];
	NSString *scpServer = [parameters objectForKey:@"scpServer"];
	NSString *scpUserName = [parameters objectForKey:@"scpUserName"];
	NSString *scpDestinationPath = [parameters objectForKey:@"scpDestinationPath"];
	NSString *scpOtherOptions = [parameters objectForKey:@"scpOtherOptions"];
	NSNumber *scpPreserveTimes = [parameters objectForKey:@"scpPreserveTimes"];
	NSNumber *scpPreserveExtended = [parameters objectForKey:@"scpPreserveExtended"];
	
	// construct options
	NSMutableArray *options = [NSMutableArray arrayWithCapacity:2];
	[options addObject:@"-B"];
	[options addObject:@"-r"];
	if ((scpPreserveTimes != nil) && [scpPreserveTimes intValue]) [options addObject:@"-p"];
	if ((scpPreserveExtended != nil) && [scpPreserveExtended intValue]) [options addObject:@"-E"];
	if ((scpOtherOptions != nil) && ![scpOtherOptions isEqualToString:@""]) {
		[options addObjectsFromArray:[[scpOtherOptions stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "]];
	}

	// copy the files
	NSString *cmdError;
	NSDictionary *cmdLog;
	BOOL result = [DSSCP uploadTo:scpServer
						 username:scpUserName
						  options:options
						filenames:input
				  destinationPath:scpDestinationPath
						scpBinary:nil
					 errorMessage:&cmdError
							  log:&cmdLog];
	
	// handle errors
	if (result == NO) {
		*errorInfo = [DSAutomatorHelper constructAutomatorError:cmdError];
		NSLog(@"Upload with scp v%@ (revision %@) error.\nError message: %@\nCommand: \n\t%@\n\t%@\nReturn status: %@\nOutput: %@", 
			  kDSUploadWithSCPVersion,
			  kDSUploadWithSCPSVNRevision,
			  cmdError,
			  [cmdLog valueForKey:@"command"], 
			  [[cmdLog valueForKey:@"arguments"] componentsJoinedByString:@"\n\t"], 
			  [cmdLog valueForKey:@"status"], 
			  [cmdLog valueForKey:@"stderr"]);
		return nil;
	}
	
	return input;
}

- (IBAction)checkForNewVersionSelector:(id)sender {

	[DSAutomatorHelper checkForNewVersion:@"Upload with scp"
					 currentVersionString:kDSUploadWithSCPVersion 
									  url:[NSURL URLWithString:kDSUploadWithSCPVersionCheckURL] 
				 checkForNewVersionButton:checkForNewVersionButton
				 downloadNewVersionButton:downloadNewVersionButton
						noNewVersionLabel:noNewVersionLabel
				 failCheckNewVersionLabel:failCheckNewVersionLabel
	 ];
	 
}

@end