//
//  PlayerEffectBrick.m
//  prototype
//
//  Created by Dian Peng on 3/2/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "PlayerEffectBrick.h"
#import "RepeatableSprite.h"
#import "PhysicalWorld.h"
#import "Player.h"
#import "GameMapFile.h"
#import "GameScene.h"

// ---------------------------
// Floating effect
// ---------------------------

@interface FloatEffect: NSObject<PlayerEffect>

-(void) takeEffect:(Player *)player withDelta:(float)dt;
-(BOOL) isAlive;
-(void) destroy;

-(id) init:(float) max min:(float) min frequency:(float) freq expire:(float)timer;
+(id) createObject:(GameMapFileObject*) object;
@end



@implementation FloatEffect
{
  float _value_max,_value_min;
  float _steps;
  float _timer;
  float _expire_timer;
  float _cur_value;
}

+(id) createObject:(GameMapFileObject*) object
{
  float value_max , value_min , freq , timer;
  NSMutableArray* collection = [object asCommand];
  assert(collection.count ==4);
  GameMapFileObjectAtomic* atomic = [collection objectAtIndex:0];
  value_max = [atomic asNumber];
  atomic = [collection objectAtIndex:1];
  value_min = [atomic asNumber];
  atomic = [collection objectAtIndex:2];
  freq = [atomic asNumber];
  atomic = [collection objectAtIndex:3];
  timer = [atomic asNumber];
  return [[FloatEffect alloc] init:value_max min:value_min frequency:freq expire:timer];
}


-(id) init:(float)max min:(float)min frequency:(float)freq expire:(float)timer
{
  self = [super init];
  if( self == nil ) return nil;
  _value_max = max;
  _value_min = min;
  assert(max>min);
  assert(!FLOAT_ZERO(freq));
  _steps = (max - min)/freq;
  _timer = 0.0f;
  _expire_timer = timer;
  _cur_value = _value_min;
  return self;
}

-(void) takeEffect:(Player *)player withDelta:(float)dt
{
  _timer += dt;
  if( _timer > _expire_timer ) return;
  _cur_value += _steps;
  if( _cur_value > _value_max  ) {
    _steps = -_steps;
    _cur_value = _value_max;
  } else if( _cur_value < _value_min ) {
    _steps = -_steps;
    _cur_value = _value_min;
  }
  vec2_t force;
  force.y = _cur_value;
  force.x = 0.0f;
  [player.physical_actor setImpulse:force];
}

-(BOOL) isAlive
{
  return _timer < _expire_timer;
}

-(void) destroy
{
  
}

@end




// ---------------------------------------------
// Jump Effect
// ---------------------------------------------

@interface JumpCoolDownEffect: NSObject<PlayerEffect>

-(void) takeEffect:(Player *)player withDelta:(float)dt;
-(BOOL) isAlive;
-(void) destroy;

+(id) createObject:(GameMapFileObject*) object;
@end



@implementation JumpCoolDownEffect
{
  float _cool_down;
  float _cur_timer;
  float _expire;
  float _original_cool_down;
}


+(id) createObject:(GameMapFileObject*) object
{
  float cool_down ,expire;
  NSMutableArray* collection = [object asCommand];
  assert(collection.count ==2);
  GameMapFileObjectAtomic* atomic = [collection objectAtIndex:0];
  cool_down = [atomic asNumber];
  atomic = [collection objectAtIndex:1];
  expire = [atomic asNumber];
  return [[JumpCoolDownEffect alloc] init:cool_down expire:expire ];
}


-(id) init:(float)cool_down expire:(float)expire
{
  self = [super init];
  if(self == nil)
    return nil;
  _cool_down = cool_down;
  _expire=expire;
  _cur_timer = 0.0f;
  return self;
}

-(void) takeEffect:(Player *)player withDelta:(float)dt
{
  if(_cur_timer == 0.0f) {
    _original_cool_down = player.jump_cool_down;
  } else {
    player.jump_cool_down = _cool_down;
  }
  _cur_timer += dt;
  if( _cur_timer > _expire ) {
    player.jump_cool_down = _original_cool_down;
    return;
  }
}

-(BOOL) isAlive
{
  return _cur_timer < _expire;
}

-(void) destroy
{
  
}

@end

// ---------------------------
// Scale effect
// ---------------------------

@interface ScaleEffect: NSObject<PlayerEffect>

-(void) takeEffect:(Player *)player withDelta:(float)dt;
-(BOOL) isAlive;
-(void) destroy;

+(id) createObject:(GameMapFileObject*) object;
@end



@implementation ScaleEffect
{
  float _cur_timer;
  int _state;
  float _scale_up_timer , _scale_down_timer , _scale_timer;
  float _scale_x , _scale_y;
  float _original_x , _original_y;
  float _step_x, _step_y;
}

