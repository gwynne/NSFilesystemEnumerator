//
//  NSFilesystemEnumerator.m
//
//  Created by Gwynne on 12/6/11.
//	
//	Copyright (c) 2011, Gwynne Raskind
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	- Redistributions of source code must retain the above copyright notice,
//	  this list of conditions and the following disclaimer.
//	- Redistributions in binary form must reproduce the above copyright notice,
//	  this list of conditions and the following disclaimer in the documentation
//	  and/or other materials provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//	POSSIBILITY OF SUCH DAMAGE.

#import "NSFilesystemEnumerator.h"

@interface NSFilesystemEntry ()

+ (NSFilesystemEntry *)entryForFTSENT:(const FTSENT *)entry_ hasStat:(BOOL)hasStat_;

@end

@implementation NSFilesystemEntry
{
	BOOL					ownsEntry, hasStat;
}

@synthesize	rawEntry, parent, cycle, url, error, level, type, device, mode, inode, uid, gid, size, atime, mtime, ctime, birthtime;

+ (NSFilesystemEntry *)entryForFTSENT:(const FTSENT *)entry_ hasStat:(BOOL)hasStat_
{
	NSFilesystemEntry		*entry = [[[self class] alloc] init];
	
	entry->rawEntry = entry_;
	entry->ownsEntry = NO;
	entry->hasStat = hasStat_;
	
	if (!entry_)
	{
		entry->error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
		return entry;
	}
	
	if (entry_->fts_parent && entry_->fts_parent != entry_)
		entry->parent = [NSFilesystemEntry entryForFTSENT:entry_->fts_parent hasStat:hasStat_];
	else
		entry->parent = nil;
	
	if (entry_->fts_info == FTS_DC && entry_->fts_cycle && entry_->fts_cycle != entry_)
		entry->cycle = [NSFilesystemEntry entryForFTSENT:entry_->fts_cycle hasStat:hasStat_];
	else
		entry->cycle = nil;
	
	NSString				*entryPath = [[NSString alloc] initWithBytes:entry_->fts_path length:entry_->fts_pathlen
														   encoding:CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding())];
	
	entry->url = [NSURL fileURLWithPath:entryPath isDirectory:entry_->fts_info == FTS_D || entry_->fts_info == FTS_DC || entry_->fts_info == FTS_DNR ||
															  entry_->fts_info == FTS_DOT || entry_->fts_info == FTS_DP];
	
	if (entry_->fts_info == FTS_DNR || entry_->fts_info == FTS_ERR || entry_->fts_info == FTS_NS)
		entry->error = [NSError errorWithDomain:NSPOSIXErrorDomain code:entry_->fts_errno userInfo:nil];
	
	entry->level = entry_->fts_level;
	if (entry_->fts_info == FTS_D || entry_->fts_info == FTS_DC || entry_->fts_info == FTS_DNR || entry_->fts_info == FTS_DOT)
		entry->type = NSFilesystemEntryDirectory;
	else if (entry_->fts_info == FTS_DP)
		entry->type = NSFilesystemEntryDirectoryPostOrder;
	else if (entry_->fts_info == FTS_F || entry_->fts_info == FTS_NSOK)
		entry->type = NSFilesystemEntryFile;
	else if (entry_->fts_info == FTS_SL || entry_->fts_info == FTS_SLNONE)
		entry->type = NSFilesystemEntrySymlink;
	else
		entry->type = NSFilesystemEntryUnknown;
	
	if (hasStat_)
	{
		entry->device = entry_->fts_statp->st_dev;
		entry->mode = entry_->fts_statp->st_mode;
		entry->inode = entry_->fts_statp->st_ino;
		entry->uid = entry_->fts_statp->st_uid;
		entry->gid = entry_->fts_statp->st_gid;
		entry->size = entry_->fts_statp->st_size;
		entry->atime = (double)(entry_->fts_statp->st_atimespec.tv_sec) + ((double)entry_->fts_statp->st_atimespec.tv_nsec / (double)NSEC_PER_SEC);
		entry->mtime = (double)(entry_->fts_statp->st_mtimespec.tv_sec) + ((double)entry_->fts_statp->st_mtimespec.tv_nsec / (double)NSEC_PER_SEC);
		entry->ctime = (double)(entry_->fts_statp->st_ctimespec.tv_sec) + ((double)entry_->fts_statp->st_ctimespec.tv_nsec / (double)NSEC_PER_SEC);
		entry->birthtime = (double)(entry_->fts_statp->st_birthtimespec.tv_sec) + ((double)entry_->fts_statp->st_birthtimespec.tv_nsec / (double)NSEC_PER_SEC);
	}
	
	return entry;
}

- (id)copyWithZone:(NSZone *)zone
{
	NSFilesystemEntry		*result = [[self class] entryForFTSENT:rawEntry hasStat:hasStat];
	FTSENT					*entry = calloc(1, sizeof(FTSENT));
	
	memcpy(entry, rawEntry, sizeof(FTSENT));
	result->rawEntry = entry;
	if (hasStat)
	{
		entry->fts_statp = calloc(1, sizeof(struct stat));
		memcpy(entry->fts_statp, rawEntry->fts_statp, sizeof(struct stat));
	}
	result->parent = [result->parent copy];
	result->cycle = [result->cycle copy];
	result->ownsEntry = YES;
	return result;
}

