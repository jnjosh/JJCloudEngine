//
//  JJCloudEngine.h
//
//  Created by Josh Johnson on 5/26/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//
// ======================================================================
// CloudApp API info -> http://support.getcloudapp.com/faqs/developers/api
// ======================================================================

#import <Foundation/Foundation.h>
#import "JJCloudEngineGlobals.h"
#import "JJCloudEngineDelegate.h"
#import "JJCloudParserDelegate.h"

@interface JJCloudEngine : NSObject <JJCloudParserDelegate> {
	__weak NSObject<JJCloudEngineDelegate> *_delegate;
	
	NSString *_userEmail;
	NSString *_userPassword;

	NSMutableDictionary *_connections; // JJCloudEngineHTTPURLConnection objects

	NSString *userAgent;
	BOOL clearsCookies;
}

@property (assign) BOOL clearsCookies;
@property (copy) NSString *userAgent;

+ (NSString *)version;
+ (JJCloudEngine *)cloudEngineWithDelegate:(NSObject *)delegate;
- (JJCloudEngine *)initWithDelegate:(NSObject *)delegate;

#pragma mark -
#pragma mark REST API methods
- (NSString *)getCloudItems;
- (NSString *)getCloudItems:(NSInteger)itemsPerPage forPage:(NSInteger)pageNumber;
- (NSString *)getCloudItem:(NSString *)shortSlug;
- (NSString *)createBookmarkWithURL:(NSString *)urlString andDescription:(NSString *)description;
- (NSString *)uploadFile:(NSString *)localPathToFile;
- (NSString *)deleteCloudItem:(NSString *)shortSlug;
#pragma mark -

// connection methods
- (NSUInteger)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnection:(NSString *)identifier;
- (void)closeAllConnections;

// utilities
- (NSString *)getImageAtURL:(NSString *)urlString;

@end

@interface JJCloudEngine (BasicAuth)
- (NSString *)email;
- (NSString *)password;
- (void)setEmail:(NSString *)newEmail password:(NSString *)newPassword;
@end