//
//  BaseItem.h
//  Mario
//
//  Created by Dian Peng on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"
#import "Item.h"

@class GameMapFileObject;
@class GameScene;
@class SimpleMovableCollidableObject;
@class PhysicalShape;

@interface BaseItem : CCNode<Item>
-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene;

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
  withStartX:(float)startX
  withStartY:(float)startY;

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape;
-(BOOL) onOutOfBound;

@property GameScene* game_scene;
@property SimpleMovableCollidableObject* movable_object;
@end
