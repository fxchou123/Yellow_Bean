//
//  ScoreLevelUp.h
//  Mario
//
//  Created by Dian Peng on 4/5/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "WayPointBaseItem.h"

@class GameMapFileObject;
@class GameScene;


@interface GoldLevelUp : WayPointBaseItem
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
