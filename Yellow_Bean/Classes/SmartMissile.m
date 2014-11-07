//
//  SmartMissile.m
//  Mario
//
//  Created by Yifan Zhou on 3/8/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "SmartMissile.h"
#import "CCSprite.h"
#import "CCParticleSystem.h"
#import "Misc.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "PhysicalWorld.h"
#import "Player.h"
#import "SoundManager.h"

@implementation SmartMissile
{
  GameScene* _scene;
  CCSprite* _sprite;
  CCParticleSystem* _fire;
  CCParticleSystem* _explosion;
  SimpleCollidableObject* _collidable_object;
  float _speed;
  vec2_t _cur_speed;
  vec2_t _anchor_point;
  // lock radius
  float _lock_radius;
  float _cur_radius;
  
  int _state;
}


enum {
  CHASING,
  LOCK,
  EXPLOSION,
  DEAD
};

+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return [[SmartMissile alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [self init];
  if( self == nil ) return nil;
  _scene = scene;
  // (1) Grab the appearing bound of the missile
  NSMutableArray* command = [par asCommand];
  assert( command.count ==9 );
  
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  float x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  float y = [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  float width = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  float height = [atomic asNumber];
  
  // (2) Grab the lock radius/ lock fly radius
  atomic = [command objectAtIndex:4];
  _lock_radius = [atomic asNumber];
  
  // (3) Grab the speed
  atomic = [command objectAtIndex:5];
  _speed = [atomic asNumber];
  
  // (4) texture/tail/explosion
  NSString* texture_path;
  NSString* tail_path;
  NSString* explosion_path;
  atomic = [command objectAtIndex:6];
  texture_path = [atomic asString];
  
  atomic = [command objectAtIndex:7];
  tail_path = [atomic asString];
  
  atomic = [command objectAtIndex:8];
  explosion_path = [atomic asString];
  
  // -------------------------------------
  // Do real initialization here
  // -------------------------------------
  if( [_scene.player isAlive] == FALSE ) {
    return nil;
  } else {
    _state = CHASING;
  }
  
  _anchor_point.x = x + width/2.0f;
  _anchor_point.y = y + height/2.0f;
  
  rect_t bound;
  bound.x = _anchor_point.x;
  bound.y = _anchor_point.y;
  bound.width = width;
  bound.height= height;
  
  
  _collidable_object = [scene.physical_world addSimpleCollidableObject:bound
                                             onCollision:@selector(onCollision:withShape:)
                                             onOutOfBound:@selector(onOutOfBound)
                                             targetAt:self];
  
  _sprite = [[CCSprite alloc] initWithImageNamed:texture_path];
  _fire = [[CCParticleSystem alloc] initWithFile:tail_path];
  float scale_x = width / _sprite.textureRect.size.width;
  float scale_y = height/ _sprite.textureRect.size.height;
  _sprite.scaleX = scale_x;
  _sprite.scaleY = scale_y;
  
  _explosion= [[CCParticleSystem alloc] initWithFile:explosion_path];
  _fire.position = ccp(_anchor_point.x,_anchor_point.y);
  _explosion.position = ccp(_anchor_point.x,_anchor_point.y);
  [self addChild:_fire];
  [self addChild:_sprite];
  [scene.player addPlayerStateNotification:self withHandler:@selector(onPlayerStateChange:)];
  [scene.sound_manager playEffect:@"MissileFire"];
  return self;
}


-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
    if( [object isKindOfClass:[Player class]] && [_scene.player isPlayerCollided:shape]) {
    Player* player = (Player*)object;
    [player die];
    if( _state != EXPLOSION ) {
      _state = EXPLOSION;
      [self removeChild:_sprite];
      [self removeChild:_fire];
      [self addChild:_explosion];
      [_scene.sound_manager playEffect:@"MissileExplosion"];
      _explosion.position = ccp(_anchor_point.x,_anchor_point.y);
      return YES;
    }
    return NO;
  }
  return NO;
}

-(BOOL) onOutOfBound
{
  if( _state != DEAD) {
    [_scene removeChild:self];
    _state = DEAD;
  }
  
  return YES;
}


-(BOOL) onPlayerStateChange:(Player*)player
{
  switch(_state) {
    case DEAD:
    case EXPLOSION:
      return YES;
    default:
      if([player isAlive] == NO) {
        _state = EXPLOSION;
        [self removeChild:_sprite];
        [self removeChild:_fire];
        [self addChild:_explosion];
        _explosion.position = ccp(_anchor_point.x,_anchor_point.y);
        return YES;
      }
      return NO;
  }
}


-(void) update:(CCTime)delta {
  
  switch(_state) {
    case CHASING: {
      Player* p = _scene.player;
      // Grab the chasing vector
      vec2_t directionVector;
      directionVector.x = p.scene_position.x - _anchor_point.x;
      directionVector.y = p.scene_position.y - _anchor_point.y;
      // Normalize the vector
      directionVector = VectorNormalize(&directionVector);
      _cur_speed = VectorMul(&directionVector,_speed);
      vec2_t offset = VectorMul(&_cur_speed,delta);
      _anchor_point = VectorAdd(&_anchor_point,&offset);
      _collidable_object.bound = MakeRect(_anchor_point.x,_anchor_point.y,
                                          _collidable_object.bound.width,
                                          _collidable_object.bound.height);
      // Update the position here
      _sprite.position = ccp(_anchor_point.x,_anchor_point.y);
      vec2_t pictureDir = MakeVector(-1.0f,0.0f);
      float rot = VectorGetRotationByAxis(&_cur_speed,&pictureDir);
      _sprite.rotation = rot;
      _fire.position = ccp(_anchor_point.x,_anchor_point.y);
      _fire.gravity = ccp(-_cur_speed.x,-_cur_speed.y);
      // Checking if we need to go to other states
      float distance = sqrt( (_anchor_point.x - p.scene_position.x) *
                             (_anchor_point.x - p.scene_position.x) +
                             (_anchor_point.y - p.scene_position.y) *
                             (_anchor_point.y - p.scene_position.y) );
      if( distance < _lock_radius ) {
        // We need to go to lock states
        _state = LOCK;
      }
      return;
    }
    case LOCK: {
      vec2_t offset = VectorMul(&_cur_speed,delta);
      _anchor_point = VectorAdd(&_anchor_point,&offset);
      _collidable_object.bound = MakeRect(_anchor_point.x,_anchor_point.y,
                                          _collidable_object.bound.width,
                                          _collidable_object.bound.height);
      // Update the position here
      _sprite.position = ccp(_anchor_point.x,_anchor_point.y);
      _fire.position = ccp(_anchor_point.x,_anchor_point.y);
      _fire.gravity = ccp(-_cur_speed.x,-_cur_speed.y);
      return;
    }
      
    case EXPLOSION:
      if( _explosion.active == FALSE && _explosion.particleCount == 0 ) {
        [_scene removeChild:self];
        _state = DEAD;
      }
      return;
    default:
      return;
  }
}




@end













