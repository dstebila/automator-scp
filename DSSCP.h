//
//  DSSCP.h
//  automator-scp project http://code.google.com/p/automator-scp/
//
//  Copyright (c) 2005-2010 Douglas Stebila http://www.douglas.stebila.ca/
//  All code is provided under the New BSD license.
//

#include <Cocoa/Cocoa.h>

@interface DSSCP : NSObject
{
}

+ (BOOL)downloadFrom:(NSString *)server
			username:(NSString *)username
			 options:(NSArray *)options
		 sourcePaths:(NSArray *)sourcePaths
	 destinationPath:(NSString *)destinationPath 
		   scpBinary:(NSString *)scpBinary
		errorMessage:(NSString **)errorMessage
				 log:(NSDictionary **)log;

+ (BOOL)uploadTo:(NSString *)server
		username:(NSString *)username
		 options:(NSArray *)options
	   filenames:(NSArray *)filenames
 destinationPath:(NSString *)destinationPath 
	   scpBinary:(NSString *)scpBinary
	errorMessage:(NSString **)errorMessage
			 log:(NSDictionary **)log;

@end
