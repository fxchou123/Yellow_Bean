//
//  Spike.h
//  Mario
//
//  Created by Dian Peng on 3/18/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"
@class GameMapFileObject;
@class GameScene;

// Spike is simple. It stays at a certain position and then move. If the player
// hit its top, it gets disappeared, otherwise it will kill the user.
@interface Spike : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)game_scene;
@end
