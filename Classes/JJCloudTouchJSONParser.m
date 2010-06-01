//
//  JJCloudTouchJSONParser.m
//  CloudEngineTest
//
//  Created by Joshua Johnson on 5/28/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#import "JJCloudTouchJSONParser.h"
#import "CJSONDeserializer.h"

@implementation JJCloudTouchJSONParser

#pragma mark -
#pragma mark Memory

- (void)dealloc 
{
	[parsedObjects release];
	[json release];
	[identifier release];
	[URL release];
	
	delegate = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark constructors

+ (id)parserWithJSON:(NSData *)theJSON
			delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)theIdentifier
		 requestType:(JJCloudRequestType)theRequestType
		responseType:(JJCloudResponseType)theResponseType
				 URL:(NSURL *)theUrl;
{
	return [[[self alloc] initWithJSON:theJSON delegate:theDelegate connectionIdentifier:theIdentifier requestType:theRequestType responseType:theResponseType URL:theUrl] autorelease];
}


- (id)initWithJSON:(NSData *)theJSON
		  delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)theIdentifier
	   requestType:(JJCloudRequestType)theRequestType
	  responseType:(JJCloudResponseType)theResponseType
			   URL:(NSURL *)theUrl;
{
	if (self = [super init])
	{
		json = [theJSON retain];
		identifier = [theIdentifier retain];
		URL = [theUrl retain];
		requestType = theRequestType;
		responseType = theResponseType;
		delegate = theDelegate;
		parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];

		id results = [[CJSONDeserializer deserializer] deserialize:json error:nil];
		if ([results isKindOfClass:[NSArray class]])
		{
			for (NSDictionary *result in results)
			{
				[self _parsedObject:result];
			}
		}
		else 
		{
			[self _parsedObject:results];
		}
		
		[self _parsingDidEnd];
	}
	return self;
}

#pragma mark -
#pragma mark Delegate methods

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((delegate != nil) && [delegate respondsToSelector:selector]);
}

- (void)_parsingDidEnd;
{
	if ([self _isValidDelegateForSelector:@selector(parsingSucceededForRequest:ofResponseType:withParsedObjects:)])
		[delegate parsingSucceededForRequest:identifier ofResponseType:responseType withParsedObjects:parsedObjects];
}

- (void)_parsingErrorOccurred:(NSError *)parseError;
{
	if ([self _isValidDelegateForSelector:@selector(parsingFailedForRequest:ofResponseType:withError:)])
		[delegate parsingFailedForRequest:identifier ofResponseType:responseType withError:parseError];
}

- (void)_parsedObject:(NSDictionary *)dictionary;
{
	[parsedObjects addObject:dictionary];
	if ([self _isValidDelegateForSelector:@selector(parsedObject:forRequest:ofResponseType:)])
		[delegate parsedObject:dictionary forRequest:identifier ofResponseType:responseType];
}


@end
