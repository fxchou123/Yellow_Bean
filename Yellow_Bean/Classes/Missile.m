//
//  Missle.m
//  prototype
//
//  Created by Yifan Zhou on 3/2/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "Missile.h"
#import "CCDrawingPrimitives.h"
#import "PhysicalWorld.h"
#import "CCSprite.h"
#import "Player.h"
#import "CCParticleSystem.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "CCColor.h"
#import "SoundManager.h"

@class Missile;

@interface MissileWarning : CCNode
-(id) initWithTime:(float)duration
        startColor:(CCColor*)start endColor:(CCColor*)end
        withDirection:(vec2_t)dir withPoint:(vec2_t)pt
        withScene:(GameScene*)scene;

@property (readonly) BOOL alive;
@end

@implementation MissileWarning
{
  float _step_R;
  float _step_G;
  float _step_B;
  float _step_A;
  float _cur_time;
  float _duration;
  int _state;
  CGPoint _start_point;
  CGPoint _end_point;
  float _cur_R;
  float _cur_G;
  float _cur_B;
  float _cur_A;
  float _line_width;
}

enum {
  COLOR_UP,
  COLOR_DOWN
};

-(BOOL) alive
{
  return _cur_time < _duration;
}

-(id) initWithTime:(float)duration
      startColor:(CCColor*)start endColor:(CCColor*)end
      withDirection:(vec2_t)dir withPoint:(vec2_t)pt
      withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  
  _line_width = 8.0f;
  
  if(dir.x == 0.0f) {
    _start_point.x = pt.x;
    _start_point.y = scene.physical_world.viewport.y;
    _end_point.x = pt.x;
    _end_point.y = scene.physical_world.viewport.y+scene.physical_world.viewport.height;
  } else if(dir.y == 0.0f) {
    _start_point.x = scene.physical_world.viewport.x;
    _start_point.y = pt.y;
    _end_point.x = scene.physical_world.viewport.x + scene.physical_world.viewport.width;
    _end_point.y = pt.y;
  } else {
    float k = dir.y/dir.x;
    float b = pt.y-k*pt.x;
    _start_point.x = scene.physical_world.viewport.x;
    _start_point.y = k*_start_point.x + b;
    _end_point.y = scene.physical_world.viewport.y;
    _end_point.x = (_end_point.y-b)/k;
  }
  
  const float time_step = duration/2.0f;
  _step_A = (end.alpha-start.alpha)/time_step;
  _step_R = (end.red-start.red)/time_step;
  _step_G = (end.green-start.green)/time_step;
  _step_B = (end.blue-start.blue)/time_step;
  _cur_time = 0.0f;
  _duration = duration;
  _state = COLOR_UP;
  _cur_R = start.red;
  _cur_A = start.alpha;
  _cur_G = start.green;
  _cur_B = start.blue;
  
  [scene.sound_manager playEffect:@"MissileAlert"];
  return self;
}

-(void) draw
{
  [super draw];
  ccDrawColor4F(_cur_R, _cur_G, _cur_B, _cur_A);
  glLineWidth(_line_width);
  ccDrawLine(_start_point,_end_point);
}


-(void) update:(CCTime)delta
{
  _cur_time += delta;
  if(_cur_time > _duration)
    return;
  if( _cur_time >= _duration/2.0f && _state == COLOR_UP ) {
    _state = COLOR_DOWN;
    _step_R = -_step_R;
    _step_G = -_step_G;
    _step_B = -_step_B;
    _step_A = -_step_A;
  }
  _cur_R += _step_R*delta;
  _cur_G += _step_G*delta;
  _cur_B += _step_B*delta;
  _cur_A += _step_A*delta;
}

@end


@implementation Missile
{
  SimpleCollidableObject* _collidable_object;
  CCSprite* _sprite;
  CCParticleSystem* _fire;
  CCParticleSystem* _explosion;
  GameScene* _scene;
  MissileWarning* _warning;
  vec2_t _anchor_point;
  vec2_t _speed;
  float _warning_time;
  int _state;
}

