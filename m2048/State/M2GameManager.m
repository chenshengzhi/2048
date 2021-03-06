//
//  M2GameManager.m
//  m2048
//
//  Created by Danqing on 3/16/14.
//  Copyright (c) 2014 Danqing. All rights reserved.
//

#import "M2GameManager.h"
#import "M2Grid.h"
#import "M2Tile.h"
#import "M2Scene.h"
#import "M2ViewController.h"

/**
 * Helper function that checks the termination condition of either counting up or down.
 *
 * @param value The current i value.
 * @param countUp If YES, we are counting up.
 * @param upper The upper bound of i.
 * @param lower The lower bound of i.
 * @return YES if the counting is still in progress. NO if it should terminate.
 */
BOOL iterate(NSInteger value, BOOL countUp, NSInteger upper, NSInteger lower) {
    return countUp ? value < upper : value > lower;
}


@implementation M2GameManager {
    /** True if game over. */
    BOOL _over;
    
    /** True if won game. */
    BOOL _won;
    
    /** The current score. */
    NSInteger _score;
    
    /** The points earned by the user in the current round. */
    NSInteger _pendingScore;
    
    /** The grid on which everything happens. */
    M2Grid *_grid;
    
    /** The display link to add tiles after removing all existing tiles. */
    CADisplayLink *_addTileDisplayLink;
    
    NSInteger _backupScore;
}


+ (instancetype)manager {
    static M2GameManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[M2GameManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if (!_over) {
                [self saveCurrentStateForTerminate];
            }
        }];
    }
    return self;
}

# pragma mark - Setup

