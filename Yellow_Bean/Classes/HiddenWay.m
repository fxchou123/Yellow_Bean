//
//  HiddenWay.m
//  Mario
//
//  Created by Yifan Zhou on 4/4/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "HiddenWay.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "WayPoint.h"
#import "PhysicalWorld.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "Player.h"
#import "SoundManager.h"

//
// [StartX:500]
// [StartY:300]
// HiddenWayItem = {
//  ItemInfo();
//  WayPoint();
//  Sprite("");
//  Effect("");
//  Path = {
//    [StartX:500]
//    [StartY:240]
//    ...
//  };
//  ...
// };

@implementation HiddenWay
{
  CCSprite* _item_sprite;
  CCParticleSystem* _item_effect;
  BOOL _enable_hidden_path;
  int _state;
  NSMutableArray* _hidden_path;
}

enum {
  DISPLAY,
  EFFECT,
  WORK,
  DEAD
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[HiddenWay alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  self = [super init:par withScene:scene];
  if(self ==nil) return nil;
  // (1) Sprite
  GameMapFileObject* gm_object = [self findGameMapObject:par withKey:@"Sprite"];
  assert(gm_object);
  NSString* sprite_path = [self queryKeyValueAsString:gm_object];
  _item_sprite = [[CCSprite alloc] initWithImageNamed:sprite_path];
  _item_sprite.scaleX = (self.collision_object.bound.width/_item_sprite.textureRect.size.width);
  _item_sprite.scaleY = (self.collision_object.bound.height/_item_sprite.textureRect.size.height);
  // (2) Particle
  gm_object = [self findGameMapObject:par withKey:@"Effect"];
  assert(gm_object);
  NSString* effect_path = [self queryKeyValueAsString:gm_object];
  _item_effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  // (3) Path
  gm_object = [self findGameMapObject:par withKey:@"Path"];
  if(gm_object == nil) {
    _hidden_path = [[NSMutableArray alloc] init];
  } else {
    _hidden_path = [gm_object asCollection];
  }
  
  [self addChild:_item_sprite];
  _state = DISPLAY;
  _enable_hidden_path = NO;
  return self;
}

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

-(id) createInstance:(NSString*)className withFactoryMethod:(NSString*)factoryMethod
          withObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return CreateObjectByReflection(className, factoryMethod, par, scene);
}

-(void) modifyPropertyValue:(GameMapFileObject*)object withKey:(NSString*)key withValue:(float)value
{
  GameMapFileObjectProperty* prop = [object getPropertyWithKey:key];
  assert(prop);
  GameMapFileObjectAtomic* atomic = [[GameMapFileObjectAtomic alloc] init];
  [atomic setNumber:value];
  prop.value = atomic;
}

-(void) spawnObjectByPosition:(NSMutableArray*) array withZ:(int)z
{
  // -------------------------------------------------------------
  // In order to test wheather this object should be put into the
  // scene, we need to calculate its left most x/y value. This job
  // is done by seeing its PositionX/PositionY.
  // -------------------------------------------------------------
  vec2_t absolute_position = self.game_scene.physical_world.absolute_position;
  rect_t viewport = self.game_scene.physical_world.viewport;
  // Checking where we need to iterate
  NSMutableArray* discard = [[NSMutableArray alloc]init];
  int len = (int)[array count];
  if( len == 0 ) {
    _state = DEAD;
    return;
  }
  for( int i = 0 ; i < len ; ++i ) {
    GameMapFileObject* game_element = (GameMapFileObject*)[array objectAtIndex:i];
    
    float StartX = [self getPropertyNumber:game_element withKey:@"StartX"];
    float StartY = [self getPropertyNumber:game_element withKey:@"StartY"];
    
    float leftMostX = StartX;
    float leftMostY = StartY;
    
    if( leftMostX -absolute_position.x < viewport.x + viewport.width &&
       leftMostY -absolute_position.y < viewport.y + viewport.height ) {
      
      // ------------------------------------------------------------------------
      // We need to modify the X/Y back to the game map object's properties
      // This is a must since many implementation relies on the StartX/StartY
      // ------------------------------------------------------------------------
      [self modifyPropertyValue:game_element withKey:@"StartX" withValue:leftMostX];
      [self modifyPropertyValue:game_element withKey:@"StartY" withValue:leftMostY];
      
      CCNode* node = [self createInstance:game_element.name
                        withFactoryMethod:@"createObject:withScene:"
                               withObject:game_element
                                withScene:self.game_scene];
      if( node != nil ) {
        [self.game_scene addChild:node z:z];
      }
      [discard addObject:game_element];
    } else {
      break;
    }
  }
  [array removeObjectsInArray:discard];
}


-(void) update:(CCTime)delta
{
  if( _enable_hidden_path ) {
    [self spawnObjectByPosition:_hidden_path withZ:(int)self.zOrder];
  }
  
  switch(_state) {
    case DISPLAY:
      if([self.way_point update:delta]) {
        _item_sprite.position = ccp(self.way_point.position.x,
                                    self.way_point.position.y);
        self.collision_object.bound = MakeRect(self.way_point.position.x,
                                               self.way_point.position.y,
                                               self.collision_object.bound.width,
                                               self.collision_object.bound.height);
      } else {
        // remove self here
        _state = DEAD;
        [self.game_scene removeChild:self];
      }
      return;
    case EFFECT:
      _item_effect.position = ccp(self.game_scene.player.scene_position.x,
                                  self.game_scene.player.scene_position.y);
      if(_item_effect.active == NO && _item_effect.particleCount ==0) {
        _state = WORK;
      }
      return;
    case DEAD:
      [self.game_scene removeChild:self];
      return;
    default:
      return;
  }
}

-(BOOL) onCollision:(NSObject *)object withShape:(PhysicalShape *)shape
{
  if([object isKindOfClass:[self.game_scene.player class]] &&
     [self.game_scene.player isPlayerCollided:shape] ) {
    if(_state == DISPLAY) {
      _state = EFFECT;
      _enable_hidden_path = YES;
      [self removeChild:_item_sprite];
      [self addChild:_item_effect];
      _item_effect.position = ccp(self.game_scene.player.scene_position.x,
                                  self.game_scene.player.scene_position.y);
      [self.game_scene.sound_manager playEffect:@"HiddenWay"];
    }
    return YES;
  }
  return NO;
}

@end






