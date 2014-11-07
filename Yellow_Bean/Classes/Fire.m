//
//  Fire.m
//  Yellow_Bean
//
//  Created by Dian Peng on 4/8/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Fire.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "CCParticleSystem.h"
#import "PhysicalWorld.h"
#import "Player.h"

@implementation Fire
{
  CCParticleSystem* _fire;
  SimpleMovableCollidableObject* _collision_object;
  GameScene* _game_scene;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[Fire alloc]init:par withScene:scene];
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  _game_scene = scene;
  float StartX = [self getPropertyNumber:par withKey:@"StartX"];
  float StartY = [self getPropertyNumber:par withKey:@"StartY"];
  SimpleMovableCollidableObjectSettings settings;
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [ command objectAtIndex:0 ];
  settings.speed.x = [atomic asNumber];
  atomic = [ command objectAtIndex:1 ];
  settings.speed.y = [atomic asNumber];
  atomic = [ command objectAtIndex:2 ];
  settings.width = [atomic asNumber];
  atomic = [ command objectAtIndex:3 ];
  settings.height = [atomic asNumber];
  atomic = [ command objectAtIndex:4 ];
  NSString* path = [atomic asString];
  settings.absolute_position.x = StartX + settings.width/2.0f;
  settings.absolute_position.y = StartY + settings.height/2.0f;
  _collision_object = [scene.physical_world
                       addMovableCollidableObject:&settings
                       onCollision:@selector(onCollision:withShape:)
                       onOutOfBound:@selector(onOutOfBound)
                       targetAt:self];
  
  _fire = [[CCParticleSystem alloc] initWithFile:path];
  _fire.posVar = ccp(settings.width/2.0f,settings.height/2.0f);
  _fire.speed = settings.height/2.0f;
  _fire.position = ccp(_collision_object.position.x,
                       _collision_object.position.y);
  [self addChild:_fire];
  return self;
}

-(void) update:(CCTime)delta
{
  _fire.position = ccp(_collision_object.position.x,
                       _collision_object.position.y);
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape *)shape
{
  if( [object isKindOfClass:[Player class]] &&
      [_game_scene.player isPlayerCollided:shape] )
  {
    Player* player = (Player*)object;
    [player die];
  }
  return NO;
}

-(BOOL) onOutOfBound
{
  [_game_scene removeChild:self];
  return YES;
}

@end


















