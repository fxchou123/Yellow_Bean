//
//  Bee.m
//  Mario
//
//  Created by Yifan Zhou on 3/18/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "Bee.h"
#import "WayPoint.h"
#import "PhysicalWorld.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "Player.h"
#import "GameStatistics.h"

@implementation Bee
{
  WayPoint* _way_point;
  BannerObject* _banner;
  CCSprite* _sprite;
  CCParticleSystem* _effect;
  GameScene* _scene;
  int _score_value;
  float _width,_height;
  int _state;
  BOOL _death;
}

enum {
  STATE_DEVIL_IDLE,
  STATE_DEVIL_EFFECT,
  STATE_DEVIL_DEAD
};

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(GameMapFileObject*) findObject:(NSMutableArray*)collection withKey:(NSString*)key
{
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* obj = [collection objectAtIndex:i];
    if( [obj.name isEqual:key] ) {
      return obj;
    }
  }
  return nil;
}

+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return [[Bee alloc]init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  _scene = scene;
  
  float start_x = [self getPropertyNumber:par withKey:@"StartX"];
  float start_y = [self getPropertyNumber:par withKey:@"StartY"];
  NSMutableArray* collection = [par asCollection];
  GameMapFileObject* object = [self findObject:collection withKey:@"BeeInfo"];
  assert(object);
  NSMutableArray* command = [object asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _width = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  _height = [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  if([[atomic asString] isEqual:@"true"]) {
    _death = YES;
  } else {
    _death = NO;
  }
  
  atomic = [command objectAtIndex:3];
  NSString* sprite_path = [atomic asString];
  
  atomic = [command objectAtIndex:4];
  NSString* particle_path=[atomic asString];
  
  vec2_t start_point;
  start_point.x = start_x + _width/2.0f;
  start_point.y = start_y + _height/2.0f;
  
  
  object = [self findObject:collection withKey:@"WayPoint"];
  _way_point = [[WayPoint alloc] init:object withPoint:start_point withPhysicalWorld:scene.physical_world];
  
  _banner = [scene.physical_world
              addBannerObject:MakeRect(_way_point.position.x,_way_point.position.y,_width,_height)
                  onCollision:@selector(onBannerTopCollision:withShape:)
             onOtherCollision:@selector(onBannerTopCollision:withShape:)
                 onOutOfBound:@selector(onOutOfBound)
                    targetAt:self];
  
  _sprite = [[CCSprite alloc] initWithImageNamed:sprite_path];
  _sprite.scaleX = _width/_sprite.textureRect.size.width;
  _sprite.scaleY = _height/_sprite.textureRect.size.height;
  _effect = [[CCParticleSystem alloc] initWithFile:particle_path];
  
  _sprite.position = ccp(start_point.x,start_point.y);
  [self addChild:_sprite];
  _state = STATE_DEVIL_IDLE;
  
  object = [self findObject:collection withKey:@"ScoreValue"];
  if( object == nil ) {
    _score_value = 0;
  } else {
    NSMutableArray* command = [object asCommand];
    assert(command.count==1);
    atomic =[command objectAtIndex:0];
    _score_value = (int)[atomic asNumber];
  }
  
  return self;
}

-(BOOL) onBannerBodyCollision:(NSObject*)target withShape:(PhysicalShape*)shape
{
  if( [target isKindOfClass:[Player class]] == NO ||
     [_scene.player isPlayerCollided:shape] == NO ) return NO;
  if(_state == STATE_DEVIL_IDLE) {
    [_scene.player die];
    _state = STATE_DEVIL_EFFECT;
    [self removeChild:_sprite];
    _effect.position = _sprite.position;
    [self addChild:_effect];
  }
  return YES;
}

-(BOOL) onBannerTopCollision:(NSObject*)target withShape:(PhysicalShape*)shape
{
  if( [target isKindOfClass:[Player class]] == NO ||
     [_scene.player isPlayerCollided:shape] == NO ) return NO;
  
  if(_state == STATE_DEVIL_IDLE) {
    if(!_death) {
      [_scene.player forceJump];
      _state = STATE_DEVIL_EFFECT;
      [self removeChild:_sprite];
      _effect.position = _sprite.position;
      [self addChild:_effect];
      [_scene.game_statistics addScore:_score_value];
    } else {
      [_scene.player die];
      _state = STATE_DEVIL_EFFECT;
      [self removeChild:_sprite];
      _effect.position = _sprite.position;
      [self addChild:_effect];
    }
  }
  return YES;
}

-(void) onOutOfBound
{
  [_scene removeChild:self];
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case STATE_DEVIL_IDLE:
      _banner.position = MakeVector(_way_point.position.x,_way_point.position.y);
      if([_way_point update:delta] == NO) {
        _state = STATE_DEVIL_EFFECT;
        [self removeChild:_sprite];
        _effect.position = _sprite.position;
        [self addChild:_effect];
        return;
      }
      _sprite.position = ccp(_way_point.position.x,
                             _way_point.position.y);
      return;
    case STATE_DEVIL_EFFECT:
      if( _effect.active == NO && _effect.particleCount == 0) {
        _state = STATE_DEVIL_DEAD;
        [_scene removeChild:self];
      }
    default:
      return;
  }
}


@end
