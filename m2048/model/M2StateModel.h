//
//  M2StateModel.h
//  m2048
//
//  Created by shengzhichen on 15/5/11.
//  Copyright (c) 2015年 Danqing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface M2StateModel : NSObject <NSCoding>

@property (nonatomic) M2GameType gameType;
@property (nonatomic) NSInteger dimension;
@property (nonatomic) NSInteger score;
@property (nonatomic, strong) NSArray *grids;
@property (nonatomic, strong) NSDate *date;

@property (nonatomic, strong) NSString *filePath;


+ (NSArray *)archivedModels;

- (BOOL)archive;

+ (instancetype)archiveFromDefaultFile;

+ (BOOL)clearDefaultFile;

- (BOOL)archiveToDefaultFile;

@end
