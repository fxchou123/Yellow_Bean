//
//  WayPointBaseItem.m
//  Mario
//
//  Created by Yifan Zhou on 4/5/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "WayPointBaseItem.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "WayPoint.h"
#import "PhysicalWorld.h"


// ----------------------------------------------------------------------------------------
// WayPointBaseItem will help to parse the way point related item problem !
// It includes:
// [StartX:300]
// [StartY:300]
// AName = {
//     ItemInfo(Width,Height,...);
//     WayPoint= { ... };
//     ...
// };
// ----------------------------------------------------------------------------------------

@implementation WayPointBaseItem
{
  GameScene* _game_scene;
  WayPoint* _way_point;
  SimpleCollidableObject* _collision_object;
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(GameMapFileObject*) findGMObject:(NSMutableArray*)collection withKey:(NSString*)key
{
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* gm_object = [collection objectAtIndex:i];
    if( [gm_object.name isEqual:key] ) {
      return gm_object;
    }
  }
  return nil;
}

-(void) initItemInfo:(GameMapFileObject*)par withStartX:(float)startX withStartY:(float)startY
{
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  float width = [atomic asNumber];
  atomic = [command objectAtIndex:1];
  float height =[atomic asNumber];
  // Fix Bugs:
  // Bound for SimpleCollisionObject should be relative position
  rect_t bound = MakeRect( startX-_game_scene.physical_world.absolute_position.x + width/2.0f ,
                           startY-_game_scene.physical_world.absolute_position.y + height/2.0f,
                           width,height);
  _collision_object = [_game_scene.physical_world
                       addSimpleCollidableObject:bound
                       onCollision:@selector(onCollision:withShape:)
                       onOutOfBound:@selector(onOutOfBound)
                       targetAt:self];
}

-(BOOL) onCollision:(NSObject *)object withShape:(PhysicalShape *)shape
{
  // DO NOTHING
  return NO;
}

-(BOOL) onOutOfBound
{
  return YES;
}
                                             

-(id) init:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  self = [super init];
  if( self == nil ) return nil;
  _game_scene = scene;
  assert(par.type == GM_OBJECT_COLLECTION);
  NSMutableArray* collection = [par asCollection];
  
  // We need to grab the StartX and StartY
  float StartX = [self getPropertyNumber:par withKey:@"StartX"];
  float StartY = [self getPropertyNumber:par withKey:@"StartY"];
  // (1) Find out the ItemInfo section
  GameMapFileObject* gm_object = [self findGMObject:collection withKey:@"ItemInfo"];
  assert(gm_object);
  [self initItemInfo:gm_object withStartX:StartX withStartY:StartY];
  // (2) Initialize WayPoint object
  gm_object = [self findGMObject:collection withKey:@"WayPoint"];
  assert(gm_object);
  _way_point = [[WayPoint alloc]init:gm_object withPoint:MakeVector(_collision_object.bound.x,
                                                                    _collision_object.bound.y)
                withPhysicalWorld:scene.physical_world];
  return self;
}


@end
