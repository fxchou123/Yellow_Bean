//
//  Player.m
//  prototype
//
//  Created by Yifan Zhou on 3/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "Player.h"
#import "CCNode.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "PhysicalWorld.h"
#import "CCDirector.h"
#import "CCSprite.h"
#import "cocos2d-ui.h"
#import "CCParticleSystem.h"
#import "SoundManager.h"
#import "TextureAnimation.h"
#import "BrickBase.h"
#import "GameStatistics.h"

@interface PlayerNotifyObject : NSObject
@end

@implementation PlayerNotifyObject
{
@public
  NSObject* _target;
  SEL _on_state_change;
}
@end

@implementation PlayerAttachObject
{
  @public
  SEL _on_collision;
  PhysicalShape* _attached_shape;
  NSObject* _target;
}

@synthesize physical_shape = _attached_shape;
@end


@implementation Player 
{
  GameScene* _scene;
  TextureAnimation* _stand_sprite;
  TextureAnimation* _shrink_down_sprite;
  TextureAnimation* _shrink_up_sprite;
  TextureAnimation* _jump_sprite;
  TextureAnimation* _cur_sprite;
  PhysicalActor* _actor;
  
  float _cur_jump_timer;
  float _jump_cool_down;
  float _jump_height;
  float _dump_speed;
  
  float _shrink_anim_down_width , _shrink_anim_down_height;
  float _shrink_anim_up_width , _shrink_anim_up_height;
  BOOL _shrink_release;
  
  vec2_t _shrink_scale;
  int _state;
  NSMutableArray* _effect_list;
  NSMutableArray* _attach_object_list;
  NSMutableArray* _observer_list;
  
  PhysicalShape* _stand_up;
  PhysicalShape* _shrink;
  
  // The jump state is used to indicate the current jumping
  // status. It is a separate state to tell how to handle
  // jump statistics.
  int _jump_state;
  
  int _maximum_jump_times;
  int _cur_jump_times;
  
  
  // --------------------------------------------------------------------------
  // Player position recovery !
  // This is a really hard goal since we never prepare it before.
  // I will implement this function by using some small iteration to catch up the
  // goal. 1) The player can only enter such state once we find out that the player
  // is behind the position 2) The player can exit the state once the player hit a
  // target. 3) In order to avoid the artifact by continuouslly changing the speed,
  // we'd like to generate such small portion of movement step by step
  // -----------------------------------------------------------------------------
  
  float _position_recovery_cur_timer;
  float _position_recovery_frequency;
  float _position_recovery_x_step;
  float _target_x_position;
  
  NSMutableArray* _player_life_watcher;
  
}

enum {
  PLAYER_STAND,
  PLAYER_SHRINK_DOWN_ANIM_PLAYING,
  PLAYER_SHRINK,
  PLAYER_SHRINK_UP_ANIM_PLAYING,
  PLAYER_DIE
};

enum {
  JUMP_NO_JUMP,
  JUMP_IN_AIR
};

@synthesize physical_actor = _actor;
@synthesize jump_height = _jump_height;
@synthesize jump_cool_down = _jump_cool_down;
@synthesize jump_time = _jump_time;

-(void) setScale_x:(float)scale_x
{
  _cur_sprite.scaleX = scale_x;
  
}

-(float) scale_x
{
  return _cur_sprite.scaleX;
}

-(void) setScale_y:(float)scale_y
{
  _cur_sprite.scaleY = scale_y;
}

-(float) scale_y
{
  return _cur_sprite.scaleY;
}

-(vec2_t) scene_position
{
  return _actor.position;
}

-(float) width
{
  return _actor.width;
}

-(float) height
{
  return _actor.height;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  id obj = [[Player alloc]init:par withScene:scene];
  return obj;
}


-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}




