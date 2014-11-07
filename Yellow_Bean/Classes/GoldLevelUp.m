//
//  ScoreLevelUp.m
//  Mario
//
//  Created by Dian Peng on 4/5/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "GoldLevelUp.h"
#import "WayPointBaseItem.h"
#import "PhysicalWorld.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "Player.h"
#import "SoundManager.h"
#import "WayPoint.h"
#import "Gold.h"

//
//
// [StartX:400]
// [StartY:500]
// ScoreLevelUp = {
//   ItemInfo(width,height);
//   WayPoint = {};
//   Sprite("");
//   Effect("");
//   Range(1000);
// };

@implementation GoldLevelUp
{
  CCSprite* _level_up_sprite;
  CCParticleSystem* _level_up_effect;
  int _state;
  float _range;
  BOOL _start_level_up;
  float _start_position;
  float _world_start_position;
  NSMutableSet* _marked_gold;
}

enum {
  DISPLAY,
  EFFECT,
  DEAD
};

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(NSString*) queryKeyValueAsString:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==1);
  return [[command objectAtIndex:0] asString];
}

-(float) queryKeyValueAsFloat:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==1);
  return [[command objectAtIndex:0] asNumber];
}

-(GameMapFileObject*) findGameMapObject:(GameMapFileObject*)par withKey:(NSString*)key
{
  NSMutableArray* collection = [par asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* gm_object = [collection objectAtIndex:i];
    if([gm_object.name isEqual:key]) {
      return gm_object;
    }
  }
  return nil;
}


+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[GoldLevelUp alloc] init:par withScene:scene];
}


-(id) init:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  self = [super init:par withScene:scene];
  if( self == nil ) return nil;
  GameMapFileObject* gm_object = [self findGameMapObject:par withKey:@"Sprite"];
  assert(gm_object);
  NSString* sprite_path = [self queryKeyValueAsString:gm_object];
  _level_up_sprite = [[CCSprite alloc] initWithImageNamed:sprite_path];
  
  gm_object = [self findGameMapObject:par withKey:@"Effect"];
  assert(gm_object);
  NSString* effect_path = [self queryKeyValueAsString:gm_object];
  _level_up_effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  
  gm_object = [self findGameMapObject:par withKey:@"Range"];
  assert(gm_object);
  _range = [self queryKeyValueAsFloat:gm_object];
  
  _level_up_sprite.scaleX = self.collision_object.bound.width / _level_up_sprite.textureRect.size.width;
  _level_up_sprite.scaleY = self.collision_object.bound.height/ _level_up_sprite.textureRect.size.height;
  _level_up_sprite.position = ccp(self.collision_object.bound.x,
                               self.collision_object.bound.y);
  
  [self addChild:_level_up_sprite];
  _state = DISPLAY;
  _start_level_up = NO;
  return self;
}


-(void) startLevelUp
{
  if(_start_level_up) {
    // 1. Judge that if we need to do so or not
    if( self.game_scene.physical_world.absolute_position.x - _world_start_position >= _range ) {
      // We are done here
      _state = DEAD;
      [self.game_scene removeChild:self];
      return;
    }
    // We start to do level up here
    NSArray* children = self.game_scene.children;
    for( int i = 0 ; i < children.count ; ++ i ) {
      NSObject* child = [children objectAtIndex:i];
      if( [child conformsToProtocol:@protocol(GoldProtocol)] ) {
        if( ![_marked_gold containsObject:child] ) {
          id<GoldProtocol> gold = (id<GoldProtocol>)child;
          if( [gold scene_position].x > _start_position ) {
            [_marked_gold addObject:child];
            [gold levelUp];
          }
        }
      }
    }
  }
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case DISPLAY:
      if([self.way_point update:delta]) {
        _level_up_sprite.position = ccp(self.way_point.position.x,
                                     self.way_point.position.y);
        self.collision_object.bound = MakeRect(self.way_point.position.x,
                                               self.way_point.position.y,
                                               self.collision_object.bound.width,
                                               self.collision_object.bound.height);
      } else {
        [self removeChild:_level_up_sprite];
      }
      break;
    default:
      break;
  }
  // Let's tick for the level up
  [self startLevelUp];
}


-(BOOL) onCollision:(NSObject *)object withShape:(PhysicalShape *)shape
{
  // When collision happened, the ScoreUpdate needs to update all the
  // score on the ground.
  if( [object isKindOfClass:[self.game_scene.player class]] &&
     [self.game_scene.player isPlayerCollided:shape] ) {
    if( _state == DISPLAY ) {
      _state = EFFECT;
      [self removeChild:_level_up_sprite];
      [self addChild:_level_up_effect];
      _level_up_effect.position = _level_up_sprite.position;
      [self.game_scene.sound_manager playEffect:@"GoldLevelUp"];
      //  Force all the score on the ground to level up
      _start_level_up = YES;
      _start_position = self.collision_object.bound.x;
      _world_start_position = self.game_scene.physical_world.absolute_position.x;
      _marked_gold = [[NSMutableSet alloc] init];
    }
    return YES;
  }
  return NO;
}

-(BOOL) onOutOfBound
{
  if(!_start_level_up && _state != DEAD) {
    _state = DEAD;
    [self.game_scene removeChild:self];
  }
  return YES;
}

@end
