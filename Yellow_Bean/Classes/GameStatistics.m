//
//  GameStatistics.m
//  Mario
//
//  Created by Dian Peng on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "GameStatistics.h"
#import "CCLabelTTF.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "PhysicalWorld.h"
#import "Global.h"

@implementation GameStatistics
{
  float _current_distance;
  int _current_score;
  int _current_gold;
  int _player_jump_times;
  int _player_shrink_times;
  float _player_distance_factor;
  // Update the specific rendering status
  CCLabelTTF* _distance_label;
  CCLabelTTF* _gold_label;
  GameScene* _scene;
}

@synthesize current_distance = _current_distance;
@synthesize current_gold = _current_gold;
@synthesize current_score = _current_score;
@synthesize player_distance_factor = _player_distance_factor;
@synthesize player_jump_times = _player_jump_times;
@synthesize player_shrink_times = _player_shrink_times;

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[GameStatistics alloc] init:par withScene:scene];
}


-(void) initRenderInfo:(GameMapFileObject*)par
{
  NSString* font_name;
  float font_size;
  NSMutableArray* command = [par asCommand];
  assert(command.count ==7);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  font_name = [atomic asString];
  
  atomic = [command objectAtIndex:1];
  font_size = [atomic asNumber];
  
  _distance_label = [CCLabelTTF labelWithString:@"" fontName:font_name fontSize:font_size];
  _gold_label = [CCLabelTTF labelWithString:@"" fontName:font_name fontSize:font_size];
  
  atomic = [command objectAtIndex:2];
  NSString* color = [atomic asString];
  _distance_label.color = StringToColor(color);
  _gold_label.color = _distance_label.color;
  
  // Distance Label Position
  atomic = [command objectAtIndex:3];
  float x = [atomic asNumber];
  atomic = [command objectAtIndex:4];
  float y = [atomic asNumber];
  _distance_label.position = ccp(x,y);
  _distance_label.anchorPoint = ccp(0.0f,1.0f);
  
  // Gold Label Position
  atomic = [command objectAtIndex:5];
  x = [atomic asNumber];
  atomic = [command objectAtIndex:6];
  y = [atomic asNumber];
  _gold_label.position = ccp(x,y);
  _gold_label.anchorPoint = ccp(0.0f,1.0f);
  
  _current_distance = 0;
  _current_score = 0;
  _current_gold = 0;
  
  [self setDistanceLabel];
  [self setGoldLabel];
  
  [self addChild:_distance_label];
  [self addChild:_gold_label];
}


-(GameMapFileObject*) findGameMapFileObject:(GameMapFileObject*)par withKey:(NSString*)key
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

-(float) queryKeyValueAsFloat:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==1);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  return [atomic asNumber];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  _scene = scene;
  
  GameMapFileObject* gm_object = [self findGameMapFileObject:par withKey:@"RenderInfo"];
  assert(gm_object);
  [self initRenderInfo:gm_object];
  
  gm_object = [self findGameMapFileObject:par withKey:@"ScoreDistanceFactor"];
  assert(gm_object);
  _player_distance_factor = [self queryKeyValueAsFloat:gm_object];
  
  return self;
}

-(void) setDistanceLabel
{
  [_distance_label setString:
   [NSString stringWithFormat:@"Current Distance:%.0f",
    _current_distance/10.0f]];
}

-(void) setGoldLabel
{
  [_gold_label setString:
   [NSString stringWithFormat:@"Current Gold:%d",
    _current_gold]];
}

-(void) update:(CCTime)delta
{
  _current_distance = _scene.physical_world.absolute_position.x;
  [self setDistanceLabel];
}

-(void) addScore:(int)score
{
  _current_score += score;
}

-(void) removeScore
{
  _current_score = 0;
}

-(void) addGold:(int)gold
{
  _current_gold += gold;
  [self setGoldLabel];
}

-(void) removeGold
{
  _current_gold = 0;
  [self setGoldLabel];
}

-(void) clear
{
  _current_distance = 0;
  _current_gold = 0;
  _current_score = 0;
  _player_jump_times  = 0;
  _player_shrink_times = 0;
}


-(void) gameOver
{
  // Update the current score
  _current_score = _current_score + // current score
  _current_distance*_player_distance_factor + // distance component
  _current_gold*10 + // gold component
  _player_jump_times*100; // jump times component
  // Update Global status
  [Global sharedInstance].totalDistance += _current_distance;
  [Global sharedInstance].totalRun += 1;
  if([Global sharedInstance].highestScore >= _current_score ) {
    [Global sharedInstance].highestScore = _current_score;
  }
  [Global sharedInstance].coinNumber += _current_gold;
}

@end