-(void) initPlayerInfo:(GameMapFileObject*)par
{
  PhysicalActorSettings settings;
  // ----------------------------------------
  // Initialize physical related information
  // This is stored inside of the property
  // ----------------------------------------
  float elasticy = [self getPropertyNumber:par withKey:@"Elasticy"];
  settings.mass = [self getPropertyNumber:par withKey:@"Mass"];
  NSMutableArray* command_list = [par asCommand];
  assert(command_list.count ==10);
  // position X/Y
  GameMapFileObjectAtomic* atomic = [command_list objectAtIndex:0];
  settings.absolute_position.x = [atomic asNumber] + _scene.physical_world.absolute_position.x;
  atomic = [command_list objectAtIndex:1];
  settings.absolute_position.y = [atomic asNumber] + _scene.physical_world.absolute_position.y;
  // width/height
  atomic = [command_list objectAtIndex:2];
  settings.width = [atomic asNumber];
  atomic = [command_list objectAtIndex:3];
  settings.height = [atomic asNumber];
  // Jump information
  atomic = [command_list objectAtIndex:4];
  _jump_cool_down = [atomic asNumber];
  _cur_jump_timer = 0.0f;
  
  atomic = [command_list objectAtIndex:5];
  _maximum_jump_times = (int)[atomic asNumber];
  _cur_jump_times = 0;
  
  atomic = [command_list objectAtIndex:6];
  _jump_height = [atomic asNumber];
  
  _jump_state = JUMP_NO_JUMP;
  // Shrink parameter
  atomic = [command_list objectAtIndex:7];
  float shrink_width = [atomic asNumber];
  
  atomic = [command_list objectAtIndex:8];
  float shrink_height= [atomic asNumber];
  
  atomic = [command_list objectAtIndex:9];
  _dump_speed = [atomic asNumber];
  
  settings.penetration = NO;
  _actor = [_scene.physical_world addPhysicalActor:&settings
                                      onCollision:@selector(onCollision:withShape:)
                                     onOutOfBound:@selector(onOutOfBound)
                                          targetAt:self];
  assert(_actor);
  _stand_up = [_actor createBoxPhysicalShape
               :CGSizeMake(settings.width,settings.height)];
  _stand_up.elasticy = elasticy;
  [_actor addPhysicalShape:_stand_up];
  // Add shrink here
  _shrink = [_actor createBoxPhysicalShape:CGSizeMake(shrink_width,shrink_height)];
  _shrink.elasticy = elasticy;
  _shrink_scale.x = shrink_width/settings.width;
  _shrink_scale.y = shrink_height/settings.height;
  _shrink_release = NO;
}


-(GameMapFileObject*) findObject:(NSMutableArray*)par withKey:(NSString*)key
{
  for( int i = 0 ; i < par.count ; ++i ) {
    GameMapFileObject* object = (GameMapFileObject*)[par objectAtIndex:i];
    if([object.name isEqual:key])
      return object;
  }
  return nil;
}

