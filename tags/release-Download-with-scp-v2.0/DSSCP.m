//
//  DSSCP.m
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import "DSSCP.h"

@implementation DSSCP

+ (NSString *)checkSCPBinary:(NSString *)scpBinary {
	if (scpBinary != nil) {
		scpBinary = [scpBinary stringByExpandingTildeInPath];
		NSFileManager *localFileManager = [NSFileManager defaultManager];
		if (![localFileManager fileExistsAtPath:scpBinary] || ![localFileManager isExecutableFileAtPath:scpBinary]) {
			return nil;
		}
		return scpBinary;
	} else {
		return @"/usr/bin/scp";
	}
}

+ (void)parseStdErr:(NSPipe *)stdErr errorString:(NSString **)errorString errorMessage:(NSString **)errorMessage {
	NSFileHandle *stdErrRead = [stdErr fileHandleForReading];
	*errorString = [[NSString alloc] initWithData:[stdErrRead availableData] encoding:NSASCIIStringEncoding];
	if ([*errorString rangeOfString:@"illegal option -- E"].location != NSNotFound) {
		*errorMessage = @"The server does not supported extended Mac OS X attributes.";
	} else if ([*errorString rangeOfString:@"Permission denied"].location != NSNotFound) {
		*errorMessage = @"Could not authenticate to the server. You may need to set up SSH public key authentication.";
	} else if ([*errorString rangeOfString:@"WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"].location != NSNotFound) {
		*errorMessage = @"The server's public key has changed. This may indicate an attack! Please contact your system administrator.";
	} else if ([*errorString rangeOfString:@"Host key verification failed."].location != NSNotFound) {
		*errorMessage = @"Could not verify the server's public key. It may not be a site you have logged in to before.";
	} else {
		*errorMessage = @"An unknown error occurred.";
	}
}

+ (BOOL)downloadFrom:(NSString *)server
			username:(NSString *)username
			 options:(NSArray *)options
		 sourcePaths:(NSArray *)sourcePaths
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
	scpBinary = [DSSCP checkSCPBinary:scpBinary];
	if (scpBinary == nil) {
		*errorMessage = @"Invalid scp binary specified.";
		retValue = NO;
		goto cleanup;
	} else {
		[*log setValue:scpBinary forKey:@"command"];
		[task setLaunchPath:scpBinary];
	}
	
	// construct arguments
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:2];
	
	// add options
	if (options != nil) [args addObjectsFromArray:options];
	
	// construct source base
	if ((server == nil) || [server isEqualToString:@""]) {
		*errorMessage = @"No server name specified.";
		retValue = NO;
		goto cleanup;
	}
	NSString *sourceBase;
	if ((username != nil) && ![username isEqualToString:@""]) {
		sourceBase = [NSString stringWithFormat:@"%@@%@", username, server];
	} else {
		sourceBase = [NSString stringWithFormat:@"%@", server];
	}
	
	// construct sources
	if ([sourcePaths count] < 1) {
		*errorMessage = @"No source paths specified.";
		retValue = NO;
		goto cleanup;
	}
	NSMutableArray *sources = [NSMutableArray arrayWithCapacity:[sourcePaths count]];
	NSEnumerator *enumerator = [sourcePaths objectEnumerator];
	NSString *sourcePath;
	while (sourcePath = [enumerator nextObject]) {
		if ((sourcePath != nil) && ![sourcePath isEqualToString:@""]) {
			[sources addObject:[NSString stringWithFormat:@"%@:%@", 
								sourceBase, 
								[sourcePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
		}
	}
	
	// set sources
	[args addObjectsFromArray:sources];
	
	// set destination
	[args addObject:destinationPath];
	
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
		NSString *errorString;
		[DSSCP parseStdErr:stdErr errorString:&errorString errorMessage:errorMessage];
		[*log setValue:errorString forKey:@"stderr"];
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
	scpBinary = [DSSCP checkSCPBinary:scpBinary];
	if (scpBinary == nil) {
		*errorMessage = @"Invalid scp binary specified.";
		retValue = NO;
		goto cleanup;
	} else {
		[*log setValue:scpBinary forKey:@"command"];
		[task setLaunchPath:scpBinary];
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
		NSString *errorString;
		[DSSCP parseStdErr:stdErr errorString:&errorString errorMessage:errorMessage];
		[*log setValue:errorString forKey:@"stderr"];
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