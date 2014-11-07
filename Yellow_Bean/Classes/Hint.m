//
//  Hint.m
//  Yellow_Bean
//
//  Created by Dian Peng on 4/21/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Hint.h"
#import "CCLabelTTF.h"
#import "GameScene.h"
#import "GameMapFile.h"
#import "Misc.h"

@implementation Hint
{
  GameScene* _scene;
  CCLabelTTF* _label;
  float _fade_in_time;
  float _fade_out_time;
  float _stay_time;
  float _cur_time;
  float _cur_step;
  int _state;
}

enum {
  FADE_IN,
  FADE_OUT,
  STAY
};


+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[Hint alloc] init:par withScene:scene];
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(GameMapFileObject*) findGameMapFileObject:(GameMapFileObject*)par withKey:(NSString*)key
{
  NSMutableArray* collection = [par asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* object = [collection objectAtIndex:i];
    if([object.name isEqual:key] == YES ) {
      return object;
    }
  }
  return nil;
}

-(NSString*) getMessage:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==1);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  return [atomic asString];
}


-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if(self == nil) return nil;
  _scene = scene;
  
  GameMapFileObject* gm_object = [self findGameMapFileObject:par withKey:@"Message"];
  assert(gm_object);
  NSString* message = [self getMessage:gm_object];
  gm_object = [self findGameMapFileObject:par withKey:@"Effect"];
  assert(gm_object);
  NSMutableArray* command =[gm_object asCommand];
  assert(command.count == 8);
  GameMapFileObjectAtomic* atomic;
  atomic = [command objectAtIndex:0];
  CGPoint pos;
  pos.x = [atomic asNumber];
  atomic = [command objectAtIndex:1];
  pos.y = [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  NSString* string_value = [atomic asString];
  CCColor* color = StringToColor(string_value);
  
  atomic = [command objectAtIndex:3];
  float size = [atomic asNumber];
  
  atomic = [command objectAtIndex:4];
  NSString* font_family = [atomic asString];
  
  atomic = [command objectAtIndex:5];
  _fade_in_time = [atomic asNumber];
  
  atomic = [command objectAtIndex:6];
  _stay_time = [atomic asNumber];
  
  atomic = [command objectAtIndex:7];
  _fade_out_time = [atomic asNumber];
  
  _label = [[CCLabelTTF alloc] initWithString:message fontName:font_family fontSize:size];
  _label.color = color;
  _label.opacity = 0.0f;
  _label.position = pos;
  [self addChild:_label];
  _state = FADE_IN;
  _cur_time = 0.0f;
  _cur_step = 1.0f / _fade_in_time;
  
  return self;
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case FADE_IN:
      _cur_time += delta;
      _label.opacity += delta * _cur_step;
      if(_cur_time > _fade_in_time) {
        _cur_time = 0.0f;
        _state = STAY;
        return;
      }
      return;
    case STAY:
      _cur_time += delta;
      if( _cur_time > _stay_time ) {
        _state = FADE_OUT;
        _cur_time = 0.0f;
        _cur_step = 1.0f/_fade_out_time;
        return;
      }
      return;
    case FADE_OUT:
      _cur_time += delta;
      _label.opacity -= delta * _cur_step;
      if( _cur_time > _fade_out_time ) {
        [_scene removeChild:self];
        return;
      }
      return;
  }
}

@end
