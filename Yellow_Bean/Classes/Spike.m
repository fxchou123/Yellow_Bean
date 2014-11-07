//
//  Spike.m
//  Mario
//
//  Created by Dian Peng on 3/18/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Spike.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "Player.h"
#import "PhysicalWorld.h"
#import "SoundManager.h"
#import "GameStatistics.h"

@implementation Spike
{
  CCSprite* _sprite;
  CCParticleSystem* _effect;
  BannerObject* _banner;
  GameScene* _game_scene;
  SimpleMovableCollidableObject* _moveable_object;
  int _score_value;
  int _state;
}

enum {
  STATE_PLAY_EFFECT,
  STATE_IDLE
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)game_scene
{
  return [[Spike alloc] init:par withScene:game_scene];
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(id)init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  
  _game_scene= scene;
  SimpleMovableCollidableObjectSettings settings;
  NSMutableArray* command = [par asCommand];
  
  float abs_x = [self getPropertyNumber:par withKey:@"StartX"];
  float abs_y = [self getPropertyNumber:par withKey:@"StartY"];
  
  GameMapFileObjectAtomic* atomic;
  
  atomic = [command objectAtIndex:0];
  settings.width = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  settings.height= [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  settings.speed.x = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  settings.speed.y = [atomic asNumber];
  
  settings.absolute_position.x = abs_x + settings.width/2.0f;
  settings.absolute_position.y = abs_y + settings.height/2.0f;
  
  atomic = [command objectAtIndex:4];
  NSString* sprite_path = [atomic asString];
  
  atomic = [command objectAtIndex:5];
  NSString* effect_path = [atomic asString];
  
  _moveable_object = [scene.physical_world addMovableCollidableObject:&settings onCollision:@selector(onCollision:) onOutOfBound:@selector(onOutOfBound)
                                                             targetAt:self];
  if(command.count == 7) {
    atomic = [command objectAtIndex:6];
    _score_value = [atomic asNumber];
  } else {
    _score_value = 0;
  }
  
  // Initialize banner
  _banner = [scene.physical_world
             addBannerObject:_moveable_object.bound
             onCollision:@selector(onBannerTopCollision:withShape:)
             onOtherCollision:@selector(onBannerBodyCollision:withShape:)
             onOutOfBound:@selector(onOutOfBound)
             targetAt:self];
  
  _sprite = [[CCSprite alloc] initWithImageNamed:sprite_path];
  _effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  _sprite.position = ccp(_moveable_object.bound.x,_moveable_object.bound.y);
  _sprite.scaleX = (settings.width/_sprite.textureRect.size.width);
  _sprite.scaleY = (settings.height/_sprite.textureRect.size.height);
  [self addChild:_sprite];
  _state = STATE_IDLE;
  return self;
}

-(BOOL) onCollision:(NSObject*)object
{
  return NO;
}

-(void) onOutOfBound
{
  
}

-(BOOL) onBannerBodyCollision:(NSObject*)object withShape:(PhysicalShape *)shape
{
  if( [object isKindOfClass:[Player class]] == NO || [_game_scene.player isPlayerCollided:shape] == NO ) return NO;
  if(_state == STATE_PLAY_EFFECT) return YES;
  _state = STATE_PLAY_EFFECT;
  [_game_scene.player die];
  [self removeChild:_sprite];
  [_game_scene.physical_world removeMoveableCollidableObject:_moveable_object];
  _effect.position = _sprite.position;
  [self addChild:_effect];
  [_game_scene.sound_manager playEffect:@"Bomb"];
  return YES;
}

-(BOOL) onBannerTopCollision:(NSObject*)object withShape:(PhysicalShape *)shape
{
  if( [object isKindOfClass:[Player class]] == NO || [_game_scene.player isPlayerCollided:shape] == NO ) return NO;
  if(_state == STATE_PLAY_EFFECT) return YES;
  [_game_scene.player forceJump];
  _state = STATE_PLAY_EFFECT;
  [self removeChild:_sprite];
  [_game_scene.physical_world removeMoveableCollidableObject:_moveable_object];
  _effect.position = _sprite.position;
  [self addChild:_effect];
  [_game_scene.sound_manager playEffect:@"Bomb"];
  // Add the score here
  [_game_scene.game_statistics addScore:_score_value];
  return YES;
}


-(void) update:(CCTime)delta
{
  switch(_state) {
    case STATE_IDLE:
      _sprite.position = ccp(_moveable_object.position.x,
                             _moveable_object.position.y);
      _banner.position = _moveable_object.position;
      break;
    case STATE_PLAY_EFFECT:
      if(_effect.particleCount == 0 && _effect.active == NO) {
        [_game_scene removeChild:self];
        return;
      }
    default:
      return;
  }
}

@end