- (void)startNewSessionWithScene:(M2Scene *)scene {
    if (!_grid || _grid.dimension != GSTATE.dimension) {
        [_grid.scene enumerateChildNodesWithName:NSStringFromClass([M2Tile class]) usingBlock:^(SKNode *node, BOOL *stop) {
            M2Tile *tile = (M2Tile *)node;
            [tile removeFromParent];
        }];
        
        _grid = [[M2Grid alloc] initWithDimension:GSTATE.dimension];
        _grid.scene = scene;
    } else {
        [_grid removeAllTilesAnimated:NO];
    }
    
    [scene loadBoardWithGrid:_grid];
    
    // Set the initial state for the game.
    _score = 0; _over = NO; _won = NO;
    
    // Existing tile removal is async and happens in the next screen refresh, so we'd wait a bit.
    _addTileDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(addTwoRandomTiles)];
    [_addTileDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


- (void)addTwoRandomTiles {
    // If the scene only has one child (the board), we can proceed with adding new tiles
    // since all old ones are removed. After adding new tiles, remove the displaylink.
    
    M2StateModel *model = [M2StateModel archiveFromDefaultFile];
    if (model) {
        [M2StateModel clearDefaultFile];
        [self loadFromArchive:model];
    } else {
        if (_grid.scene.children.count <= 1) {
            [_grid insertTileAtRandomAvailablePositionWithDelay:NO];
            [_grid insertTileAtRandomAvailablePositionWithDelay:NO];
            [_addTileDisplayLink invalidate];
        }
    }
}


# pragma mark - Actions

- (void)moveToDirection:(M2Direction)direction {
    _backupScore = _score;
    [_grid backupForStepBack];
    
    __block M2Tile *tile = nil;
    
    __block BOOL hasMovement = NO;
    
    // Remember that the coordinate system of SpriteKit is the reverse of that of UIKit.
    BOOL reverse = direction == M2DirectionUp || direction == M2DirectionRight;
    NSInteger unit = reverse ? 1 : -1;
    
    if (direction == M2DirectionUp || direction == M2DirectionDown) {
        [_grid forEach:^(M2Position position) {
            if ((tile = [_grid tileAtPosition:position])) {
                BOOL pending = NO;
                // Find farthest position to move to.
                NSInteger target = position.x;
                for (NSInteger i = position.x + unit; iterate(i, reverse, _grid.dimension, -1); i += unit) {
                    M2Tile *t = [_grid tileAtPosition:M2PositionMake(i, position.y)];
                    
                    if (!t) {
                        // Empty cell; we can move at least to here.
                        target = i;
                    } else {
                        // Try to merge to the tile in the cell.
                        NSInteger level = 0;
                        
                        if (GSTATE.gameType == M2GameTypePowerOf3) {
                            M2Position further = M2PositionMake(i + unit, position.y);
                            M2Tile *ft = [_grid tileAtPosition:further];
                            if (ft) {
                                level = [tile merge3ToTile:t andTile:ft];
                            }
                        } else {
                            level = [tile mergeToTile:t];
                        }
                        
                        if (level) {
                            pending = YES;
                            hasMovement = YES;
                            target = position.x;
                            _pendingScore = [GSTATE valueForLevel:level];
                        }
                        
                        break;
                    }
                }
                
                // The current tile is movable.
                if (!pending && target != position.x) {
                    [tile moveToCell:[_grid cellAtPosition:M2PositionMake(target, position.y)]];
                    hasMovement = YES;
                }
            }
        } reverseOrder:reverse];
    } else {
        [_grid forEach:^(M2Position position) {
            if ((tile = [_grid tileAtPosition:position])) {
                BOOL pending = NO;
                NSInteger target = position.y;
                for (NSInteger i = position.y + unit; iterate(i, reverse, _grid.dimension, -1); i += unit) {
                    M2Tile *t = [_grid tileAtPosition:M2PositionMake(position.x, i)];
                    
                    if (!t) {
                        target = i;
                    } else {
                        NSInteger level = 0;
                        
                        if (GSTATE.gameType == M2GameTypePowerOf3) {
                            M2Position further = M2PositionMake(position.x, i + unit);
                            M2Tile *ft = [_grid tileAtPosition:further];
                            if (ft) {
                                level = [tile merge3ToTile:t andTile:ft];
                            }
                        } else {
                            level = [tile mergeToTile:t];
                        }
                        
                        if (level) {
                            pending = YES;
                            hasMovement = YES;
                            target = position.y;
                            _pendingScore = [GSTATE valueForLevel:level];
                        }
                        
                        break;
                    }
                }
                
                // The current tile is movable.
                if (!pending && target != position.y) {
                    hasMovement = YES;
                    [tile moveToCell:[_grid cellAtPosition:M2PositionMake(position.x, target)]];
                }
            }
        } reverseOrder:reverse];
    }
    
    // Increment score.
    if (_pendingScore) {
        [self materializePendingScore];
    }
    
    if (!hasMovement) {
        return;
    }
    
    // Commit tile movements.
    [_grid forEach:^(M2Position position) {
        M2Tile *tile = [_grid tileAtPosition:position];
        if (tile) {
            [tile commitPendingActions];
            if (tile.level >= GSTATE.winningLevel) _won = YES;
        }
    } reverseOrder:reverse];
    
    // Check post-move status.
    if (_won) {
        // We set `keepPlaying` to YES. If the user decides not to keep playing,
        // we will be starting a new game, so the current state is no longer relevant.
        _won = NO;
        [_grid.scene.controller endGame:YES];
    }
    
    // Add one more tile to the grid.
    [_grid insertTileAtRandomAvailablePositionWithDelay:YES];
    if (GSTATE.dimension == 5 && GSTATE.gameType == M2GameTypePowerOf2)
        [_grid insertTileAtRandomAvailablePositionWithDelay:YES];
    
    if (![self movesAvailable]) {
        _over = YES;
        [_grid.scene.controller endGame:NO];
    }
}


# pragma mark - Score

- (void)materializePendingScore {
    _score += _pendingScore;
    _pendingScore = 0;
    [_grid.scene.controller updateScore:_score];
}


# pragma mark - State checkers

/**
 * Whether there are moves available.
 *
 * A move is available if either there is an empty cell, or there are adjacent matching cells.
 * The check for matching cells is more expensive, so it is only performed when there is no
 * available cell.
 *
 * @return YES if there are moves available.
 */
- (BOOL)movesAvailable {
    return [_grid hasAvailableCells] || [self adjacentMatchesAvailable];
}


/**
 * Whether there are adjacent matches available.
 *
 * An adjacent match is present when two cells that share an edge can be merged. We do not
 * consider cases in which two mergable cells are separated by some empty cells, as that should
 * be covered by the `cellsAvailable` function.
 *
 * @return YES if there are adjacent matches available.
 */
- (BOOL)adjacentMatchesAvailable {
    for (NSInteger i = 0; i < _grid.dimension; i++) {
        for (NSInteger j = 0; j < _grid.dimension; j++) {
            // Due to symmetry, we only need to check for tiles to the right and down.
            M2Tile *tile = [_grid tileAtPosition:M2PositionMake(i, j)];
            
            // Continue with next iteration if the tile does not exist. Note that this means that
            // the cell is empty. For our current usage, it will never happen. It is only in place
            // in case we want to use this function by itself.
            if (!tile) continue;
            
            if (GSTATE.gameType == M2GameTypePowerOf3) {
                if (([tile canMergeWithTile:[_grid tileAtPosition:M2PositionMake(i + 1, j)]] &&
                     [tile canMergeWithTile:[_grid tileAtPosition:M2PositionMake(i + 2, j)]]) ||
                    ([tile canMergeWithTile:[_grid tileAtPosition:M2PositionMake(i, j + 1)]] &&
                     [tile canMergeWithTile:[_grid tileAtPosition:M2PositionMake(i, j + 2)]])) {
                        return YES;
                    }
            } else {
                if ([tile canMergeWithTile:[_grid tileAtPosition:M2PositionMake(i + 1, j)]] ||
                    [tile canMergeWithTile:[_grid tileAtPosition:M2PositionMake(i, j + 1)]]) {
                    return YES;
                }
            }
        }
    }
    
    // Nothing is found.
    return NO;
}



#pragma mark - archives -

- (BOOL)saveCurrentState {
    M2StateModel *model = [[M2StateModel alloc] init];
    model.gameType = GSTATE.gameType;
    model.dimension = GSTATE.dimension;
    model.score = _score;
    model.grids = [_grid dataForArchive];
    model.date = [[NSDate alloc] init];
    
    return [model archive];
}

- (BOOL)saveCurrentStateForTerminate {
    M2StateModel *model = [[M2StateModel alloc] init];
    model.gameType = GSTATE.gameType;
    model.dimension = GSTATE.dimension;
    model.score = _score;
    model.grids = [_grid dataForArchive];
    model.date = [[NSDate alloc] init];
    
    return [model archiveToDefaultFile];
}

- (BOOL)loadFromArchive:(M2StateModel *)model {
    [Settings setInteger:model.gameType forKey:@"Game Type"];
    [Settings setInteger:model.dimension-3 forKey:@"Board Size"];
    [GSTATE loadGlobalState];
    
    if (!_grid || _grid.dimension != GSTATE.dimension) {
        [_grid.scene enumerateChildNodesWithName:NSStringFromClass([M2Tile class]) usingBlock:^(SKNode *node, BOOL *stop) {
            M2Tile *tile = (M2Tile *)node;
            [tile removeFromParent];
        }];
        
        M2Grid *newGrid = [[M2Grid alloc] initWithDimension:GSTATE.dimension];
        newGrid.scene = _grid.scene;
        _grid = newGrid;
    } else {
        [_grid removeAllTilesAnimated:YES];
    }
    
    [_grid.scene loadBoardWithGrid:_grid];
    
    
    [_grid.scene.controller updateState];
    _score = model.score;
    _pendingScore = 0;
    [_grid.scene.controller updateScore:_score];
    
    [model.grids enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSArray *components = [obj componentsSeparatedByString:@"-"];
        if (components.count == 3) {
            NSInteger x = [components[0] integerValue];
            NSInteger y = [components[1] integerValue];
            NSInteger level = [components[2] integerValue];
            
            [_grid insertTileAtPosision:M2PositionMake(x, y) level:level];
        }
    }];
    
    return YES;
}

#pragma mark - setp back -
- (void)stepBack {
    if (_score > 0) {
        [_grid.scene.controller updateScore:_backupScore];
        [_grid stepBack];
    }
}

@end
