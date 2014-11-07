//
//  ScoreMagnet.m
//  Mario
//
//  Created by Yifan Zhou on 3/10/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "GoldMagnet.h"
#import "Player.h"
#import "GameScene.h"
#import "GameMapFile.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "PhysicalWorld.h"
#import "Gold.h"
#import "NodeRotator.h"
#import "SoundManager.h"
#import "WayPoint.h"

// ----------------------------------------------------------
// Magnet effect for player. This effect is an effect that will
// attach to a specific player and then act as a magnet that
// can obsorb the score around it.
// ----------------------------------------------------------

// ----------------------------------------------------------
// New Version Score Magnet
//
// ScoreMagnet = {
//    ItemInfo(width,height);
//    Sprite("");
//    MagnetEffect(...);
//    WayPoint = {};
// };
// ----------------------------------------------------------

@interface GoldMagnetEffect : CCNode

@end

@implementation GoldMagnetEffect
{
  float _effect_duration;
  float _cur_effect_time;
  CCParticleSystem* _effect;
  CCParticleSystem* _fade_out;
  int _state;
  float _speed;
  PlayerAttachObject* _magnet_shape;
  GameScene* _scene;
  NodeRotator* _rotator;
  id _player_callback_key;
}

enum {
  EFFECT,
  FADE_OUT,
  DEAD
};

-(id) init:(GameScene*)scene withSize:(CGSize)size
withDuration:(float)duration withSpeed:(float)speed
withEffectPath:(NSString*)effect_path withFadeOutPath:(NSString*)fade_out_path
withEffectRadius:(float)radius withEffectFrequency:(float)frequency
{
  self = [super init];
  if(self == nil) return nil;
  
  _scene = scene;
  _cur_effect_time = 0.0f;
  _effect_duration = duration;
  _speed = speed;
  _magnet_shape = [scene.player attachPhysicalShape:size onCollision:@selector(onCollision:) targetAt:self];
  _state = EFFECT;
  _effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  _fade_out=[[CCParticleSystem alloc] initWithFile:fade_out_path];
  _effect.particlePositionType = CCParticleSystemPositionTypeFree;
  _rotator = [[NodeRotator alloc] init:_magnet_shape.physical_shape.entity.position
                            withRadius:radius withFrequency:frequency];
  [_rotator setTarget:_effect];
  [self addChild:_rotator];
  [scene.player addPlayerStateNotification:self withHandler:@selector(onPlayerStateChange:)];
  return self;
}


-(BOOL) onPlayerStateChange:(Player*)player
{
  if( _state == DEAD )
    return YES;
  
  if( [player isAlive] == NO ) {
    [_scene removeChild:self];
    _state = DEAD;
    return YES;
  }
  
  return NO;
}


-(void) update:(CCTime)delta
{
  switch(_state) {
    case EFFECT:
      _cur_effect_time += delta;
      if( _cur_effect_time > _effect_duration ) {
        [self removeChild:_rotator];
        [self addChild:_fade_out];
        _state = FADE_OUT;
        return;
      }
      _rotator.anchor_point = _magnet_shape.physical_shape.entity.position;
      return;
    case FADE_OUT:
      _fade_out.position = ccp(_magnet_shape.physical_shape.entity.position.x,
                      _magnet_shape.physical_shape.entity.position.y);
      if( _fade_out.active == NO && _fade_out.particleCount == 0 ) {
        [_scene.player removePhysicalShape:_magnet_shape];
        [_scene removeChild:self];
        _state = DEAD;
      }
      return;
    default:
      return;
  }
}


-(BOOL) onCollision:(NSObject*)object
{
  if([object conformsToProtocol:@protocol(GoldProtocol)] ) {
    id<GoldProtocol> score_object = (id<GoldProtocol>)object;
    // Changing the score speed
    vec2_t player_position = _magnet_shape.physical_shape.entity.position;
    vec2_t score_position = score_object.scene_position;
    vec2_t dir = VectorSub(&player_position,&score_position);
    dir = VectorNormalize(&dir);
    [score_object setSpeed:VectorMul(&dir,_speed)];
  }
  return NO;
}


