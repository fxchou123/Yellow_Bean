//
//  ScoreBomber.m
//  Mario
//
//  Created by Dian Peng on 3/22/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "GoldBomber.h"
#import "Player.h"
#import "GameScene.h"
#import "GameMapFile.h"
#import "CachedSprite.h"
#import "CCParticleSystem.h"
#import "PhysicalWorld.h"
#import "Gold.h"
#import "NodeRotator.h"
#import "SoundManager.h"

@implementation GoldBomber
{
  float _bomb_width;
  float _bomb_height;
  CachedSprite* _sprite;
  CCParticleSystem* _effect;
  int _state;
}

enum {
  IDLE,
  EFFECT,
  DEAD
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[GoldBomber alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init:par withScene:scene];
  if( self == nil ) return nil;
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:4];
  _bomb_width = [atomic asNumber];
  
  atomic = [command objectAtIndex:5];
  _bomb_height= [atomic asNumber];
  
  atomic = [command objectAtIndex:6];
  NSString* sprite_path = [atomic asString];
  
  atomic = [command objectAtIndex:7];
  NSString* effect_path = [atomic asString];
  
  _sprite = [[CachedSprite alloc] initWithImageNamed:sprite_path];
  _sprite.scaleX = self.movable_object.width/_sprite.textureRect.size.width;
  _sprite.scaleY = self.movable_object.height/_sprite.textureRect.size.height;
  _sprite.position = ccp(self.movable_object.position.x,
                         self.movable_object.position.y);
  
  _effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  _effect.posVar = ccp(_bomb_width/2.0f,_bomb_height/2.0f);
  
  [self addChild:_sprite];
  _state = IDLE;
  
  return self;
}


-(BOOL) onOutOfBound
{
  if(_state != DEAD) {
    _state = DEAD;
    [self.game_scene removeChild:self];
  }
  return YES;
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if( ([object isMemberOfClass:[Player class]] == YES)
     &&([self.game_scene.player isPlayerCollided:shape] == YES) ) {
     // Scan around to figure out what we need here
    NSMutableArray* array = [self.game_scene.physical_world
                             querySimpleObjectCollision:MakeRect(
                             self.movable_object.position.x-_bomb_width/2.0f,
                             self.movable_object.position.y-_bomb_height/2.0f,
                             _bomb_width,_bomb_height)
                             withClass:[Gold class]];
    for( int i = 0 ; i < array.count ; ++i ) {
      id<GoldProtocol> score = (id<GoldProtocol>)[array objectAtIndex:i];
      [score forceToDie];
    }
    // Change the state here
    _state = EFFECT;
    _effect.position = ccp(self.movable_object.position.x,
                           self.movable_object.position.y);
    [self removeChild:_sprite];
    [self addChild:_effect];
    [self.game_scene.sound_manager playEffect:@"Bomb"];
    [self.game_scene shakeScene:0.5f];
    return YES;
  }
  return NO;
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case IDLE:
      _sprite.position = ccp(self.movable_object.position.x,
                             self.movable_object.position.y);
      return;
    case EFFECT:
      if(_effect.active == NO && _effect.particleCount ==0) {
        _state = DEAD;
        [self.game_scene removeChild:self];
        return;
      }
    default:
      return;
  }
}

@end
