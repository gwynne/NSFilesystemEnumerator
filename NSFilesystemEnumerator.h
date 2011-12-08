//
//  NSFilesystemEnumerator.h
//
//  Created by Gwynne on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <fts.h>
#import <sys/stat.h>

typedef enum
{
	NSFSEnumerationFollowRootSymlinks		= (1 << 0),	// Follow the root path if it is a symlink.
	NSFSEnumerationChangeDirectories		= (1 << 1),	// Use the chdir() optimization
	NSFSEnumerationCallStat					= (1 << 2),	// Call stat() for each returned entity
	NSFSEnumerationFollowAllSymlinks		= (1 << 3),	// Follow all symlinks rather than returning info on the links themselves
	NSFSEnumerationSeeDotAndDotDot			= (1 << 4),	// Return entities for . and ..
	NSFSEnumerationCrossFilesystems			= (1 << 5),	// Allow iteration to cross filesystem boundaries

	NSFSEnumerationReturnDirectoriesTwice	= (0 << 8),	// Return directory entities in both pre- and post-order traversal.
	NSFSEnumerationReturnDirectoriesEarly	= (1 << 8),	// Return directory entities in pre-order traversal only.
	NSFSEnumerationReturnDirectoriesLate	= (2 << 8),	// Return directory entities in post-order traversal only.
	NSFSEnumerationReturnDirectoriesMask	= (3 << 8),
	
	// This represents the default behavior of fts when not passed options.
	NSFSEnumerationDefaultOptions			= NSFSEnumerationChangeDirectories | NSFSEnumerationCallStat | NSFSEnumerationCrossFilesystems,
	
} NSFilesystemEnumerationOptions;

typedef enum
{
	NSFilesystemEntryLevelRootParent	= FTS_ROOTPARENTLEVEL,
	NSFilesystemEntryLevelRoot			= FTS_ROOTLEVEL,
} NSFilesystemEntryLevel;

typedef enum
{
	NSFilesystemEntryDirectory			= FTS_D,
	NSFilesystemEntryDirectoryPostOrder	= FTS_DP,
	NSFilesystemEntryFile				= FTS_F,
	NSFilesystemEntrySymlink			= FTS_SL,
	NSFilesystemEntryUnknown			= FTS_DEFAULT,
} NSFilesystemEntryType;

// A filesystem entry passed to a callback or returned by -nextObject is valid
//	only until the callback returns or the next call to -nextObject (though
//	directory entries will be valid a bit longer). However, a copied entry is
//	valid until released.
@interface NSFilesystemEntry : NSObject <NSCopying>

@property(assign,readonly)	const FTSENT			*rawEntry;
@property(strong,readonly)	NSFilesystemEntry		*parent;	// yes, strong, not weak
@property(strong,readonly)	NSFilesystemEntry		*cycle;
@property(strong,readonly)	NSURL					*url;		// always a file URL; get name with entry.url.lastPathComponent
@property(strong,readonly)	NSError					*error;
@property(assign,readonly)	NSFilesystemEntryLevel	level;
@property(assign,readonly)	NSFilesystemEntryType	type;		// errors are translated to their respective base types
@property(assign,readonly)	dev_t					device;
@property(assign,readonly)	mode_t					mode;
@property(assign,readonly)	ino64_t					inode;
@property(assign,readonly)	uid_t					uid;
@property(assign,readonly)	gid_t					gid;
@property(assign,readonly)	off_t					size;
@property(assign,readonly)	NSTimeInterval			atime, mtime, ctime, birthtime;

@end


@interface NSFilesystemEnumerator : NSEnumerator

// Return NO from the callback to halt iteration.
+ (void)iterateFilesystemWithRootPath:(NSString *)rootPath_
						  withOptions:(NSFilesystemEnumerationOptions)options_
							 callback:(BOOL (^)(NSFilesystemEntry *entry))callback;

// The raw callback is faster and gives access to more information, but doesn't
//	wrap things in nice Cocoa objects.
+ (void)iterateFilesystemWithRootPath:(NSString *)rootPath_
						  withOptions:(NSFilesystemEnumerationOptions)options_
						  rawCallback:(BOOL (^)(const FTSENT *entry))callback;

+ (NSFilesystemEnumerator *)filesystemEnumeratorWithRootDirectory;
+ (NSFilesystemEnumerator *)filesystemEnumeratorRootedAt:(NSString *)rootPath_;
+ (NSFilesystemEnumerator *)filesystemEnumeratorRootedAt:(NSString *)rootPath_ withOptions:(NSFilesystemEnumerationOptions)options_;

- (id)initWithRootPath:(NSString *)rootPath_ options:(NSFilesystemEnumerationOptions)options_;

@property(copy,readonly)	NSString						*rootPath;
@property(assign,readonly)	NSFilesystemEnumerationOptions	options;
@property(copy)				NSComparisonResult				(^comparator)(const FTSENT *a, const FTSENT *b);

// It IS safe to intermix these calls.
- (id)nextObject;
- (const FTSENT *)nextRawObject;

@end
