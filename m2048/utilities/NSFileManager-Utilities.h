//
//  NSFileManager-Utilities.h
//  m2048
//
//  Created by shengzhichen on 15/5/10.
//  Copyright (c) 2015年 Danqing. All rights reserved.
//


#import <UIKit/UIKit.h>

NSString *NSDocumentsFolder();

NSString *NSLibraryFolder();

NSString *NSTmpFolder();

NSString *NSBundleFolder();


@interface NSFileManager (Utilities)

+ (NSArray *)filesInFolder:(NSString *)path;

+ (BOOL)fileExist:(NSString *)path;

+ (BOOL)deleteFile:(NSString *)path;

@end

