# JJCloudEngine API for CloudApp

An Objective-C wrapper for the REST-based [CloudApp API](http://support.getcloudapp.com/faqs/developers/api) 

Still a *work in progress* and only tested around an iPhone App.

## TODO

* Finish implementation of file upload. Can't seem to get anything but 400 response from the Amazon S3 upload process.
* Create more convenience methods.
* Add tests
* Better documentation

## Usage and Requirements

Copy the JJCloudEngine group into your project. See Demo/CloudEngineTestAppDelegate.m for more actual usage.

TouchJSON is used for JSON parsing. This must also be added to your project.

### Quick Usage

	Use JJCloudEngineDelegate protocol to recieve responses:

	JJCloudEngine *cloudEngine = [[JJCloudEngine alloc] initWithDelegate:self];
	[cloudEngine setEmail:userEmail password:userPassword];

	// send request
	[cloudEngine getCloudItems];

	...
	
	- (void)itemsRecieved:(NSArray *)items forRequest:(NSString *)connectionId
	{
		NSLog(@"cloud engine recieved items on request %@", connectionId);
	}
	
### JSON Data (also from the [CloudApp API](http://support.getcloudapp.com/faqs/developers/api))

{
  "href": "http://my.cl.ly/items/3",
  "name": "Screen shot 2010-04-01 at 12.00.00 AM.png",
  "url": "http://cl.ly/6571",
  "content_url": "http://cl.ly/6571/content",
  "item_type": "image",
  "view_counter": 42,
  "icon": "http://my.cl.ly/images/item_types/image.png",
  "remote_url":"http://f.cl.ly/items/3d7ba41682802c301150/Screen shot 2010-04-01 at 12.00.00 AM.png",
  "created_at": "2010-04-01T12:00:00Z",
  "updated_at": "2010-04-01T12:00:00Z"
}
	
## CREDITS

This engine is a direct translation of [Matt Gemmell's MGTwitterEngine](http://github.com/mattgemmell/MGTwitterEngine) from a Twitter Engine to a CloudApp Engine. Large portions of this project are merely a "reimagining" of Matt's framework.
JSON Parsing supplied by [TouchJSON](http://code.google.com/p/touchcode/wiki/TouchJSON)