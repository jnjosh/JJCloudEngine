//
//  CloudEngineTestAppDelegate.h
//  CloudEngineTest
//
//  Created by Josh Johnson on 5/26/10.
//  Copyright jnjosh.com 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJCloudEngineDelegate.h"

@class JJCloudEngine;

@interface CloudEngineTestAppDelegate : NSObject <UIApplicationDelegate, JJCloudEngineDelegate, UITableViewDelegate, UITableViewDataSource> {
    UIWindow *window;
	IBOutlet UITableView *tableView;
	NSMutableArray *_cloudItems;

	JJCloudEngine *cloudEngine;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

