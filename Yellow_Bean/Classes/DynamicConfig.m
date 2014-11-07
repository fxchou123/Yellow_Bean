//
//  DynamicConfig.m
//  Mario
//
//  Created by Dian Peng on 4/5/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "DynamicConfig.h"
#import "PhysicalWorld.h"
#import "GameScene.h"
#import "Player.h"
#import "GameMapFile.h"

// ------------------------------------------------------------------
// Dynamic config is a block that cannot be used to show on the
// screen but it can be used to change the scene configuration
// on the runtime. Eg: change the scrolling speed of the background.
// ------------------------------------------------------------------
//
// [StartX:500]
// [StartY:300]
// DynamicConfig = {
//   Player = {
//     SetJumpTime();
//   };
//   PhysicalWorld = {
//     SetSpeed();
//     SetGravity();
//   };
// };
//
// ------------------------------------------------------------------

@implementation DynamicConfig
{
  GameScene* _game_scene;
  NSMutableArray* _player_instruction;
  NSMutableArray* _physical_world_instruction;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[DynamicConfig alloc] init:par withScene:scene];
}

-(GameMapFileObject*) findGameMapObject:(GameMapFileObject*)par withKey:(NSString*)key
{
  NSMutableArray* collection = [par asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* gm_object = [collection objectAtIndex:i];
    if( [gm_object.name isEqual:key] ) {
      return gm_object;
    }
  }
  return nil;
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  GameMapFileObject* gm_object = [self findGameMapObject:par withKey:@"Player"];
  if(gm_object == nil) {
    _player_instruction = [[NSMutableArray alloc]init];
  } else {
    _player_instruction = [gm_object asCollection];
  }
  
  gm_object = [self findGameMapObject:par withKey:@"PhysicalWorld"];
  assert(gm_object);
  if(gm_object == nil) {
    _physical_world_instruction = [NSMutableArray alloc];
  } else {
    _physical_world_instruction = [[gm_object asCollection]init];
  }
  
  _game_scene = scene;
  return self;
}


-(int) parseAsInt:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  return (int)[[command objectAtIndex:0]asNumber];
}

-(int) parseAsFloat:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  return (float)[[command objectAtIndex:0]asNumber];
}

-(vec2_t) parseAsVec:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  float x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  float y = [atomic asNumber];
  return MakeVector(x, y);
}


-(void) firePlayerInstruction
{
  for( int i = 0 ; i < _player_instruction.count ; ++i ) {
    GameMapFileObject* gm_object = [_player_instruction objectAtIndex:i];
    if( [gm_object.name isEqual:@"SetJumpTime"] ) {
      _game_scene.player.jump_time = [self parseAsInt:gm_object];
    } else if( [gm_object.name isEqual:@"SetGravity"] ) {
      _game_scene.player.jump_height=[self parseAsFloat:gm_object];
    } else if( [gm_object.name isEqual:@"SetJumpCoolDown"]) {
      _game_scene.player.jump_cool_down=[self parseAsFloat:gm_object];
    }
  }
}


-(void) firePhysicalWorldInstruction
{
  for( int i = 0 ; i < _physical_world_instruction.count ; ++i ) {
    GameMapFileObject* gm_object = [_physical_world_instruction objectAtIndex:i];
    if( [gm_object.name isEqual:@"SetSpeed"] ) {
      _game_scene.physical_world.current_speed = [self parseAsVec:gm_object];
    } else if( [gm_object.name isEqual:@"SetGravity"] ) {
      _game_scene.physical_world.gravity = [self parseAsFloat:gm_object];
    }
  }
}

-(void) update:(CCTime)delta {
  [self firePlayerInstruction];
  [self firePhysicalWorldInstruction];
  [_game_scene removeChild:self];
}

@end


















