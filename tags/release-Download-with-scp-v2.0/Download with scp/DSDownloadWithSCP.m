//
//  DSDownloadWithSCP.m
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#import "DSAutomatorHelper.h"
#import "DSSCP.h"
#import "DSDownloadWithSCP.h"

@implementation DSDownloadWithSCP

- (void)opened {
	[sourcePathsTokenField setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	temporaryFoldersCreated = [NSMutableArray arrayWithCapacity:1];
	[super opened];
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo {

	NSMutableArray *output = [NSMutableArray arrayWithArray:input];

	// get parameters from interface
	NSMutableDictionary *parameters = [self parameters];
	NSString *scpServer = [parameters objectForKey:@"scpServer"];
	NSString *scpUserName = [parameters objectForKey:@"scpUserName"];
	NSArray *scpSourcePaths = [parameters objectForKey:@"scpSourcePaths"];
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
	
	// construct temporary folder for destination path
	NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ca.crazycode.automator.scp.DownloadWithSCP.tmp.XXXXXX"];
	const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	char *mkdtempResult = mkdtemp(tempDirectoryNameCString);
	if (!mkdtempResult) {
		*errorInfo = [DSAutomatorHelper constructAutomatorError:@"Error creating temporary directory."];
		return nil;
	}	
	NSString *destinationPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString
																							length:strlen(mkdtempResult)];
	free(tempDirectoryNameCString);
	[temporaryFoldersCreated addObject:destinationPath];
	
	// copy the files
	NSString *cmdError;
	NSDictionary *cmdLog;
	BOOL result = [DSSCP downloadFrom:scpServer
							 username:scpUserName
							  options:options
						  sourcePaths:scpSourcePaths
					  destinationPath:destinationPath
							scpBinary:nil
						 errorMessage:&cmdError
								  log:&cmdLog];
	
	// handle errors
	if (result == NO) {
		*errorInfo = [DSAutomatorHelper constructAutomatorError:cmdError];
		NSLog(@"Download with scp v%@ (r%@) error.\nError message: %@\nCommand: \n\t%@\n\t%@\nReturn status: %@\nOutput: %@", 
			  kDSDownloadWithSCPVersion,
			  kDSDownloadWithSCPSVNRevision,
			  cmdError,
			  [cmdLog valueForKey:@"command"], 
			  [[cmdLog valueForKey:@"arguments"] componentsJoinedByString:@"\n\t"], 
			  [cmdLog valueForKey:@"status"], 
			  [cmdLog valueForKey:@"stderr"]);
		return nil;
	}
	
	// add downloaded files to output
	NSEnumerator *downloadedEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:destinationPath];
	NSString *downloadedFile;
	while (downloadedFile = [downloadedEnumerator nextObject]) {
		[output addObject:[destinationPath stringByAppendingPathComponent:downloadedFile]];
	}
	
	return output;
	
}

- (IBAction)checkForNewVersionSelector:(id)sender {

	[DSAutomatorHelper checkForNewVersion:@"Download with scp"
					 currentVersionString:kDSDownloadWithSCPVersion 
									  url:[NSURL URLWithString:kDSDownloadWithSCPVersionCheckURL] 
				 checkForNewVersionButton:checkForNewVersionButton
				 downloadNewVersionButton:downloadNewVersionButton
						noNewVersionLabel:noNewVersionLabel
				 failCheckNewVersionLabel:failCheckNewVersionLabel
	 ];
	 
}

- (void)closed {
	
	// clean any temporary directories created, if they're empty
	// if they're not empty, maybe the user has a reason for keeping the files around; 
	// at worst they'll hang around until the system cleans up the temporary files directory
	if (temporaryFoldersCreated != nil) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSEnumerator *enumerator = [temporaryFoldersCreated objectEnumerator];
		NSString *tmpDir;
		NSArray *tmpDirContents;
		BOOL isDir;
		while (tmpDir = [enumerator nextObject]) {
			if ([fileManager fileExistsAtPath:tmpDir isDirectory:&isDir] && isDir) {
				tmpDirContents = [fileManager contentsOfDirectoryAtPath:tmpDir error:NULL];
				if (tmpDirContents == nil) continue;
				if ([tmpDirContents count] == 0) {
					[fileManager removeItemAtPath:tmpDir error:NULL];
				}
			}
		}
		temporaryFoldersCreated = nil;
	}
	
}

@end