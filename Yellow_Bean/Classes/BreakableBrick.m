//
//  BreakableBrick.m
//  prototype
//
//  Created by Yifan Zhou on 3/2/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "BreakableBrick.h"
#import "PhysicalWorld.h"
#import "RepeatableSprite.h"
#import "Player.h"
#import "CCTexture_Private.h"
#import "GameScene.h"
#import "CCParticleSystem.h"
#import "SoundManager.h"

@implementation BreakableBrick
{
  float _frozen_time;
  float _cur_time;
  int _state;
  RepeatableSprite* _sprite;
  CCParticleSystem* _effect;
}

enum {
  IDLE,
  FROZEN,
  DISAPPEAR,
  DEAD
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  id obj = [[BreakableBrick alloc]init:par withScene:scene];
  return obj;
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  NSString* path;
  NSMutableArray* command = [par asCommand];
  assert(command.count ==8);
  self = [super init:par withScene:scene withPath:&path];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  _sprite = [[RepeatableSprite alloc ] initWithImageNamed:path
                                       withWidth:self.physical_entity.width
                                       withHeight:self.physical_entity.height];
  
  if( _sprite == nil )
    return nil;
  _sprite.position = ccp(self.physical_entity.position.x,self.physical_entity.position.y);
  _sprite.position = ccp(self.physical_entity.position.x,self.physical_entity.position.y);
  [self addChild:_sprite];
  _state = IDLE;
  _cur_time = 0.0f;
  // parsing the forzen time
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:6];
  _frozen_time = [atomic asNumber];
  
  atomic = [command objectAtIndex:7];
  NSString* effect_path = [atomic asString];
  _effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  _effect.posVar = ccp(self.physical_entity.width/2.0f,
                       self.physical_entity.height/2.0f);
  return self;
}

// DO NOT DELETE PHYSICAL IN onXXX callback
-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if( [object isKindOfClass:[Player class]] ) {
    if( _state == IDLE ) {
      _state = FROZEN;
    }
  }
  return NO;
}


-(void) onOutOfBound
{
  if( _state != DEAD )
    [self.game_scene removeChild:self];
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case FROZEN:
      _cur_time += delta;
      if( _cur_time > _frozen_time ) {
        _effect.position = ccp(self.physical_entity.position.x,
                               self.physical_entity.position.y);
        [self.game_scene shakeScene:0.3f];
        [self.physical_entity removePhysicalShape:self.base_shape];
        [self removeChild:_sprite];
        [self addChild:_effect];
        [self.game_scene.sound_manager playEffect:@"BreakableBrickExplosion"];
        _state = DISAPPEAR;
        return;
      }
      break;
    case DISAPPEAR:
      _effect.position = ccp(self.physical_entity.position.x,
                             self.physical_entity.position.y);
      if(_effect.active == NO && _effect.particleCount ==0) {
        [self.game_scene removeChild:self];
        [self.game_scene.physical_world removePhysicalEntity:self.physical_entity];
        _state = DEAD;
      }
    default:
      break;
  }
  _sprite.position = ccp(self.physical_entity.position.x,
                         self.physical_entity.position.y);
}


@end
