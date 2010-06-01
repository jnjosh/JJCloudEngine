//
//  JJCloudEngineDelegate.h
//
//  Created by Josh Johnson on 5/26/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

@protocol JJCloudEngineDelegate

@optional
// connection/request methods
- (void)requestSucceeded:(NSString *)connectionId;
- (void)requestFailed:(NSString *)connectionId withError:(NSError *)error;
- (void)connectionStarted:(NSString *)connectionIdentifier;
- (void)connectionFinished:(NSString *)connectionIdentifier;

- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier;

// REST requests received
- (void)itemsRecieved:(NSArray *)items forRequest:(NSString *)connectionId;
- (void)itemRecieved:(NSDictionary *)item forRequest:(NSString *)connectionId;

#if TARGET_OS_IPHONE
- (void)imageReceived:(UIImage *)image forRequest:(NSString *)connectionId;
#else
- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionId;
#endif 


@end
