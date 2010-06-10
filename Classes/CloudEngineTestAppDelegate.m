//
//  CloudEngineTestAppDelegate.m
//  CloudEngineTest
//
//  Created by Josh Johnson on 5/26/10.
//  Copyright jnjosh.com 2010. All rights reserved.
//

#import "CloudEngineTestAppDelegate.h"
#import "JJCloudEngine.h"

@implementation CloudEngineTestAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	
	NSLog(@"Testing JJCloudEngine version %@", [JJCloudEngine version]);

	// setup user email and password for CloudApp
	NSString *userEmail = nil;
	NSString *userPassword = nil;
	if (!userEmail || !userPassword)
	{
		NSLog(@"You failed at the simple parts. I need to log in.");
	}
	
	//=== Samples below ===//
	
	// create cloud engine instance
	cloudEngine = [[JJCloudEngine alloc] initWithDelegate:self];
	[cloudEngine setEmail:userEmail password:userPassword];
	
	// sample getting most recent items
	NSLog(@"Get All Listed items from Connection ID: %@", [cloudEngine getCloudItems]);
	
	// sample getting per page items
	//NSLog(@"Get page 2, items per page 5 -> %@", [cloudEngine getCloudItems:5 forPage:2]);
	
	// sample getting a specific item http://cl.ly/1CXW
	//NSLog(@"Get single item 1CXW on connection: %@", [cloudEngine getCloudItem:@"1CXW"]);
	
	// sample getting an image 
	//[cloudEngine getCloudItem:@"1E81"];
	
	// sample deleting a cloud item
	//[cloudEngine deleteCloudItem:@"1ETd"];
	
	// sample creating new bookmark
	//NSLog(@"Create new bookmark for jnjosh.com from connection: %@", [cloudEngine createBookmarkWithURL:@"http://www.jnjosh.com" andDescription:@"Link from JJCloudEngine!"]);

	// upload a file -- server determines type
	//[cloudEngine uploadFile:[[NSBundle mainBundle] pathForResource:@"JJCloudEngine" ofType:@"jpg"]];
	
	// upload an image with specified filename
	//[cloudEngine uploadImage:[UIImage imageNamed:@"JJCloudEngine.jpg"] fileName:@"JJCloudEngine Image.jpg"];
	
	[window makeKeyAndVisible];
	return YES;
}

- (void)requestFailed:(NSString *)connectionId withError:(NSError *)error
{
	NSLog(@"connection failed: %@. \r%@", connectionId, error);
}

- (void)itemsRecieved:(NSArray *)items forRequest:(NSString *)connectionId
{
	NSLog(@"cloud engine recieved items on request %@", connectionId);
	if (_cloudItems != nil) [_cloudItems release];
	_cloudItems = [items retain];
	[tableView reloadData];
}

- (void)itemRecieved:(NSDictionary *)item forRequest:(NSString *)connectionId
{
	NSLog(@"item received! -> \r%@\r", item);
	NSString *type = [item objectForKey:@"item_type"];
	if ([type isEqualToString:kCloudTypeImage])
	{
		NSLog(@"get the image");
		[cloudEngine getImageAtURL:[item objectForKey:@"content_url"]];
	}
}

- (void)imageReceived:(UIImage *)image forRequest:(NSString *)connectionId
{
	UIImageView *imv = [[UIImageView alloc] initWithImage:image];
	[imv setFrame:CGRectMake(0, 0, imv.frame.size.width, imv.frame.size.height)];
	[window addSubview:imv];
	[imv release];
}

#pragma mark -
#pragma mark TableView Delegates and DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if (_cloudItems != nil) 
		return [_cloudItems count];

	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellId = @"Cell";
	UILabel *itemName;
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellId];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellId] autorelease];
		CGRect frame = {{cell.indentationWidth, 0}, { cell.frame.size.width, cell.frame.size.height}};
		itemName = [[[UILabel alloc] initWithFrame:frame] autorelease];
		[[cell contentView] addSubview:itemName];
		[itemName setTag:1001];
		[itemName setBackgroundColor:[UIColor clearColor]];
		[itemName setTextColor:[UIColor blackColor]];
		[itemName setFont:[UIFont systemFontOfSize:16]];
	} else {
		itemName = (UILabel *)[cell viewWithTag:1001];
	}
	
	NSDictionary *dictItem = [_cloudItems objectAtIndex:indexPath.row];
	NSString *name = (NSString *)[dictItem objectForKey:@"name"];
	NSNumber *views = [dictItem objectForKey:@"view_counter"];
	[itemName setText:[NSString stringWithFormat:@"(%@) %@", views, name]];

	return cell;
}

- (void)dealloc {
	[tableView release];
	[_cloudItems release];
	[cloudEngine release];
    [window release];
    [super dealloc];
}


@end
