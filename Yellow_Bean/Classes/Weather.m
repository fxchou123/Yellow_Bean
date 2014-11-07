//
//  Weather.m
//  Yellow_Bean
//
//  Created by Yifan Zhou on 4/10/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "Weather.h"
#import "CCParticleSystem.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "CCDirector.h"
#import <math.h>
//
// ------------------------------
// Weather = {
//   Maple("maple.plist",30);
// };
// -------------------------------
//


@implementation Weather
{
  CCParticleSystem* _current_weather;
  int _current_weather_status;
  float _cur_time;
  float _change_time;
}

enum {
  WIND_LEFT,
  WIND_RIGHT,
  WIND_NONE
};

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[Weather alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  NSMutableArray* collection = [par asCollection];
  assert(collection.count ==1);
  GameMapFileObject* object = [collection objectAtIndex:0];
  NSMutableArray* command = [object asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  NSString* weather_name = [atomic asString];
  
  atomic = [command objectAtIndex:1];
  _change_time = [atomic asNumber];
  
  _cur_time = 0.0f;
  _current_weather_status = WIND_NONE;
  
  _current_weather = [[CCParticleSystem alloc] initWithFile:weather_name];
  
  CGSize size = [[CCDirector sharedDirector] viewSize];
  _current_weather.position = CGPointMake(size.width/2.0f,size.height);
  [self addChild:_current_weather];
  
  self.zOrder = 100;
  return self;
}


-(void) update:(CCTime)delta
{
  _cur_time += delta;
  if(_cur_time > _change_time) {
    _cur_time -= delta;
    switch(_current_weather_status) {
      case WIND_NONE:
        _current_weather_status = WIND_LEFT;
        _current_weather.gravity = CGPointMake(fabs(_current_weather.gravity.y),
                                               _current_weather.gravity.y);
        break;
      case WIND_LEFT:
        _current_weather_status = WIND_RIGHT;
        _current_weather.gravity = CGPointMake(-fabs(_current_weather.gravity.y),
                                               _current_weather.gravity.y);
        break;
      case WIND_RIGHT:
        _current_weather_status = WIND_NONE;
        _current_weather.gravity = CGPointMake(0,_current_weather.gravity.y);
        break;
    }
  }
}


@end
