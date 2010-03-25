//
//  DSSCP.m
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import "DSSCP.h"

@implementation DSSCP

+ (BOOL)uploadTo:(NSString *)server
		username:(NSString *)username
		 options:(NSArray *)options
	   filenames:(NSArray *)filenames
 destinationPath:(NSString *)destinationPath 
	   scpBinary:(NSString *)scpBinary
	errorMessage:(NSString **)errorMessage
			 log:(NSDictionary **)log {
	
	BOOL retValue = NO;
	NSTask *task = [[NSTask alloc] init];
	NSPipe *stdErr = [[NSPipe alloc] init];

	*log = [NSMutableDictionary dictionaryWithCapacity:4];
	[*log setValue:nil forKey:@"command"];
	[*log setValue:nil forKey:@"arguments"];
	[*log setValue:nil forKey:@"status"];
	[*log setValue:nil forKey:@"stderr"];
	
	// set the scp binary
	if (scpBinary != nil) {
		scpBinary = [scpBinary stringByExpandingTildeInPath];
		[*log setValue:scpBinary forKey:@"command"];
		NSFileManager *localFileManager = [NSFileManager defaultManager];
		if (![localFileManager fileExistsAtPath:scpBinary] || ![localFileManager isExecutableFileAtPath:scpBinary]) {
			*errorMessage = @"Invalid scp binary specified.";
			retValue = NO;
			goto cleanup;
		}
		[task setLaunchPath:scpBinary];
	} else {
		[*log setValue:@"/usr/bin/scp" forKey:@"command"];
		[task setLaunchPath:@"/usr/bin/scp"];
	}
	
	// construct arguments
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:2];

	// add options
	if (options != nil) [args addObjectsFromArray:options];

	// add filenames
	if ((filenames == nil) || ![filenames count]) {
		*errorMessage = @"No filenames specified.";
		retValue = NO;
		goto cleanup;
	}
	[args addObjectsFromArray:filenames];
	
	// construct destination
	NSMutableArray *destination = [NSMutableArray arrayWithCapacity:2];
	if ((username != nil) && ![username isEqualToString:@""]) {
		[destination addObject:username];
		[destination addObject:@"@"];
	}
	if ((server == nil) || [server isEqualToString:@""]) {
		*errorMessage = @"No server name specified.";
		retValue = NO;
		goto cleanup;
	}
	[destination addObject:server];
	[destination addObject:@":"];
	if ((destinationPath != nil) && ![destinationPath isEqualToString:@""]) {
		[destination addObject:[destinationPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];
	}
	[args addObject:[destination componentsJoinedByString:@""]];
	
	// set arguments
	[task setArguments:args];
	[*log setValue:args forKey:@"arguments"];
	
	// set file handler for standard error
	NSFileHandle *stdErrWrite = [stdErr fileHandleForWriting];
	[task setStandardError:stdErrWrite];
	
	// run the task
	[task launch];
	[task waitUntilExit];
	[stdErrWrite closeFile];
	
	// get status
	int status = [task terminationStatus];
	[*log setValue:[NSNumber numberWithInt:status] forKey:@"status"];
	
	// handle errors
	if (status != 0) {
		NSFileHandle *stdErrRead = [stdErr fileHandleForReading];
		NSString *errorString = [[NSString alloc] initWithData:[stdErrRead availableData] encoding:NSASCIIStringEncoding];
		[*log setValue:[NSString stringWithString:errorString] forKey:@"stderr"];
		if ([errorString rangeOfString:@"illegal option -- E"].location != NSNotFound) {
			*errorMessage = @"The server does not supported extended Mac OS X attributes.";
		} else if ([errorString rangeOfString:@"Permission denied"].location != NSNotFound) {
			*errorMessage = @"Could not authenticate to the server. You may need to set up SSH public key authentication.";
		} else if ([errorString rangeOfString:@"WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"].location != NSNotFound) {
			*errorMessage = @"The server's public key has changed. This may indicate an attack! Please contact your system administrator.";
		} else if ([errorString rangeOfString:@"Host key verification failed."].location != NSNotFound) {
			*errorMessage = @"Could not verify the server's public key. It may not be a site you have logged in to before.";
		} else {
			*errorMessage = @"An unknown error occurred.";
		}
		[errorString release];
		retValue = NO;
		goto cleanup;
	}
	
	*errorMessage = nil;
	retValue = YES;
	
  cleanup:
	[task release];
	[stdErr release];
	return retValue;
	
}

@end