-(void) initPlayerRun:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  NSString* path = [atomic asString];
  
  atomic = [command objectAtIndex:1];
  int frames = (int)[atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  float frame_rate = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  float width = [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  float height= [atomic asNumber];
  
  _stand_sprite = [[TextureAnimation alloc ]
                   initAnimationWithNamedImage:path
                   withFrames:frames
                   withFrequency:frame_rate
                   withFrameSize:MakeVector(width,height)
                   loop:YES];
  _cur_sprite = _stand_sprite;
  _state = PLAYER_STAND;
}


-(void) initPlayerShrink:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  NSString* path = [atomic asString];
  
  atomic = [command objectAtIndex:1];
  int frames = (int)[atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  float frame_rate = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  float width = [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  float height= [atomic asNumber];
  
  _shrink_up_sprite = [[TextureAnimation alloc ]
                       initAnimationWithNamedImage:path
                       withFrames:frames
                       withFrequency:frame_rate
                       withFrameSize:MakeVector(width,height)
                       loop:NO];
  
  _shrink_anim_up_height = height;
  _shrink_anim_up_width = width;
  
  atomic = [command objectAtIndex:5];
  path = [atomic asString];
  
  atomic = [command objectAtIndex:6];
  frames = (int)[atomic asNumber];
  
  atomic = [command objectAtIndex:7];
  frame_rate = [atomic asNumber];
  
  atomic = [command objectAtIndex:8];
  width = [atomic asNumber];
  
  atomic = [command objectAtIndex:9];
  height= [atomic asNumber];
  
  _shrink_down_sprite = [[TextureAnimation alloc ]
                         initAnimationWithNamedImage:path
                         withFrames:frames
                         withFrequency:frame_rate
                         withFrameSize:MakeVector(width,height)
                         loop:NO];
  _shrink_anim_down_height = height;
  _shrink_anim_down_width = width;
  
}

-(void) initPlayerJump:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  NSString* path = [atomic asString];
  
  atomic = [command objectAtIndex:1];
  int frames = (int)[atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  float frame_rate = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  float width = [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  float height= [atomic asNumber];
  
  _jump_sprite = [[TextureAnimation alloc ]
                       initAnimationWithNamedImage:path
                       withFrames:frames
                       withFrequency:frame_rate
                       withFrameSize:MakeVector(width,height)
                       loop:NO];
  
}

-(void) initPositionRecovery:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==2);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _position_recovery_frequency = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  _position_recovery_x_step = [atomic asNumber];
  
  _position_recovery_cur_timer = 0.0f;
  _target_x_position = _actor.position.x;
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  _scene = scene;
  _effect_list = [[NSMutableArray alloc] init];
  _attach_object_list = [[NSMutableArray alloc] init];
  _observer_list = [[NSMutableArray alloc] init];
  _player_life_watcher = [[NSMutableArray alloc] init];
  // 1. PlayerInfo initialization
  NSMutableArray* collection = [par asCollection];
  GameMapFileObject* object = [self findObject:collection withKey:@"PlayerInfo"];
  assert(object);
  [self initPlayerInfo:object];
  // 2. Run initialization
  object = [self findObject:collection withKey:@"PlayerRun"];
  assert(object);
  [self initPlayerRun:object];
  // 3. Shrink
  object = [self findObject:collection withKey:@"PlayerShrink"];
  assert(object);
  [self initPlayerShrink:object];
  // 4. Jump
  object = [self findObject:collection withKey:@"PlayerJump"];
  assert(object);
  [self initPlayerJump:object];
  // 5. Position Recovery
  object = [self findObject:collection withKey:@"PositionRecovery"];
  assert(object);
  [self initPositionRecovery:object];

  // Add it to the list and finish everything
  _cur_sprite.position = ccp(_actor.position.x,_actor.position.y);
  [self addChild:_cur_sprite];
  return self;
}

-(void) addEffect:(id<PlayerEffect>)effect
{
  [_effect_list addObject:effect];
}

-(PlayerAttachObject*) attachPhysicalShape:(CGSize)size onCollision:(SEL)collision targetAt:(NSObject*)target
{
  PlayerAttachObject* object = [[PlayerAttachObject alloc] init];
  object->_on_collision = collision;
  object->_target = target;
  object->_attached_shape = [_actor createSimpleCollidableBoxShape:size];
  [_actor addPhysicalShape:object->_attached_shape];
  [_attach_object_list addObject:object];
  return object;
}

-(void) removePhysicalShape:(PlayerAttachObject *)object
{
  [_actor removePhysicalShape:object->_attached_shape];
  [_attach_object_list removeObject:object];
}

-(void) addPlayerStateNotification:(NSObject*)object withHandler:(SEL)notifier
{
  PlayerNotifyObject* notify_object = [[PlayerNotifyObject alloc] init];
  notify_object->_target = object;
  notify_object->_on_state_change = notifier;
  [_observer_list addObject:notify_object];
}

-(void) addPlayerLifeWatcher:(id<PlayerLifeWatcher>)watcher
{
  [_player_life_watcher addObject:watcher];
}


-(void) forceJump
{
  // Forcing the jump of the player
  [self addChild:[_actor jump:_jump_height]];
}

-(void) playerJump
{
  // I try to jump in the air
  [self addChild:[_actor jump:_jump_height]];
  [_scene.sound_manager playEffect:@"PlayerJump"];
  _jump_sprite.position = _cur_sprite.position;
  [self removeChild:_cur_sprite];
  [_jump_sprite Replay];
  [self addChild:_jump_sprite];
  _cur_sprite = _jump_sprite;
}

-(void) rightButtonCall
{
  if( _state != PLAYER_DIE ) {
    switch(_jump_state) {
      case JUMP_NO_JUMP:
        [self playerJump];
        _jump_state = JUMP_IN_AIR;
        ++_cur_jump_times;
        _scene.game_statistics.player_jump_times += 1;
        return;
      case JUMP_IN_AIR:
        // The player has already perform a jump
        if( _cur_jump_times < _maximum_jump_times
           && _cur_jump_timer == 0.0f ) {
          // I can jump
          ++_cur_jump_times;
          [self playerJump];
          _cur_jump_timer = _jump_cool_down;
          _scene.game_statistics.player_jump_times += 1;
          return;
        default:
          return;
        }
    }
  }
}

-(void) rightButtonRelease
{
  
}

-(void) leftButtonCall
{
  // Shrink goes here
  if( _state == PLAYER_STAND ) {
    _scene.game_statistics.player_shrink_times += 1;
    _shrink_release = NO;
    _state = PLAYER_SHRINK_DOWN_ANIM_PLAYING;
    [_scene.sound_manager playEffect:@"PlayerShrink"];
    [self removeChild:_cur_sprite];
    _cur_sprite = _shrink_down_sprite;
    [self addChild:_shrink_down_sprite];
    [_shrink_down_sprite Replay];
    // Modifying the _actor position
    [_actor removePhysicalShape:_stand_up];
    [_actor addPhysicalShape:_shrink];
    vec2_t new_pos;
    float new_width = _shrink_scale.x * _actor.width;
    float new_height= _shrink_scale.y * _actor.height;
    new_pos.x = _actor.position.x - _actor.width/2.0f + new_width/2.0f;
    new_pos.y = _actor.position.y - _actor.height/2.0f + new_height/2.0f;
    [_actor setPosition:new_pos];
    [self addChild:[_actor shrink]];
    [self tickPlayerStateNotification];
    
    if(_jump_state == JUMP_IN_AIR) {
      // Dumpping effect goes here
      [_actor dump:-_dump_speed];
    }
    NSLog(@"%f,%f",_actor.speed.x,_actor.speed.y);
    return;
  }
}

-(void) leftButtonRelease
{
  if( _state == PLAYER_SHRINK_DOWN_ANIM_PLAYING || _state == PLAYER_SHRINK ) {
    _shrink_release = YES;
  }
}

-(BOOL) performAttachObjectCallback:(PhysicalShape*)shape withObject:(NSObject*)object {
  for( int i = 0 ; i < _attach_object_list.count ; ++i ) {
    PlayerAttachObject* obj = [_attach_object_list objectAtIndex:i];
    if( obj.physical_shape == shape ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      BOOL ret = [obj->_target performSelector:obj->_on_collision withObject:object];
#pragma clang diagnostic pop
      if( ret == YES ) {
        // Remove this tiny object callback
        [self removePhysicalShape:obj];
        return YES;
      }
    }
  }
  return NO;
}


-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if([object isKindOfClass:[BrickBase class]] && _jump_state == JUMP_IN_AIR) {
    // Resume jump status here
    _cur_jump_times = 0;
    _jump_state = JUMP_NO_JUMP;
  }
  return [self performAttachObjectCallback:shape withObject:object];
}

