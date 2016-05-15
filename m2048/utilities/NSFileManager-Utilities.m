//
//  NSFileManager-Utilities.m
//  m2048
//
//  Created by shengzhichen on 15/5/10.
//  Copyright (c) 2015年 Danqing. All rights reserved.
//

#import "NSFileManager-Utilities.h"


NSString *NSDocumentsFolder() {
	return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
}

NSString *NSLibraryFolder() {
	return [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
}

NSString *NSTmpFolder() {
	return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
}

NSString *NSBundleFolder() {
	return [[NSBundle mainBundle] bundlePath];
}

@implementation NSFileManager (Utilities)


+ (NSArray *)filesInFolder:(NSString *)path {
    NSURL *pathUrl = [NSURL fileURLWithPath:path];
    
	NSURL *fileUrl = nil;
    
	NSMutableArray *results = [NSMutableArray array];
    
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:pathUrl includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
    
	while (fileUrl = [dirEnum nextObject])
	{
        NSNumber *isDirectory = nil;
        
        if ([fileUrl getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil]) {
            if (![isDirectory boolValue]) {
                NSString *fileName = [fileUrl path];
                [results addObject:fileName];
            }
        }
	}
	return results;
}

+ (BOOL)fileExist:(NSString *)path {
    BOOL isDirectory = NO;
    BOOL is = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return is && !isDirectory;
}

+ (BOOL)deleteFile:(NSString *)path {
    NSError *error = nil;
    BOOL isSuccess = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!isSuccess) {
        CLog(@"%@", error);
    }
    return isSuccess;
}

@end



