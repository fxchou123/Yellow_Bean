//
//  PlayerEffectBrick.h
//  prototype
//
//  Created by Dian Peng on 3/2/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BrickBase.h"

@interface PlayerEffectBrick : BrickBase
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end

//// -----------------------------------------------------------
//// The possible effect right now for the player effect brick
//// 1. Floating effect
//// 2. Offset effect
//// 3. Scale effect
//// -----------------------------------------------------------
