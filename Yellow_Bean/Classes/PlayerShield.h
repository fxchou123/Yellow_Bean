//
//  PlayerShield.h
//  Mario
//
//  Created by Dian Peng on 3/19/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WayPointBaseItem.h"


@class GameMapFileObject;
@class GameScene;

/*
 [StartX:17660]
 [StartY:320]
 PlayerShield = {
    ItemInfo(70.0,70.0);
    EffectDuration(20);
    InvincibleDuration(2.0);
    Sprite("");
    Effect("");
    WayPoint = {};
 };
 */

@interface PlayerShield : WayPointBaseItem
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
