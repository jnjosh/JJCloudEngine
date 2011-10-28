//
//  JJCloudParserDelegate.h
//  CloudEngineTest
//
//  Created by Joshua Johnson on 5/28/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#import "JJCloudEngineGlobals.h"

@protocol JJCloudParserDelegate

- (void)parsingSucceededForRequest:(NSString *)identifier
					ofResponseType:(JJCloudResponseType)responseType
				  withParsedObjects:(NSArray *)parsedObjects;

- (void)parsingFailedForRequest:(NSString *)identifier
				 ofResponseType:(JJCloudResponseType)responseType
					  withError:(NSError *)error;

- (void)parsedObject:(NSDictionary *)parsedObject
		  forRequest:(NSString *)identifier
	  ofResponseType:(JJCloudResponseType)responseType;

@end
