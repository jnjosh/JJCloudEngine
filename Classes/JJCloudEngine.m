//
//  JJCloudEngine.m
//
//  Created by Josh Johnson on 5/26/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#import "JJCloudEngine.h"
#import "JJCloudEngineHTTPURLConnection.h"
#import "NSData+Base64.h"
#import "JJCloudTouchJSONParser.h"

#define kCloudAppDomain @"cl.ly"
#define kCloudAppMyDomain @"my.cl.ly"

#define kHTTPPostMethod @"POST"
#define kHTTPDeleteMethod @"DELETE"

#define kAPIFormat @"json"
#define kUrlRequestTimeout 25.0

#pragma mark -
#pragma mark private methods

@interface JJCloudEngine (PrivateMethods)

- (BOOL) _isValidDelegateForSelector:(SEL)selector;
- (void)_parseDataForConnection:(JJCloudEngineHTTPURLConnection *)connection;

- (NSDateFormatter *)_HTTPDateFormatter;
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSDate *)_HTTPToDate:(NSString *)httpDate;
- (NSString *)_dateToHTTP:(NSDate *)date;
- (NSString *)_encodeString:(NSString *)string;

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
                         requestType:(JJCloudRequestType)requestType 
                        responseType:(JJCloudResponseType)responseType
							userInfo:(NSDictionary *)userInfo;

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
                         requestType:(JJCloudRequestType)requestType 
                        responseType:(JJCloudResponseType)responseType;

- (NSString *)_sendDataRequestWithMethod:(NSString *)method 
								fullPath:(NSString *)fullURLPath 
                         queryParameters:(NSDictionary *)params 
                                filePath:(NSString *)filePath
                                    body:(NSDictionary *)bodyParams 
                             requestType:(JJCloudRequestType)requestType 
                            responseType:(JJCloudResponseType)responseType;

- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method 
                                           path:(NSString *)path 
                                    requestType:(JJCloudRequestType)requestType 
                                queryParameters:(NSDictionary *)params;

@end

#pragma mark -
#pragma mark Private methods for S3 upload

@interface JJCloudEngine (CloudAppApiSpecifics)
- (void)_uploadFileFromConnection:(NSString *)connectionId withS3Information:(NSArray *)s3Data;
- (void)_deleteFileWithHref:(NSString *)fileHref;
@end

#pragma mark -
#pragma mark JJCloudEngine

@implementation JJCloudEngine

#pragma mark -
#pragma mark memory

