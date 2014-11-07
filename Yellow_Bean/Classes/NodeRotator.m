//
//  NodeRotator.m
//  Mario
//
//  Created by Dian Peng on 3/11/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "NodeRotator.h"

@implementation NodeRotator
{
  @public
  vec2_t _anchor_point;
  float _radius;
  float _frequency;
  float _step;
  float _cur_rotation;
  CCNode* _target;
}

@synthesize anchor_point = _anchor_point;
@synthesize radius = _radius;

-(void) setFrequency:(float)frequency
{
  _frequency = frequency;
  _step = 2.0f*M_PI/frequency;
}

-(float) frequency
{
  return _frequency;
}

-(id) init:(vec2_t) position withRadius:(float)radius withFrequency:(float)time
{
  self = [super init];
  if( self == nil ) return nil;
  _anchor_point = position;
  _radius = radius;
  _frequency = time;
  _step = 2.0f*M_PI / time;
  _cur_rotation = 0;
  return self;
}


-(void) update:(CCTime)delta
{
  float radius_offset = _step*delta;
  _cur_rotation+=radius_offset;
  if( _target == nil ) return;
  float y = cosf(_cur_rotation)*_radius;
  float x = sinf(_cur_rotation)*_radius;
  _target.position = ccp(x+_anchor_point.x,y+_anchor_point.y);
}

-(void) setTarget:(CCNode *)node
{
  node.anchorPoint = ccp(_anchor_point.x,_anchor_point.y);
  [self addChild:node];
  _target = node;
}

-(void) removeTarget:(CCNode *)node
{
  if(_target == node) {
    [self removeChild:node];
    _target = node;
  }
}



@end