- (void)dealloc
{
	if (ownsEntry)
	{
		free(rawEntry->fts_statp);
		free((void *)rawEntry);
	}
}

- (NSString *)description
{
	NSString		*typemap[] = { [NSFilesystemEntryDirectory] = @"Directory", [NSFilesystemEntryDirectoryPostOrder] = @"Directory Post-Order",
								   [NSFilesystemEntryFile] = @"File", [NSFilesystemEntrySymlink] = @"Symlink", [NSFilesystemEntryUnknown] = @"Unknown" };

	return [NSString stringWithFormat:@"NSFilesystemEntry %@ type %@", self.url.path, typemap[self.type]];
}

@end


@interface NSFilesystemEnumerator ()

- (BOOL)openHandleIfNeeded;
@property(copy,readwrite)	NSString						*rootPath;
@property(assign,readwrite)	NSFilesystemEnumerationOptions	options;

@end


@implementation NSFilesystemEnumerator
{
	FTS			*handle;
}

@synthesize	rootPath, options, comparator;

// Return NO from the callback to halt iteration
+ (void)iterateFilesystemWithRootPath:(NSString *)rootPath_
						  withOptions:(NSFilesystemEnumerationOptions)options_
							 callback:(BOOL (^)(NSFilesystemEntry *entry))callback
{
	if (!callback)
		return;

	NSFilesystemEnumerator		*enumerator = [self filesystemEnumeratorRootedAt:rootPath_ withOptions:options_];
	NSFilesystemEntry			*obj = nil;
	
	while ((obj = [enumerator nextObject]))
	{
		if (!callback(obj))
			break;
	}
}

+ (void)iterateFilesystemWithRootPath:(NSString *)rootPath_
						  withOptions:(NSFilesystemEnumerationOptions)options_
						  rawCallback:(BOOL (^)(const FTSENT *entry))callback
{
	if (!callback)
		return;

	NSFilesystemEnumerator		*enumerator = [self filesystemEnumeratorRootedAt:rootPath_ withOptions:options_];
	const FTSENT				*obj = NULL;
	
	while ((obj = [enumerator nextRawObject]))
	{
		if (!callback(obj))
			break;
	}
}

+ (NSFilesystemEnumerator *)filesystemEnumeratorWithRootDirectory
{
	return [[[self class] alloc] initWithRootPath:@"/" options:NSFSEnumerationDefaultOptions];
}

+ (NSFilesystemEnumerator *)filesystemEnumeratorRootedAt:(NSString *)rootPath_
{
	return [[[self class] alloc] initWithRootPath:rootPath_ options:NSFSEnumerationDefaultOptions];
}

+ (NSFilesystemEnumerator *)filesystemEnumeratorRootedAt:(NSString *)rootPath_ withOptions:(NSFilesystemEnumerationOptions)options_
{
	return [[[self class] alloc] initWithRootPath:rootPath_ options:options_];
}

- (id)initWithRootPath:(NSString *)rootPath_ options:(NSFilesystemEnumerationOptions)options_
{
	if ((self = [super init]))
	{
		self.rootPath = rootPath_;
		self.options = options_;
		handle = NULL;	// lazy open so comparator can be set
	}
	return self;
}

- (BOOL)openHandleIfNeeded
{
	if (handle)
		return YES;
	
	const char		*rootPaths[2] = { self.rootPath.UTF8String, NULL };
	int				ftsOptions = 0;
	
	ftsOptions |= (self.options & NSFSEnumerationFollowRootSymlinks) ? FTS_COMFOLLOW : 0;
	ftsOptions |= (self.options & NSFSEnumerationFollowAllSymlinks) ? FTS_LOGICAL : FTS_PHYSICAL;
	ftsOptions |= (self.options & NSFSEnumerationChangeDirectories) ? 0 : FTS_NOCHDIR;
	ftsOptions |= (self.options & NSFSEnumerationCallStat) ? 0 : FTS_NOSTAT;
	ftsOptions |= (self.options & NSFSEnumerationSeeDotAndDotDot) ? FTS_SEEDOT : 0;
	ftsOptions |= (self.options & NSFSEnumerationCrossFilesystems) ? 0 : FTS_XDEV;

	handle = fts_open_b((char * const *)rootPaths, ftsOptions, ^ int (const FTSENT **a, const FTSENT **b) {
		return self.comparator ? (int)((self.comparator)(a ? *a : NULL, b ? *b : NULL)) : 0;
	});
	return handle != NULL;
}

- (id)nextObject
{
	const FTSENT			*ent = [self nextRawObject];
	
	if (!ent && errno == 0)
		return nil;
	return [NSFilesystemEntry entryForFTSENT:ent hasStat:!!(self.options & NSFSEnumerationCallStat)];
}

- (const FTSENT *)nextRawObject
{
	if (![self openHandleIfNeeded])
		return NULL;
	
	const FTSENT			*ent = NULL;
	BOOL					returnDirEarly = (self.options & NSFSEnumerationReturnDirectoriesMask) != NSFSEnumerationReturnDirectoriesLate,
							returnDirLate = (self.options & NSFSEnumerationReturnDirectoriesMask) != NSFSEnumerationReturnDirectoriesEarly;

	do
	{
		ent = fts_read(handle);
	} while (ent && ((ent->fts_info == FTS_D && !returnDirEarly) || (ent->fts_info == FTS_DP && !returnDirLate)));
	
	return ent;
}

@end
