//
//  BlinkSprite.m
//  Mario
//
//  Created by Dian Peng on 3/20/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "BlinkSprite.h"
#import "CCSprite.h"

@implementation BlinkSprite
{
  CCSprite* _sprite;
  float _cur_time;
  float _cur_freq;
  float _freq;
  float _duration;
  int _flip;
}

-(void) setSpritePosition:(vec2_t)position
{
  _sprite.position = ccp(position.x,position.y);
}



-(id) initWithNamedImage:(NSString *)name withFrequency:(float)freq withDuration:(float)duration
{
  self = [super init];
  if(self == nil) return nil;
  _sprite = [[CCSprite alloc] initWithImageNamed:name];
  _cur_time = _cur_freq = 0.0f;
  _freq = freq;
  _duration = duration;
  [self addChild:_sprite];
  _flip = 1;
  return self;
}

-(id) initWithSprite:(CCSprite *)sprite withFrequency:(float)freq withDuration:(float)duration
{
  self = [super init];
  if( self == nil ) return nil;
  _sprite = sprite;
  _cur_time = _cur_freq = 0.0f;
  _freq = freq;
  _duration = duration;
  [self addChild:_sprite];
  _flip = 1;
  return self;
}

-(BOOL) alive
{
  return _cur_time < _duration;
}

-(void) update:(CCTime)delta
{
  _cur_time += delta;
  _cur_freq += delta;
  if( _cur_time >= _duration )
    return;
  if( _cur_freq > _freq ) {
    if(_flip>0)
      [self removeChild:_sprite];
    else
      [self addChild:_sprite];
    _flip = -_flip;
    _cur_freq -= _freq;
  }
}

@end








