//
//  JJCloudTouchJSONParser.h
//  CloudEngineTest
//
//  Created by Joshua Johnson on 5/28/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JJCloudParserDelegate.h"
#import "JJCloudEngineDelegate.h"

@interface JJCloudTouchJSONParser : NSObject {
	__weak NSObject<JJCloudParserDelegate> *delegate;
	NSString *identifier;
	JJCloudRequestType requestType;
	JJCloudResponseType responseType;
	NSURL *URL;
	NSData *json;
	NSMutableArray *parsedObjects;
}

+ (id)parserWithJSON:(NSData *)theJSON
			delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)theIdentifier
		 requestType:(JJCloudRequestType)theRequestType
		responseType:(JJCloudResponseType)theResponseType
				 URL:(NSURL *)theUrl;

- (id)initWithJSON:(NSData *)theJSON
			delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)theIdentifier
		 requestType:(JJCloudRequestType)theRequestType
		responseType:(JJCloudResponseType)theResponseType
				 URL:(NSURL *)theUrl;

- (BOOL) _isValidDelegateForSelector:(SEL)selector;
- (void)_parsingDidEnd;
- (void)_parsingErrorOccurred:(NSError *)parseError;
- (void)_parsedObject:(NSDictionary *)dictionary;

@end
