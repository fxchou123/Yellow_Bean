//
//  DynamicConfig.h
//  Mario
//
//  Created by Dian Peng on 4/5/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"

@class GameMapFileObject;
@class GameScene;

// ------------------------------------------------------------------------
// Dyanmic Config is used to change the global configuration of the
// game dynamically. It enables the level designer to put such block
// in the game map file and then change the environment configuration,
// eg PhysicalWorld speed, gravity etc.
// ------------------------------------------------------------------------

@interface DynamicConfig : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
