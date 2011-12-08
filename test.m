#import <Cocoa/Cocoa.h>
#import "NSFilesystemEnumerator.h"

int		main(int argc, char **argv)
{
	@autoreleasepool
	{
		NSString						*typemapa[] = { [NSFilesystemEntryDirectory] = @"Directory", [NSFilesystemEntryDirectoryPostOrder] = @"Directory Post-Order",
													    [NSFilesystemEntryFile] = @"File", [NSFilesystemEntrySymlink] = @"Symlink", [NSFilesystemEntryUnknown] = @"Unknown" },
										* __strong *typemap = typemapa;

		[NSFilesystemEnumerator iterateFilesystemWithRootPath:argc > 1 ? [NSString stringWithUTF8String:argv[1]] : @"/"
								withOptions:NSFSEnumerationDefaultOptions
								callback:
			^ BOOL (NSFilesystemEntry *entry) {
				printf("Entry for: %s\n"
					   "\tParent: %s\n"
					   "\tError: %s\n"
					   "\tLevel: %d\n"
					   "\tType: %s\n"
					   "\tDevice: %d\n"
					   "\tMode: %o\n"
					   "\tInode: %llu\n"
					   "\tUID: %d\n"
					   "\tGID: %d\n"
					   "\tSize: %lld\n"
					   "\tAccess time: %f\n"
					   "\tModify time: %f\n"
					   "\tChange time: %f\n"
					   "\tBirth time: %f\n",
					   entry.url.path.UTF8String, entry.parent.url.path.UTF8String, entry.error.description.UTF8String, entry.level,
					   typemap[entry.type].UTF8String, entry.device, entry.mode, entry.inode, entry.uid, entry.gid, entry.size,
					   entry.atime, entry.mtime, entry.ctime, entry.birthtime);
				return YES;
			}
		];
	}
	return 0;
}
