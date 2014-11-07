//
//  GameStatistics.h
//  Mario
//
//  Created by Dian Peng on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"

@class GameMapFileObject;
@class GameScene;

@interface GameStatistics : CCNode

@property (readonly) float current_distance;
@property (readonly) int current_score;
@property (readonly) int current_gold;

@property (readonly) float player_distance_factor;

@property int player_jump_times;
@property int player_shrink_times;

+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;

-(void) addScore:(int) score;
-(void) removeScore;

-(void) addGold:(int) gold;
-(void) removeGold;

-(void) clear;
-(void) gameOver;

@end


