//
//  JJCloudEngineHTTPURLConnection.m
//
//  Created by Joshua Johnson on 5/26/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#import "JJCloudEngineHTTPURLConnection.h"
#import "NSString+UUID.h"

@implementation JJCloudEngineHTTPURLConnection

#pragma mark -
#pragma mark memory

- (void)dealloc 
{
	[_data release];
	[_identifier release];
	[_url release];
	[userData release];
	[super dealloc];
}

#pragma mark -
#pragma mark constructors

- (id)initWithRequest:(NSURLRequest *)request 
			 delegate:(id)delegate 
		  requestType:(JJCloudRequestType)newRequestType 
		 responseType:(JJCloudResponseType)newResponseType
			 userInfo:(NSDictionary *)userInfoDict;
{
	if (self = [super initWithRequest:request delegate:delegate])
	{
		_data = [[NSMutableData alloc] initWithCapacity:0];
		_identifier = [[NSString stringWithNewUUID] retain];
		_requestType = newRequestType;
		_responseType = newResponseType;
		_url = [[request URL] retain];
		[self setUserData:userInfoDict];
	}
	
	return self;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate 
		  requestType:(JJCloudRequestType)newRequestType responseType:(JJCloudResponseType)newResponseType;
{
	return [self initWithRequest:request delegate:delegate requestType:newRequestType responseType:newResponseType userInfo:nil];
}

#pragma mark -
#pragma mark helper methods

- (void)resetDataLength;
{
	[_data setLength:0];
}

- (void)appendData:(NSData *)newData;
{
	[_data appendData:newData];
}

- (NSString *)description;
{
	NSString *desc = [super description];
	return [desc stringByAppendingFormat:@" (requestType = %d, identifier = %@)", [self requestType], [self identifier]];
}

#pragma mark -
#pragma mark properties

@synthesize data = _data, requestType = _requestType, responseType = _responseType;
@synthesize identifier = _identifier, url = _url;
@synthesize userData;

@end