enum {
  SCALE_INIT,
  SCALE_UP,
  SCALE_DOWN,
  SCALE,
  SCALE_DONE
};

+(id) createObject:(GameMapFileObject*)object
{
  return [[ScaleEffect alloc]init:object];
}

-(id) init:(GameMapFileObject*) object
{
  self = [super init];
  if( self == nil ) return nil;
  
  NSMutableArray* command = [object asCommand];
  assert(command.count ==5);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _scale_x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  _scale_y = [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  _scale_up_timer = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  _scale_timer = [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  _scale_down_timer = [atomic asNumber];
  
  _state = SCALE_INIT;
  
  return self;
}


-(void) takeEffect:(Player *)player withDelta:(float)dt
{
  switch(_state) {
    case SCALE_INIT:
      _original_x = player.scale_x;
      _original_y = player.scale_y;
      _scale_x *= _original_x;
      _scale_y *= _original_y;
      _step_x = (_scale_x - _original_x)/_scale_up_timer;
      _step_y = (_scale_y - _original_y)/_scale_up_timer;
      _state = SCALE_UP;
      return;
    case SCALE_UP:
      player.scale_x = player.scale_x + _step_x*dt;
      player.scale_y = player.scale_y + _step_y*dt;
      _cur_timer += dt;
      if(_cur_timer > _scale_up_timer) {
        _cur_timer = 0.0f;
        _step_x = (_original_x - player.scale_x)/_scale_down_timer;
        _step_y = (_original_y - player.scale_y)/_scale_down_timer;
        _state = SCALE;
        return;
      }
      return;
    case SCALE:
      _cur_timer += dt;
      if(_cur_timer > _scale_timer ) {
        _cur_timer = 0.0f;
        _state = SCALE_DOWN;
        return;
      }
      return;
    case SCALE_DOWN:
      player.scale_x = player.scale_x + _step_x*dt;
      player.scale_y = player.scale_y + _step_y*dt;
      _cur_timer +=dt;
      if(_cur_timer>_scale_down_timer) {
        player.scale_x = _original_x;
        player.scale_y = _original_y;
        _state = SCALE_DONE;
        return;
      }
      return;
    default:
      return;
  }
}


-(BOOL) isAlive
{
  return _state != SCALE_DONE;
}

-(void) destroy
{
  
}

@end


@implementation PlayerEffectBrick
{
  RepeatableSprite* _sprite;
  GameMapFileObject* _effect_par;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[PlayerEffectBrick alloc] init:par withScene:scene];
}

-(id) createInstance:(NSString*)className withFactoryMethod:(NSString*)factoryMethod
          withObject:(GameMapFileObject*)par
{
  id clazz = NSClassFromString(className);
  if( clazz == nil ) return nil;
  SEL methodInstance = NSSelectorFromString(factoryMethod);
  if( methodInstance == nil ) return nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  return [clazz performSelector:methodInstance withObject:par ];
#pragma clang diagnostic pop
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(id) init:(GameMapFileObject*) par withScene:(GameScene*) scene
{
  self = [super init];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  float startX = [self getPropertyNumber:par withKey:@"StartX"];
  float startY = [self getPropertyNumber:par withKey:@"StartY"];
  // Find brick info
  NSMutableArray* collection = [par asCollection];
  assert(collection.count ==2);
  for( int i = 0 ; i <  2; ++i ) {
    GameMapFileObject* object = (GameMapFileObject*)[collection objectAtIndex:i];
    if( [object.name isEqual:@"BrickInfo"] ) {
      NSString* path;
      self = [self init:object withScene:scene startX:startX startY:startY withPath:&path];
      if( self == nil ) return nil;
      _sprite = [[RepeatableSprite alloc ] initWithImageNamed:path
                                           withWidth:self.physical_entity.width
                                           withHeight:self.physical_entity.height];
      _sprite.position = ccp( self.physical_entity.position.x , self.physical_entity.position.y );
      float scale_x = self.physical_entity.width / _sprite.textureRect.size.width;
      float scale_y = self.physical_entity.height/ _sprite.textureRect.size.height;
      _sprite.scaleX = scale_x;
      _sprite.scaleY = scale_y;
      [self addChild:_sprite];
    } else {
      _effect_par = object;
    }
  }
  return self;
}


-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if( [object isKindOfClass:[Player class]] ) {
    Player* player = (Player*)object;
    // Add a effect here
    id<PlayerEffect> effect = [self createInstance:_effect_par.name withFactoryMethod:@"createObject:" withObject:_effect_par];
    [player addEffect:effect];
    [self.game_scene removeChild:self];
    return YES;
  }
  return NO;
}


-(void) onOutOfBound
{
  [self.game_scene removeChild:self];
}

-(void) update:(CCTime)delta
{
  _sprite.position = ccp(self.physical_entity.position.x,self.physical_entity.position.y);
}

@end
