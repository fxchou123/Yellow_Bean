
//
//  ScoreBomber.h
//  Mario
//
//  Created by Dian Peng on 3/22/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseItem.h"

@class GameMapFileObject;
@class GameScene;

// ----------------------------------------------------------------
// This class is a interesting class that if the player hit it, it
// will exploded and make all the score around it being hitted and
// added to player. Generally you want to put it into a chunk of the
// scores.
// ----------------------------------------------------------------

@interface GoldBomber : BaseItem
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end










