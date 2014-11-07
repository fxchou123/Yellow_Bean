//
//  JumpBrick.m
//  Mario
//
//  Created by Dian Peng on 3/11/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "JumpBrick.h"
#import "TextureAnimation.h"
#import "CCParticleSystem.h"
#import "Player.h"
#import "GameScene.h"
#import "PhysicalWorld.h"
#import "SoundManager.h"

// ---------------------------
// Dash effect
// ---------------------------

@interface DashEffect: NSObject<PlayerEffect>

-(void) takeEffect:(Player *)player withDelta:(float)dt;
-(BOOL) isAlive;
-(void) destroy;

-(id) init:(float) dash_speed withDuration:(float)timer;
+(id) createObject:(GameMapFileObject*) object;
@end



@implementation DashEffect
{
  float _dash_speed;
  float _dash_duration;
  int _state;
}

enum {
  DASH_START,
  DASH_DONE
};

+(id) createObject:(GameMapFileObject*) object
{
  float dash_speed ,dash_duration;
  NSMutableArray* collection = [object asCommand];
  assert(collection.count ==2);
  GameMapFileObjectAtomic* atomic = [collection objectAtIndex:0];
  dash_speed = [atomic asNumber];
  atomic = [collection objectAtIndex:1];
  dash_duration = [atomic asNumber];
  return [[DashEffect alloc] init:dash_speed withDuration:dash_duration ];
}


-(id) init:(float) dash_speed withDuration:(float)duration
{
  self = [super init];
  if(self == nil) return nil;
  _dash_speed = dash_speed;
  _dash_duration=duration;
  _state = DASH_START;
  return self;
}

-(void) takeEffect:(Player *)player withDelta:(float)dt
{
  _state = DASH_DONE;
  [player.physical_actor dashRight:_dash_speed withDuration:_dash_duration];
}

-(BOOL) isAlive
{
  return _state != DASH_DONE;
}

-(void) destroy
{
  
}

@end

@interface JumpBrickEffect : CCParticleSystem
@end


@implementation JumpBrickEffect
{
  Player* _player;
}
-(id) initWithFile:(NSString *)plistFile withPlayer:(Player*)player withDuration:(float)duration
{
  self = [super initWithFile:plistFile];
  if(self == nil) return nil;
  self.particlePositionType = CCParticleSystemPositionTypeFree;
  _player = player;
  self.duration = duration;
  return self;
}

-(void) update:(CCTime)delta;
{
  self.position = ccp(_player.scene_position.x,
                      _player.scene_position.y);
  [super update:delta];
}

@end

@implementation JumpBrick
{
  @public
  TextureAnimation* _sprite;
  // This particle will add to the player and then
  // remove automatically .
  NSString* _effect_particle_name;
  // I don't know whether it gonna work or not :(
  vec2_t _jump_speed;
  float _duration;
  int _state;
  BannerObject* _banner;
}

enum {
  IDLE,
  HIT,
  DEAD
};


+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[JumpBrick alloc] init:par withScene:scene];
}


-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  NSString* texture_path;
  self = [super init:par withScene:scene withPath:&texture_path];
  if( self == nil ) return nil;
  // Initialize all the related parameter for the object
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:6];
  _jump_speed.x = [atomic asNumber];
  atomic = [command objectAtIndex:7];
  _jump_speed.y = [atomic asNumber];
  atomic = [command objectAtIndex:8];
  _duration = [atomic asNumber];
  
  atomic = [command objectAtIndex:10];
  _effect_particle_name = [atomic asString];
  
  _sprite = [[TextureAnimation alloc]
             initAnimationWithNamedImage:texture_path
             withFrames:8
             withFrequency:32 withFrameSize:MakeVector(40, 50)];
  
  [_sprite Stop];
  
  _sprite.position = ccp(self.physical_entity.position.x,
                         self.physical_entity.position.y);

  [self addChild:_sprite];
  
  _state= IDLE;
  // -------------------------------------------------
  // Adding another shape to detect the top collision
  // -------------------------------------------------
  _banner = [scene.physical_world addBannerObject:MakeRect(self.physical_entity.position.x,
                                                           self.physical_entity.position.y,
                                                           self.physical_entity.width,
                                                           self.physical_entity.height)
                                      onCollision:@selector(onBannerTopCallback:withShape:)
                                 onOtherCollision:@selector(onBannerOtherCallback:withShape:)
                                     onOutOfBound:@selector(onBannerOutOfBound)
                                      targetAt:self];
  return self;
}

-(BOOL) onBannerTopCallback:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if( [object isKindOfClass:[Player class]] == NO || [self.game_scene.player isPlayerCollided:shape] == NO ) return NO;
  if(_state == HIT) return YES;
  _state = HIT;
  // Fire the effect for our player
  [self.game_scene.player.physical_actor jump:_jump_speed.y];
  [self.game_scene.player.physical_actor dash:_jump_speed.x withDuration:_duration];
  JumpBrickEffect* effect =
  [[JumpBrickEffect alloc] initWithFile:_effect_particle_name
                          withPlayer:self.game_scene.player withDuration:_duration];
  [_sprite Replay];
  effect.autoRemoveOnFinish = true;
  [self.game_scene.sound_manager playEffect:@"JumpBrick"];
  [self.game_scene.player addChild:effect];
  return NO;
}


-(BOOL) onBannerOtherCallback:(NSObject*)object withShape:(PhysicalShape*)shape
{
  return NO;
}

-(BOOL) onCollision:(NSObject *)object withShape:(PhysicalShape *)shape
{
  return NO;
}

-(void) onOutOfBound
{
  [self.game_scene removeChild:self];
  [self.game_scene.physical_world removeBanner:_banner];
}

-(BOOL) onBannerOutOfBound
{
  return YES;
}

-(void) update:(CCTime)delta
{
  _sprite.position = ccp(self.physical_entity.position.x,
                         self.physical_entity.position.y);
  
  _banner.position =  MakeVector(self.physical_entity.position.x,self.physical_entity.position.y);
}




@end









