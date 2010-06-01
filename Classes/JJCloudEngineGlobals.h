//
//  JJCloudEngineGlobals.h
//
//  Created by Josh Johnson on 5/26/10.
//  Copyright 2010 jnjosh.com. All rights reserved.
//

#define kCloudTypeAll nil
#define kCloudTypeUnknown @"unknown"
#define kCloudTypeBookmark @"bookmark"
#define kCloudTypeVideo @"video"
#define kCloudTypeImage @"image"
#define kCloudTypeText @"text"
#define kCloudTypeArchive @"archive"
#define kCloudTypeAudio @"audio"

#define kCloudFilePathKey @"CloudItemPath"
#define kCloudFileTypeKey @"CloudItemType"

typedef enum
{
	JJCloudUnknownType = 0,
	JJCloudBookmarkType = 1,
	JJCloudVideoType = 2,
	JJCloudImageType = 3,
	JJCloudTextType = 4,
	JJCloudArchiveType = 5,
	JJCloudAudioType = 6
} JJCloudItemType;

typedef enum 
{
	JJCloudViewItemByURLRequest = 0,
	JJCloudListAllItemsRequest,
	JJCloudCreateBookmarkRequest,
	JJCloudUploadS3FileRequest,
	JJCloudUploadFileRequest,
	JJCloudDeleteItemRequest,
	JJCloudImageRequest
} JJCloudRequestType;

typedef enum 
{
	JJCloudGeneric = 0,
	JJCloudItems = 1,
	JJCloudItem = 2,
	JJCloudImage = 3,
	JJCloudS3Data = 4,
	JJCloudItemToDelete = 5,
	JJCloudDeleteItem = 6
} JJCloudResponseType;