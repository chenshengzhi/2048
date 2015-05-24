//
//  M2StateModel.m
//  m2048
//
//  Created by shengzhichen on 15/5/11.
//  Copyright (c) 2015年 Danqing. All rights reserved.
//

#import "M2StateModel.h"
#import "NSFileManager-Utilities.h"

@implementation M2StateModel

+ (NSArray *)archivedModels
{
    NSArray *files = [NSFileManager filesInFolder:NSDocumentsFolder()];
    NSMutableArray *modelsArray = [NSMutableArray array];
    for (NSString *path in files) {
        M2StateModel *model = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        model.filePath = path;
        [modelsArray addObject:model];
    }
    [modelsArray sortUsingComparator:^NSComparisonResult(M2StateModel *obj1, M2StateModel *obj2) {
        return obj1.score < obj2.score;
    }];
    return modelsArray;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _gameType = [aDecoder decodeIntegerForKey:@"gameType"];
        _dimension = [aDecoder decodeIntegerForKey:@"dimension"];
        _score = [aDecoder decodeIntegerForKey:@"score"];
        _grids = [aDecoder decodeObjectForKey:@"grids"];
        _date = [aDecoder decodeObjectForKey:@"date"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_gameType forKey:@"gameType"];
    [aCoder encodeInteger:_dimension forKey:@"dimension"];
    [aCoder encodeInteger:_score forKey:@"score"];
    [aCoder encodeObject:_grids forKey:@"grids"];
    [aCoder encodeObject:_date forKey:@"date"];
}


- (BOOL)archive
{
    NSString *fileName = [NSString stringWithFormat:@"%lld.data", (int64_t)[self.date timeIntervalSinceReferenceDate]];
    NSString *filePath = [NSDocumentsFolder() stringByAppendingPathComponent:fileName];
    
    return [NSKeyedArchiver archiveRootObject:self toFile:filePath];
}
@end