enum {
  WARNING,
  FLY,
  EXPLOSION,
  DEAD
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[Missile alloc] init:par withScene:scene];
}


-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  _scene = scene;
  NSMutableArray* command = [par asCommand];
  assert(command.count ==9);
  
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  float x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  float y= [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  float width = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  float height= [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  _speed.x = [atomic asNumber];
  
  atomic = [command objectAtIndex:5];
  _speed.y = [atomic asNumber];
  
  atomic = [command objectAtIndex:6];
  NSString* path = [atomic asString];
  
  NSString* particle_path;
  atomic = [command objectAtIndex:7];
  particle_path = [atomic asString];
  
  NSString* explosion_path;
  atomic = [command objectAtIndex:8];
  explosion_path = [atomic asString];
  
  // Just hard code here
  _warning_time = 1.0f;
  
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
  _fire = [[CCParticleSystem alloc] initWithFile:particle_path];
  _fire.gravity = ccp(-_speed.x,-_speed.y);
  _fire.position = ccp(_anchor_point.x,_anchor_point.y);
  [self addChild:_fire];
  
  _sprite = [[CCSprite alloc] initWithImageNamed:path];
  if( _sprite == nil ) return nil;
  float scale_x = width / _sprite.textureRect.size.width;
  float scale_y = height/ _sprite.textureRect.size.height;
  _sprite.scaleX = scale_x;
  _sprite.scaleY = scale_y;
  vec2_t pictureDir = MakeVector(-1.0f,0.0f);
  _sprite.rotation = VectorGetRotationByAxis(&_speed,&pictureDir);
  _explosion = [[CCParticleSystem alloc] initWithFile:explosion_path];
  _warning = [[MissileWarning alloc] initWithTime:_warning_time
                                    startColor:[CCColor blackColor] endColor:[CCColor redColor]
                                    withDirection:_speed withPoint:_anchor_point
                                    withScene:scene];
  
  [self addChild:_warning];
  _state = WARNING;
  return self;
}


-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if( [object isKindOfClass:[Player class]] && [_scene.player isPlayerCollided:shape]) {
    Player* player = (Player*)object;
    [player die];
    _state = EXPLOSION;
    [_scene shakeScene:1.0f];
    [self removeChild:_fire];
    [self removeChild:_sprite];
    _explosion.position = ccp(_anchor_point.x,_anchor_point.y);
    [self addChild:_explosion];
    [_scene.sound_manager playEffect:@"MissileExplosion"];
    return YES;
  }
  return NO;
}


-(BOOL) onOutOfBound
{
  if( _state != DEAD ) {
    _state = DEAD;
    [_scene removeChild:self];
  }
  return YES;
}

-(void) update:(CCTime)delta
{
  
  switch( _state ) {
    case WARNING:
      if(!_warning.alive) {
        [self removeChild:_warning];
        [self addChild:_sprite];
        [_scene.sound_manager playEffect:@"MissileFire"];
        _state = FLY;
      }
      return;
    case FLY:
      if(_collidable_object.dead) {
        [_scene removeChild:self];
      } else {
        // =======================================
        // We only require collision detection, so
        // the movement of the object is handled by
        // our self
        // =======================================
        vec2_t offset = VectorMul(&_speed,delta);
        _anchor_point = VectorAdd(&offset,&_anchor_point);
        _collidable_object.bound = MakeRect(_anchor_point.x,_anchor_point.y,
                                            _collidable_object.bound.width,
                                            _collidable_object.bound.height);
        _sprite.position = ccp(_anchor_point.x,_anchor_point.y);
        _fire.position = ccp(_anchor_point.x,_anchor_point.y);
      }
      break;
    case EXPLOSION:
      if( _explosion.active == FALSE && _explosion.particleCount == 0 ) {
        [_scene removeChild:self];
        _state = DEAD;
      }
      break;
    default:
      break;
  }
  
  
}

@end
