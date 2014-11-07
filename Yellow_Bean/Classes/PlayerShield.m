//
//  PlayerShield.m
//  Mario
//
//  Created by Dian Peng on 3/19/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "PlayerShield.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "PhysicalWorld.h"
#import "Player.h"
#import "GameScene.h"
#import "BlinkSprite.h"
#import "SoundManager.h"
#import "WayPoint.h"

@interface PlayerShieldEffect : CCNode<PlayerLifeWatcher>
-(id) init:(CCSprite*)sprite
  withParticle:(CCParticleSystem*)effect
  withInvincibleDuration:(float)invincible_duration
  withDuration:(float)duration
  withSize:(rect_t)size
  withScene:(GameScene*)scene;

-(BOOL) update:(Player *)player withDelta:(float)dt;
-(BOOL) onPlayerDieInvoked;
-(void) destroy;
@end



@implementation PlayerShieldEffect
{
  CCSprite* _sprite;
  BlinkSprite* _blink_sprite;
  CCParticleSystem* _effect;
  float _duration;
  float _cur_duration;
  float _invincible_time;
  PlayerAttachObject* _player_attach_object;
  GameScene* _scene;
  int _state;
}

enum {
  STATE_NOT_USED,
  STATE_EFFECT,
  STATE_INVINCIBLE,
  STATE_GONE
};

-(id) init:(CCSprite*)sprite
  withParticle:(CCParticleSystem*)effect
  withInvincibleDuration:(float)invincible_duration
  withDuration:(float)duration
  withSize:(rect_t)size
  withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  
  _sprite = sprite;
  _effect = effect;
  _duration = duration;
  _cur_duration = 0.0f;
  _scene = scene;
  _player_attach_object = [scene.player attachPhysicalShape:CGSizeMake(size.width,size.height)
                                        onCollision:@selector(onCollision:) targetAt:self];
  
  float scale;
  if( size.width > size.height ) {
    scale = size.width / _sprite.textureRect.size.width;
  } else {
    scale = size.height / _sprite.textureRect.size.height;
  }
  _sprite.scale = scale;
  _sprite.position = ccp(size.x,size.y);
  [self addChild:_sprite];
  
  [scene.player addPlayerStateNotification:self withHandler:@selector(onPlayerStateChange:)];
  [scene.player addPlayerLifeWatcher:self];
  _state = STATE_NOT_USED;
  _invincible_time = invincible_duration;
  return self;
}


-(BOOL) onPlayerStateChange:(Player*)player
{
  if( (_state == STATE_INVINCIBLE || _state == STATE_EFFECT) && [player isAlive] == NO ) {
    [_scene removeChild:self];
    return YES;
  } else {
    if(_state == STATE_GONE)
      return YES;
  }
  return NO;
} 

-(BOOL) onCollision:(NSObject*)object
{
  // Do nothing since we don't need this callback
  return NO;
}

-(BOOL) onPlayerDieInvoked
{
  if(_state == STATE_NOT_USED) {
    _state = STATE_INVINCIBLE;
    [self removeChild:_sprite];
    _effect.position = _sprite.position;
    // Add a simple blink effect for that sprite to indicate invincible
    _blink_sprite = [[BlinkSprite alloc] initWithSprite:_sprite
                                         withFrequency:0.1f withDuration:_invincible_time];
    [self addChild:_blink_sprite];
    return NO;
  } else if( _state == STATE_INVINCIBLE ) {
    // I am in Invincible status
    return NO;
  }
  return YES;
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case STATE_NOT_USED:
      _sprite.position = ccp(_player_attach_object.physical_shape.entity.position.x,
                             _player_attach_object.physical_shape.entity.position.y);
      return;
    case STATE_INVINCIBLE:
      if(!_blink_sprite.alive) {
        [self removeChild:_blink_sprite];
        [self addChild:_effect];
        _effect.position = ccp(_player_attach_object.physical_shape.entity.position.x,
                               _player_attach_object.physical_shape.entity.position.y);
        _state = STATE_EFFECT;
      } else {
        [_blink_sprite setSpritePosition:_player_attach_object.physical_shape.entity.position];
      }
      return;
    case STATE_EFFECT:
      if(_effect.particleCount == 0 && _effect.active==NO) {
        [_scene.player removePhysicalShape:_player_attach_object];
        [_scene removeChild:self];
        // -------------------------------------------
        // Removing your player attach object here !!
        // -------------------------------------------
        _state = STATE_GONE;
      }
      return;
    default:
      return;
  }
}

