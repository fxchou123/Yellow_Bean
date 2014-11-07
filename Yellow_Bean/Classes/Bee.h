//
//  Bee.h
//  Mario
//
//  Created by Yifan Zhou on 3/18/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"


@class GameMapFileObject;
@class GameScene;

@interface Bee : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