-(BOOL) isPlayerCollided:(PhysicalShape *)shape
{
  return shape == _shrink || shape == _stand_up;
}


-(void) onOutOfBound
{
  if( _state != PLAYER_DIE ) {
    [self setToDie];
  }
}


-(void) updateCharacterJump:(float)delta
{
  if(_cur_jump_timer > 0.0f)
    _cur_jump_timer -= delta;
  if(_cur_jump_timer < 0.0f)
    _cur_jump_timer = 0.0f;
}

-(void) updatePlayerEffectList:(float)delta
{
  NSMutableIndexSet* discard_array = [[NSMutableIndexSet alloc]init];
  // Tick all the effect that has been added to the player
  for( int i = 0 ; i < [_effect_list count] ; ++i ) {
    id<PlayerEffect> protocol = [_effect_list objectAtIndex:i];
    [protocol takeEffect:self withDelta:(float)delta];
    if([protocol isAlive] == NO) {
      [protocol destroy];
      [discard_array addIndex:i];
    }
  }
  [_effect_list removeObjectsAtIndexes:discard_array];
}

-(void) updatePlayerLifeWatcher:(float)delta
{
  NSMutableIndexSet* discard_array = [[NSMutableIndexSet alloc]init];
  for( int i = 0 ; i < [_player_life_watcher count] ; ++i ) {
    id<PlayerLifeWatcher> watcher = [_player_life_watcher objectAtIndex:i];
    BOOL ret = [watcher update:self withDelta:delta];
    if(ret) {
      [discard_array addIndex:i];
      [watcher destroy];
    }
  }
  [_player_life_watcher removeObjectsAtIndexes:discard_array];
}