- (void)dealloc 
{
	_delegate = nil;
	
	[[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections release];

	[userAgent release];
	[_userEmail release];
	[_userPassword release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark info

+ (NSString *)version;
{
	return @"1.0"; // May 30, 2010
}

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((_delegate != nil) && [_delegate respondsToSelector:selector]);
}


#pragma mark -
#pragma mark constructors

+ (JJCloudEngine *)cloudEngineWithDelegate:(NSObject *)delegate;
{
	return [[[self alloc] initWithDelegate:delegate] autorelease];
}

- (JJCloudEngine *)initWithDelegate:(NSObject *)delegate;
{
	if (self = [super init]) 
	{
		_delegate = delegate;
		_connections = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
		[self setClearsCookies:NO];
	}
	
	return self;
}

#pragma mark -
#pragma mark REST API methods

- (NSString *)getCloudItems;
{
	NSString *path = @"items";
	return [self _sendRequestWithMethod:nil 
								   path:path 
						queryParameters:nil 
								   body:nil 
							requestType:JJCloudListAllItemsRequest 
						   responseType:JJCloudItems];
}

- (NSString *)getCloudItems:(NSInteger)itemsPerPage forPage:(NSInteger)pageNumber;
{
	NSMutableDictionary *queryDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%d", pageNumber], @"page", [NSString stringWithFormat:@"%d", itemsPerPage], @"per_page", nil];
	NSString *path = @"items";
	return [self _sendRequestWithMethod:nil 
								   path:path 
						queryParameters:queryDict 
								   body:nil 
							requestType:JJCloudListAllItemsRequest 
						   responseType:JJCloudItems];
}

- (NSString *)getCloudItem:(NSString *)shortSlug;
{
	return [self _sendRequestWithMethod:nil
								   path:shortSlug 
						queryParameters:nil 
								   body:nil 
							requestType:JJCloudViewItemByURLRequest 
						   responseType:JJCloudItem];
}

- (NSString *)deleteCloudItem:(NSString *)shortSlug;
{
	return [self _sendRequestWithMethod:nil
								   path:shortSlug 
						queryParameters:nil 
								   body:nil 
							requestType:JJCloudDeleteItemRequest 
						   responseType:JJCloudItemToDelete];
}

- (NSString *)createBookmarkWithURL:(NSString *)urlString andDescription:(NSString *)description;
{
	NSString *path = @"items";
	NSString *body = [NSString stringWithFormat:@"{\"item\":{\"name\": \"%@\",\"redirect_url\": \"%@\"}}", description, urlString];
	return [self _sendRequestWithMethod:kHTTPPostMethod 
								   path:path 
						queryParameters:nil 
								   body:body 
							requestType:JJCloudCreateBookmarkRequest 
						   responseType:JJCloudItem];
}


- (NSString *)uploadFile:(NSString *)localPathToFile;
{
	// get s3 data
	NSString *path = @"items/new";
	NSDictionary *userInfo = [[[NSDictionary alloc] initWithObjectsAndKeys:[localPathToFile copy], kCloudFilePathKey, nil] autorelease];
	return [self _sendRequestWithMethod:nil 
								   path:path 
						queryParameters:nil 
								   body:nil 
							requestType:JJCloudUploadS3FileRequest 
						   responseType:JJCloudS3Data 
							   userInfo:userInfo];
}

#pragma mark -
#pragma mark Internal processes
//
// cloudapp api requires 3 step process, get s3 data, post actual data, then finally get the returned item.
//
- (void)_uploadFileFromConnection:(NSString *)connectionId withS3Information:(NSArray *)s3Data;
{

	JJCloudEngineHTTPURLConnection *connection = [_connections objectForKey:connectionId];
	NSString *filePath = [[connection userData] objectForKey:kCloudFilePathKey];
	if (filePath) 
	{
		NSDictionary *s3 = [s3Data objectAtIndex:0];
		NSDictionary *params = [s3 objectForKey:@"params"];
		NSString *newUrl = [s3 objectForKey:@"url"];
		NSMutableDictionary *bodyDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (NSString *key in [params allKeys])
		{
			[bodyDict setObject:[params valueForKey:key] forKey:key];
		}
		
		// post file request
		[self _sendDataRequestWithMethod:kHTTPPostMethod 
								fullPath:newUrl 
						 queryParameters:nil 
								filePath:filePath
									body:bodyDict
							 requestType:JJCloudUploadFileRequest 
							responseType:JJCloudItem];
	
	}
	
	// close connection
	[self closeConnection:connectionId];
}

- (void)_deleteFileWithHref:(NSString *)fileHref;
{
	[self _sendRequestWithMethod:kHTTPDeleteMethod 
							path:fileHref 
				 queryParameters:nil 
							body:nil 
					 requestType:JJCloudDeleteItemRequest 
					responseType:JJCloudGeneric];
}

#pragma mark -
#pragma mark Connection methods

- (NSUInteger)numberOfConnections
{
    return [_connections count];
}

- (NSArray *)connectionIdentifiers
{
    return [_connections allKeys];
}

- (void)closeConnection:(NSString *)connectionIdentifier
{
    JJCloudEngineHTTPURLConnection *connection = [_connections objectForKey:connectionIdentifier];
    if (connection) {
        [connection cancel];
        [_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
}

- (void)closeAllConnections
{
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections removeAllObjects];
}

#pragma mark -
#pragma mark Request Methods

- (NSString *)_sendRequest:(NSURLRequest *)theRequest 
		   withRequestType:(JJCloudRequestType)requestType 
			  responseType:(JJCloudResponseType)responseType 
				  userInfo:(NSDictionary *)userInfo
{
	JJCloudEngineHTTPURLConnection *connection;
    connection = [[[JJCloudEngineHTTPURLConnection alloc] initWithRequest:theRequest 
																 delegate:self 
															  requestType:requestType 
															 responseType:responseType 
																 userInfo:userInfo] autorelease];
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
    }
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
}

- (NSString *)_sendRequest:(NSURLRequest *)theRequest 
		   withRequestType:(JJCloudRequestType)requestType
			  responseType:(JJCloudResponseType)responseType
{
	return [self _sendRequest:theRequest withRequestType:requestType responseType:responseType userInfo:nil];
}

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
                         requestType:(JJCloudRequestType)requestType 
                        responseType:(JJCloudResponseType)responseType
							userInfo:(NSDictionary *)userInfo;
{
	NSMutableURLRequest *theRequest = [self _baseRequestWithMethod:method 
                                                              path:path
													   requestType:requestType 
                                                   queryParameters:params];
    
    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:kHTTPPostMethod]);
	BOOL isDELETE = (method && [method isEqualToString:kHTTPDeleteMethod]);
    if (isPOST) {
		// Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
		NSString *finalBody = @"";
		if (body) {
			finalBody = [finalBody stringByAppendingString:body];
		}
        
		if (finalBody) {
			[theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	if (isDELETE)
	{
		NSURL *url = [NSURL URLWithString:path];
		[theRequest setURL:url];
	}
	return [self _sendRequest:theRequest withRequestType:requestType responseType:responseType userInfo:userInfo];
}

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(NSString *)body 
                         requestType:(JJCloudRequestType)requestType 
                        responseType:(JJCloudResponseType)responseType
{
	return [self _sendRequestWithMethod:method path:path queryParameters:params body:body requestType:requestType responseType:responseType userInfo:nil];
}

- (NSString *)_sendDataRequestWithMethod:(NSString *)method 
								fullPath:(NSString *)fullURLPath 
                         queryParameters:(NSDictionary *)params 
                                filePath:(NSString *)filePath
                                    body:(NSDictionary *)bodyParams 
                             requestType:(JJCloudRequestType)requestType 
                            responseType:(JJCloudResponseType)responseType;
{
	if (!method || ![method isEqualToString:kHTTPPostMethod]) return nil;
	if (!filePath) return nil;
	
	NSString *filename = [filePath lastPathComponent];
	NSString *boundary = @"-----0xkHtMlBoUnDaRy-----";  
	
	NSString *bodyPrefix = [NSString stringWithFormat:@"--%@\r\n", boundary];
	NSString *bodySeperator = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
	NSString *bodySuffix = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
	
	// build request
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fullURLPath] 
																   cachePolicy:NSURLCacheStorageAllowed 
															   timeoutInterval:kUrlRequestTimeout];
	[theRequest setHTTPMethod:kHTTPPostMethod];
	
	// build body
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[bodyPrefix dataUsingEncoding:NSUTF8StringEncoding]];
	
	// body params
	for (id key in bodyParams)
	{
		NSString *contDisp = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", (NSString *)key];
		NSString *contValue = [bodyParams objectForKey:key];

		[postBody appendData:[[NSString stringWithFormat:@"%@%@", contDisp, contValue] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[bodySeperator dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	// file 
	NSString *fileContDisp = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename];
	NSString *fileContType = @"Content-Type: application/octet-stream\r\n\r\n";

	[postBody appendData:[[NSString stringWithFormat:@"%@%@", fileContDisp, fileContType] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[NSData dataWithContentsOfFile:filePath]];
	[postBody appendData:[bodySuffix dataUsingEncoding:NSUTF8StringEncoding]];
	[theRequest setHTTPBody:postBody];
	
	// set headers
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[theRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
	[theRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[theRequest setValue:[NSString stringWithFormat:@"%d", [postBody length]] forHTTPHeaderField:@"Content-Length"];
	
	// build connection
	JJCloudEngineHTTPURLConnection *connection;
	connection = [[JJCloudEngineHTTPURLConnection alloc] initWithRequest:theRequest delegate:self requestType:requestType responseType:responseType];
	if (!connection) 
	{
		return nil;
	}
	else 
	{
		[_connections setObject:connection forKey:[connection identifier]];
		[connection release];
	}
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
	
	return [connection identifier];
}


- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method 
                                           path:(NSString *)path 
                                    requestType:(JJCloudRequestType)requestType 
                                queryParameters:(NSDictionary *)params;
{
	NSString *fullPath = [path stringByAddingPercentEscapesUsingEncoding:NSNonLossyASCIIStringEncoding];
	if (params && ![method isEqualToString:kHTTPPostMethod])
	{
		fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
	}
	
	NSString *domain = nil;
	switch (requestType) {
		case JJCloudViewItemByURLRequest:
		case JJCloudDeleteItemRequest:
			domain = kCloudAppDomain;
			break;
		default:
			domain = kCloudAppMyDomain;
			break;
	}
	
	NSString *connectionType = @"http";
	NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", connectionType, domain, fullPath];
	NSURL *finalUrl = [NSURL URLWithString:urlString];

	if (!finalUrl) return nil;
	
	// make request
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:finalUrl 
																	   cachePolicy:NSURLRequestReloadIgnoringCacheData 
																  timeoutInterval:kUrlRequestTimeout];
	if (![[self userAgent] isEqualToString:@""]) 
	{
		[theRequest setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
	}
	[theRequest setHTTPShouldHandleCookies:NO];
	
	if (method) 
	{
		[theRequest setHTTPMethod:method];
		if (method == kHTTPPostMethod && requestType != JJCloudUploadFileRequest)
			[theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	}
	[theRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	return theRequest;
}

#pragma mark -
#pragma mark NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (_userEmail && _userPassword && [challenge previousFailureCount] == 0 && ![challenge proposedCredential]) {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:_userEmail password:_userPassword 
															  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}


- (void)connection:(JJCloudEngineHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connection resetDataLength];
    
    // Get response code.
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    NSInteger statusCode = [resp statusCode];

	if (statusCode >= 400) {
        // Assume failure, and report to delegate.
        NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:nil];
		if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
			[_delegate requestFailed:[connection identifier] withError:error];
        
        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
		
    } else if (statusCode == 304 || [connection responseType] == JJCloudGeneric) {
        // Not modified, or generic success.
		if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
			[_delegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) {
            [self parsingSucceededForRequest:[connection identifier] 
                              ofResponseType:[connection responseType] 
                           withParsedObjects:[NSArray array]];
        }
        
        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
}


- (void)connection:(JJCloudEngineHTTPURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the receivedData.
    [connection appendData:data];
}


- (void)connection:(JJCloudEngineHTTPURLConnection *)connection didFailWithError:(NSError *)error
{
	NSString *connectionIdentifier = [connection identifier];

    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)]){
		[_delegate requestFailed:connectionIdentifier
					   withError:error];
	}
    
    // Release the connection.
    [_connections removeObjectForKey:connectionIdentifier];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
		[_delegate connectionFinished:connectionIdentifier];
}


- (void)connectionDidFinishLoading:(JJCloudEngineHTTPURLConnection *)connection
{
	NSString *connID = [connection identifier];
	JJCloudResponseType responseType = [connection responseType];
	
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
		[_delegate requestSucceeded:connID];
    
    NSData *receivedData = [connection data];
    if (receivedData) {        
        if (responseType == JJCloudImage) {
			// Create image from data.
#if TARGET_OS_IPHONE
            UIImage *image = [[[UIImage alloc] initWithData:[connection data]] autorelease];
#else
            NSImage *image = [[[NSImage alloc] initWithData:[connection data]] autorelease];
#endif
            // Inform delegate.
			if ([self _isValidDelegateForSelector:@selector(imageReceived:forRequest:)])
				[_delegate imageReceived:image forRequest:[connection identifier]];
		} else {
            // Parse data from the connection
			[self _parseDataForConnection:connection];
			if (responseType == JJCloudUploadFileRequest) return;
        }
    }
	
	// Release the connection.
	[_connections removeObjectForKey:connID];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
		[_delegate connectionFinished:connID];
}

#pragma mark -
#pragma mark Parsing Method

- (void)_parseDataForConnection:(JJCloudEngineHTTPURLConnection *)connection
{
    NSData *jsonData = [[[connection data] copy] autorelease];
    NSString *identifier = [[[connection identifier] copy] autorelease];
    JJCloudRequestType requestType = [connection requestType];
    JJCloudResponseType responseType = [connection responseType];
	
	NSURL *URL = [connection url];
	[JJCloudTouchJSONParser parserWithJSON:jsonData 
								  delegate:self
					  connectionIdentifier:identifier
							   requestType:requestType
							  responseType:responseType
									   URL:URL];
}

#pragma mark -
#pragma mark JJCloudParserDelegate Methods

- (void)parsingSucceededForRequest:(NSString *)identifier 
                    ofResponseType:(JJCloudResponseType)responseType 
                 withParsedObjects:(NSArray *)parsedObjects
{
    // Forward appropriate message to _delegate, depending on responseType.
    switch (responseType) {
		case JJCloudItemToDelete:;
			NSDictionary *dict = [parsedObjects objectAtIndex:0];
			NSString *href = [dict valueForKey:@"href"];
			[self _deleteFileWithHref:href];
			break;
		case JJCloudItems:
			if ([self _isValidDelegateForSelector:@selector(itemsRecieved:forRequest:)])
				[_delegate itemsRecieved:parsedObjects forRequest:identifier];
			break;
		case JJCloudItem:
			if ([self _isValidDelegateForSelector:@selector(itemRecieved:forRequest:)])
				[_delegate itemRecieved:[parsedObjects objectAtIndex:0] forRequest:identifier];
			break;
		case JJCloudS3Data:
			[self _uploadFileFromConnection:identifier withS3Information:parsedObjects];
			break;
    }
}

- (void)parsingFailedForRequest:(NSString *)requestIdentifier 
                 ofResponseType:(JJCloudResponseType)responseType 
                      withError:(NSError *)error
{
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:requestIdentifier withError:error];
}

- (void)parsedObject:(NSDictionary *)dictionary forRequest:(NSString *)requestIdentifier 
	  ofResponseType:(JJCloudResponseType)responseType
{
	if (responseType != JJCloudS3Data) 
	{
		if ([self _isValidDelegateForSelector:@selector(receivedObject:forRequest:)])
			[_delegate receivedObject:dictionary forRequest:requestIdentifier];
	}
}

#pragma mark -
#pragma mark utility methods

- (NSDateFormatter *)_HTTPDateFormatter
{
    // Returns a formatter for dates in HTTP format (i.e. RFC 822, updated by RFC 1123).
    // e.g. "Sun, 06 Nov 1994 08:49:37 GMT"
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	//[dateFormatter setDateFormat:@"%a, %d %b %Y %H:%M:%S GMT"]; // won't work with -init, which uses new (unicode) format behaviour.
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss GMT"];
	return dateFormatter;
}

- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
{
    // Append base if specified.
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    
    // Append each name-value pair.
    if (params) {
        NSUInteger i;
        NSArray *names = [params allKeys];
        for (i = 0; i < [names count]; i++) {
            if (i == 0 && prefixed) {
                [str appendString:@"?"];
            } else if (i > 0) {
                [str appendString:@"&"];
            }
            NSString *name = [names objectAtIndex:i];
            [str appendString:[NSString stringWithFormat:@"%@=%@", 
							   name, [self _encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}

- (NSDate *)_HTTPToDate:(NSString *)httpDate
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter dateFromString:httpDate];
}

- (NSString *)_dateToHTTP:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter stringFromDate:date];
}

- (NSString *)_encodeString:(NSString *)string
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
																		   (CFStringRef)string, 
																		   NULL, 
																		   (CFStringRef)@";/?:@&=$+{}<>,",
																		   kCFStringEncodingUTF8);
    return [result autorelease];
}

- (NSString *)getImageAtURL:(NSString *)urlString
{
	NSString *encodedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *url = [NSURL URLWithString:encodedUrlString];
	if (!url) {
		return nil;
	}
    
	// Construct an NSMutableURLRequest for the URL and set appropriate request method.
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:kUrlRequestTimeout];
    
	JJCloudEngineHTTPURLConnection *connection;
	connection = [[JJCloudEngineHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:JJCloudImageRequest 
                                                        responseType:JJCloudImage];
   
	if (!connection) {
		return nil;
	} else {
		[_connections setObject:connection forKey:[connection identifier]];
		[connection release];
	}
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
	return [connection identifier];
}

#pragma mark -
#pragma mark properties

@synthesize clearsCookies, userAgent;

@end

#pragma mark -
#pragma mark BasicAuth

@implementation JJCloudEngine (BasicAuth)

- (NSString *)email
{
	return [[_userEmail retain] autorelease];
}

- (NSString *)password
{
	return [[_userPassword retain] autorelease];
}

- (void)setEmail:(NSString *)newEmail password:(NSString *)newPassword;
{
	[_userEmail release];
	_userEmail = [newEmail retain];
	[_userPassword release];
	_userPassword = [newPassword retain];
	
	if ([self clearsCookies]) 
	{
		NSString *urlString = [NSString stringWithFormat:@"%@://%@", @"http", kCloudAppDomain];
		NSURL *url = [NSURL URLWithString:urlString];
		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSEnumerator *enumerator = [[cookieStorage cookiesForURL:url] objectEnumerator];
		NSHTTPCookie *cookie = nil;
		while ((cookie = [enumerator nextObject]))
		{
			[cookieStorage deleteCookie:cookie];
		}
	}
}

@end
