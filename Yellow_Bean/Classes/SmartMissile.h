//
//  SmartMissile.h
//  Mario
//
//  Created by Yifan Zhou on 3/8/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"


@class GameMapFileObject;
@class GameScene;

@interface SmartMissile : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