-(BOOL) update:(Player *)player withDelta:(float)dt
{
  // Removing self here
  switch(_state) {
    case STATE_NOT_USED:
      _cur_duration += dt;
      if(_cur_duration > _duration) {
        if(_state != STATE_EFFECT) {
          // Expire here
          _state = STATE_EFFECT;
          [self removeChild:_sprite];
          _effect.position = _sprite.position;
          [self addChild:_effect];
        }
        return YES;
      }
    case STATE_INVINCIBLE:
      return NO;
    case STATE_EFFECT:
    case STATE_GONE:
      return YES;
    default:
      return NO;
  }
}

-(void) destroy
{
  
}

@end

@implementation PlayerShield
{
  CCSprite* _sprite;
  CCParticleSystem* _effect;
  float _effect_duration;
  float _invincible_duration;
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
  return (float)[[command objectAtIndex:0] asNumber];
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

+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return [[PlayerShield alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init:par withScene:scene];
  if( self == nil ) return nil;
  
  GameMapFileObject* gm_object = [self findGameMapObject:par withKey:@"InvincibleDuration"];
  assert(gm_object);
  _invincible_duration = [self queryKeyValueAsFloat:gm_object];
  
  gm_object = [self findGameMapObject:par withKey:@"EffectDuration"];
  assert(gm_object);
  _effect_duration = [self queryKeyValueAsFloat:gm_object];
  
  gm_object = [self findGameMapObject:par withKey:@"Sprite"];
  assert(gm_object);
  NSString* sprite_path = [self queryKeyValueAsString:gm_object];
  
  gm_object = [self findGameMapObject:par withKey:@"Effect"];
  assert(gm_object);
  NSString* effect_path = [self queryKeyValueAsString:gm_object];

  _sprite = [[CCSprite alloc] initWithImageNamed:sprite_path];
  _sprite.scaleX = self.collision_object.bound.width/_sprite.textureRect.size.width;
  _sprite.scaleY = self.collision_object.bound.height/_sprite.textureRect.size.height;
  _sprite.position = ccp(self.collision_object.bound.x,
                         self.collision_object.bound.y);
  
  _effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  [self addChild:_sprite];
  return self;
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if([object isKindOfClass:[Player class]] &&
     [self.game_scene.player isPlayerCollided:shape]) {
    [self removeChild:_sprite];
    [self.game_scene removeChild:self];
    PlayerShieldEffect* shield = [[PlayerShieldEffect alloc] init:_sprite withParticle:_effect
                                   withInvincibleDuration:_invincible_duration
                                   withDuration:_effect_duration
                                   withSize:MakeRect(self.game_scene.player.physical_actor.position.x,
                                                     self.game_scene.player.physical_actor.position.y,
                                                     self.game_scene.player.width*1.5f,
                                                     self.game_scene.player.height*1.5f)
                                   withScene:self.game_scene];
    [self.game_scene addChild:shield z:self.game_scene.player.zOrder];
    [self.game_scene.sound_manager playEffect:@"PickUp"];
    return YES;
  }
  return NO;
}

-(void) update:(CCTime)delta
{
  if([self.way_point update:delta]) {
    _sprite.position = ccp(self.way_point.position.x,
                           self.way_point.position.y);
    self.collision_object.bound = MakeRect(self.way_point.position.x,
                                           self.way_point.position.y,
                                           self.collision_object.bound.width,
                                           self.collision_object.bound.height);
  }
}

-(BOOL) onOutOfBound
{
  [self.game_scene removeChild:self];
  return YES;
}

@end