@end

@implementation GoldMagnet
{
  CCSprite* _sprite;
  // Effect parameter
  float _magnet_width , _magnet_height;
  float _magnet_duration, _magnet_speed;
  NSString* _magnet_effect_path;
  NSString* _magnet_fade_out_path;
  float _magnet_effect_radius ;
  float _magnet_effect_frequency;
  int _state;
}

enum {
  SM_DISPLAY,
  SM_DEAD
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[GoldMagnet alloc] init:par withScene:scene];
}

-(GameMapFileObject*) findGameMapObject:(GameMapFileObject*)object withKey:(NSString*)key
{
  NSMutableArray* collection = [object asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* gm_object = (GameMapFileObject*)[collection objectAtIndex:i];
    if( [gm_object.name isEqual:key] ) {
      return gm_object;
    }
  }
  return nil;
}

-(NSString*) queryKeyValueAsString:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==1);
  return [[command objectAtIndex:0] asString];
}

-(void) initMagnetEffect:(GameMapFileObject*)object
{
  NSMutableArray* command = [object asCommand];
  assert(command.count == 8);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _magnet_width = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  _magnet_height = [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  _magnet_duration = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  _magnet_speed = [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  _magnet_effect_path = [atomic asString];
  
  atomic = [command objectAtIndex:5];
  _magnet_effect_radius = [atomic asNumber];
  
  atomic = [command objectAtIndex:6];
  _magnet_effect_frequency = [atomic asNumber];
  
  atomic = [command objectAtIndex:7];
  _magnet_fade_out_path = [atomic asString];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init:par withScene:scene];
  if( self == nil ) return nil;
  // 1. Sprite loads
  GameMapFileObject* gm_object = [self findGameMapObject:par withKey:@"Sprite"];
  assert(gm_object);
  NSString* sprite_path = [self queryKeyValueAsString:gm_object];
  _sprite = [[CCSprite alloc] initWithImageNamed:sprite_path];
  _sprite.position = ccp(self.collision_object.bound.x,
                         self.collision_object.bound.y);
  [self addChild:_sprite];
  _sprite.scaleX = self.collision_object.bound.width/_sprite.textureRect.size.width;
  _sprite.scaleY = self.collision_object.bound.height/_sprite.textureRect.size.height;
  
  // 2. Magnet loads
  gm_object = [self findGameMapObject:par withKey:@"MagnetEffect"];
  assert(gm_object);
  [self initMagnetEffect:gm_object];
  
  _state = SM_DISPLAY;
  
  return self;
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape *)shape
{
  if( [object isMemberOfClass:[Player class]] &&
      [self.game_scene.player isPlayerCollided:shape] ) {
    // ----------------------------------------------------------
    // Create the Score Magnet Effect and attach it to the player
    // ----------------------------------------------------------
    GoldMagnetEffect* effect = [[
    GoldMagnetEffect alloc] init:self.game_scene
    withSize:CGSizeMake(_magnet_width,_magnet_height)
    withDuration:_magnet_duration withSpeed:_magnet_speed
    withEffectPath:_magnet_effect_path withFadeOutPath:_magnet_fade_out_path
    withEffectRadius:_magnet_effect_radius withEffectFrequency:_magnet_effect_frequency];
    [self.game_scene removeChild:self];
    [self.game_scene.sound_manager playEffect:@"PickUp"];
    [self.game_scene addChild:effect z:self.game_scene.player.zOrder];
    return YES;
  }
  return NO;
}

-(BOOL) onOutOfBound
{
  if( _state != SM_DISPLAY )
    [self.game_scene removeChild:self];
  return YES;
}


-(void) update:(CCTime)delta
{
  if([self.way_point update:delta]) {
    
    self.collision_object.bound = MakeRect(self.way_point.position.x,
                                           self.way_point.position.y,
                                           self.collision_object.bound.width,
                                           self.collision_object.bound.height);
    
    _sprite.position = ccp(self.way_point.position.x,self.way_point.position.y);
    
  } else {
    // We remove our tiny sprite here
    _state = SM_DEAD;
    [self.game_scene removeChild:self];
  }
}


@end
