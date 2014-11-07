//
//  BlockBase.h
//  Mario
//
//  Created by Dian Peng on 4/1/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"
@class GameMapFileObject;
@class GameScene;
@class PhysicalEntity;
@class PhysicalShape;

@interface BlockBase : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;

@property GameScene* game_scene;
@property float (friction);
@property float (elasticy);
@property PhysicalEntity* physical_entity;
@property (readonly) PhysicalShape* base_shape;

-(id) init:(GameMapFileObject*)gm_object withScene:(GameScene*)scene withPath:(NSString**)path;

-(id) init:(GameMapFileObject*)gm_object withScene:(GameScene*)scene
    startX:(float)startX startY:(float)startY withPath:(NSString**)path;

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape;
-(void) onOutOfBound;
@end