-(void) updatePlayerPosition:(float)delta
{
  // Update based on the states for shrinking
  switch(_state) {
    case PLAYER_SHRINK_DOWN_ANIM_PLAYING:
      if([_cur_sprite isStopped]) {
        _state = PLAYER_SHRINK;
      } else {
        float new_width = _shrink_scale.x * _actor.width;
        float new_height= _shrink_scale.y * _actor.height;
        _cur_sprite.position = ccp(_actor.position.x+_actor.width/2.0f-new_width/2.0f,
                                   _actor.position.y+_actor.height/2.0f-new_height/2.0f);
      }
      break;
    case PLAYER_SHRINK: {
      if(_shrink_release) {
        _state = PLAYER_SHRINK_UP_ANIM_PLAYING;
        _shrink_up_sprite.position = _cur_sprite.position;
        [self removeChild:_cur_sprite];
        [_shrink_up_sprite Replay];
        [self addChild:_shrink_up_sprite];
        _cur_sprite = _shrink_up_sprite;
        [self tickPlayerStateNotification];
      } else {
        vec2_t new_pos;
        float new_width = _shrink_scale.x * _actor.width;
        float new_height= _shrink_scale.y * _actor.height;
        new_pos.x = _actor.position.x + _actor.width/2.0f - new_width/2.0f;
        new_pos.y = _actor.position.y + _actor.height/2.0f - new_height/2.0f;
        _cur_sprite.position = ccp(new_pos.x,new_pos.y);
      }
      break;
    }
    case PLAYER_SHRINK_UP_ANIM_PLAYING:
      if([_cur_sprite isStopped]) {
        _state = PLAYER_STAND;
        [_actor removePhysicalShape:_shrink];
        [_actor addPhysicalShape:_stand_up];
        vec2_t new_pos;
        float new_width = _shrink_scale.x * _actor.width;
        float new_height= _shrink_scale.y * _actor.height;
        new_pos.x = _actor.position.x - new_width/2.0f  + _actor.width / 2.0f;
        new_pos.y = _actor.position.y - new_height/2.0f + _actor.height/ 2.0f;
        [_actor setPosition:new_pos];
        _stand_sprite.position = _cur_sprite.position;
        [self removeChild:_cur_sprite];
        [_stand_sprite Replay];
        [self addChild:_stand_sprite];
        _cur_sprite = _stand_sprite;
        return;
      } else {
        vec2_t new_pos;
        float new_width = _shrink_scale.x * _actor.width;
        float new_height= _shrink_scale.y * _actor.height;
        new_pos.x = _actor.position.x + _actor.width/2.0f - new_width/2.0f;
        new_pos.y = _actor.position.y + _actor.height/2.0f - new_height/2.0f;
        _cur_sprite.position = ccp(new_pos.x,new_pos.y);
      }
      break;
    default:
      if([_cur_sprite isStopped]) {
        _stand_sprite.position = _cur_sprite.position;
        [self removeChild:_cur_sprite];
        _cur_sprite = _stand_sprite;
        [_stand_sprite Replay];
        [self addChild:_cur_sprite];
      }
      _cur_sprite.position = ccp(_actor.position.x,_actor.position.y);
      return;
  }
}

-(void) tickPlayerStateNotification
{
  NSMutableIndexSet* discard_array = [[NSMutableIndexSet alloc]init];
  for( int i = 0 ; i < _observer_list.count ; ++i ) {
    PlayerNotifyObject* notifier = (PlayerNotifyObject*)[_observer_list objectAtIndex:i];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    BOOL ret = [notifier->_target performSelector:notifier->_on_state_change withObject:self];
#pragma clang diagnostic pop
    if( ret ) {
      [discard_array addIndex:i];
    }
  }
  [_observer_list removeObjectsAtIndexes:discard_array];
}

-(void) updatePositionRecovery:(CCTime)delta
{
  _position_recovery_cur_timer += delta;
  // 1. Check whether we need to recover or not
  if( _actor.position.x >= _target_x_position) {
    if(_position_recovery_cur_timer > _position_recovery_frequency ) {
      [_actor stable];
      _position_recovery_cur_timer -= _position_recovery_frequency;
    }
    return;
  }
  // 2.1 If the actor is stucked, do not recover
  if( [_actor isStuck] ) {
    _position_recovery_cur_timer = 0.0f;
    return;
  }
  if( _position_recovery_cur_timer > _position_recovery_frequency ) {
    // Do the recovery here
    _position_recovery_cur_timer -= delta;
    [_actor setImpulse:MakeVector(_position_recovery_x_step,0.0f)];
  }
}

-(void) update:(CCTime)delta
{
  assert(_state != PLAYER_DIE);
  [self updatePositionRecovery:delta];
  [self updatePlayerEffectList:delta];
  [self updateCharacterJump:delta];
  [self updatePlayerPosition:delta];
  [self updatePlayerLifeWatcher:delta];
}

-(void) setToDie
{
  [_scene gameOver];
  [_scene removeChild:self];
  _state = PLAYER_DIE;
  [self tickPlayerStateNotification];
}

-(void) die
{
  for( int i = 0 ; i < _player_life_watcher.count ; ++i ) {
    id<PlayerLifeWatcher> watcher = [_player_life_watcher objectAtIndex:i];
    BOOL bret = [watcher onPlayerDieInvoked];
    if(!bret) {
      return;
    }
  }

  if( _state != PLAYER_DIE ) {
    [_scene.physical_world removePhysicalActor:_actor];
    [self setToDie];
  }
}

-(BOOL) isAlive
{
  return _state != PLAYER_DIE;
}

-(BOOL) isStand
{
  return _state == PLAYER_STAND;
}

-(BOOL) isShrink
{
  return _state == PLAYER_SHRINK;
}

@end
