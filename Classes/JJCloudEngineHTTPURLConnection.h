//
//  JJCloudEngineHTTPURLConnection.h
//
//  Created by Joshua Johnson on 5/26/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#import "JJCloudEngineGlobals.h"

@interface JJCloudEngineHTTPURLConnection : NSURLConnection {
	NSMutableData *_data;
	JJCloudRequestType _requestType;
	JJCloudResponseType _responseType;
	NSString *_identifier;
	NSURL *_url;
	NSDictionary *userData;
}

@property (retain, readonly) NSMutableData *data;
@property (assign, readonly) JJCloudRequestType requestType;
@property (assign, readonly) JJCloudResponseType responseType;
@property (retain, readonly) NSString *identifier;
@property (retain, readonly) NSURL *url;
@property (retain) NSDictionary *userData;

- (id)initWithRequest:(NSURLRequest *)request 
			 delegate:(id)delegate 
		  requestType:(JJCloudRequestType)newRequestType 
		 responseType:(JJCloudResponseType)newResponseType;

- (id)initWithRequest:(NSURLRequest *)request 
			 delegate:(id)delegate 
		  requestType:(JJCloudRequestType)newRequestType 
		 responseType:(JJCloudResponseType)newResponseType
			 userInfo:(NSDictionary *)userInfoDict;

- (void)resetDataLength;
- (void)appendData:(NSData *)newData;
- (NSString *)description;
@end
