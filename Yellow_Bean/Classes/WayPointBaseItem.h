//
//  WayPointBaseItem.h
//  Mario
//
//  Created by Yifan Zhou on 4/5/14.
//  Copyright (c) 2014 Yifan Zhous. All rights reserved.
//

#import "CCNode.h"
#import "Item.h"

// A Way Point Base Item is a different type of BaseItem since it
// contains WayPoint class to help us to it better.

@class WayPoint;
@class SimpleCollidableObject;
@class GameScene;
@class GameMapFileObject;
@class PhysicalShape;

@interface WayPointBaseItem : CCNode<Item>

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene;

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape;
-(BOOL) onOutOfBound;

@property SimpleCollidableObject* collision_object;
@property WayPoint* way_point;
@property GameScene* game_scene;

@end
