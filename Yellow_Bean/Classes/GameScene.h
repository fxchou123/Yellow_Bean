//
//  GameScene.h
//  prototype
//
//  Created by Yifan Zhou on 3/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCScene.h"
#import "GameMapFile.h"
#import "PauseNodeDelegate.h"
#import "GameOverNode.h"
#import "Gold.h"

@class PhysicalWorld;
@class Player;
@class Background;
@class GameStatistics;
@class SoundManager;
// ------------------------------------------------
// A game scene is used to represent a single game.
// It works as a container that includes all the
// game runtime component that can help the game .
// ------------------------------------------------

@interface GameScene : CCScene <PauseNodeDelegate, GameOverNodeDelegate>

@property SoundManager* sound_manager;
@property Player* player;
@property PhysicalWorld* physical_world;
@property GameStatistics* game_statistics;
@property Background* background;
@property (readonly) NSString* current_level_name;

-(void) shakeScene:(float)duration;
-(void) gameOver;
-(id) init:(GameMapFileObject*)object;
-(void) update:(CCTime)delta;
-(void) showGameOverNode;

@end
