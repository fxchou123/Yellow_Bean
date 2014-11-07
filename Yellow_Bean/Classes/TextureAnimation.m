//
//  TextureAnimation.m
//  Mario
//
//  Created by Dian Peng on 3/22/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "TextureAnimation.h"


@implementation TextureAnimation
{
  int _texture_frame_width_cnt;
  int _texture_frame_height_cnt;
  float _frame_width;
  float _frame_height;
  int _frames;
  float _freq;
  int _cur_frames;
  float _cur_time;
  float _rate;
  BOOL _loop;
  BOOL _stop;
}

-(id) initAnimationWithNamedImage:(NSString*)name
                       withFrames:(int) frames
                    withFrequency:(float) freq
                    withFrameSize:(vec2_t)size
                             loop:(BOOL)loop
{
  self = [super initWithImageNamed:name];
  if(self ==nil) return nil;
  _frames = frames;
  _freq = freq;
  _rate = 1.0f/freq;
  _loop = loop;
  _frame_width = size.x;
  _frame_height= size.y;
  _cur_frames = 1;
  _cur_time = 0;
  _texture_frame_width_cnt = self.textureRect.size.width/_frame_width;
  _texture_frame_height_cnt= self.textureRect.size.height/_frame_height;
  _stop = false;
  // Setting the very first frame for texture here
  [self setTextureRect:CGRectMake(0.0f,0.0f,_frame_width,_frame_height)];
  return self;
}


-(id) initAnimationWithNamedImage:(NSString *)name
                       withFrames:(int)frames
                    withFrequency:(float)freq
                    withFrameSize:(vec2_t)size
{
  return [[TextureAnimation alloc]
          initAnimationWithNamedImage:name
          withFrames:frames
          withFrequency:freq
          withFrameSize:size
          loop:NO];
}

-(void) Replay
{
  _stop = NO;
  _cur_frames = 0;
  [self setTextureRect:CGRectMake(0.0f,0.0f,_frame_width,_frame_height)];
}

-(void) Play
{
  _stop = NO;
}

-(void) Pause
{
  _stop = YES;
}

-(void) Stop
{
  _stop = YES;
  _cur_frames = 0;
}

-(BOOL) isStopped
{
  return _stop;
}

-(void) update:(CCTime)delta
{
  if(_stop) return ;
  _cur_time += delta;
  if(_cur_time > _rate) {
    _cur_frames++;
    if(_cur_frames > _frames) {
      if(_loop) {
        _cur_frames = 0;
        [self setTextureRect:CGRectMake(0.0f,0.0f,_frame_width,_frame_height)];
      } else {
        _stop = YES;
      }
      return;
    }
    // Moving the frame here
    int col_cnt = (_cur_frames-1) / _texture_frame_width_cnt;
    int row_cnt = (_cur_frames-1) - col_cnt*_texture_frame_width_cnt;
    int x = row_cnt*_frame_width;
    int y = col_cnt*_frame_height;
    [self setTextureRect:CGRectMake(x,y,_frame_width,_frame_height)];
    _cur_time -= _rate;
  }
}

@synthesize loop = _loop;
@synthesize current_frame = _frames;
-(float) frequency
{
  return 1.0f/_rate;
}

-(void) setFrequency:(float)frequency
{
  _rate = 1.0f/frequency;
}

@end
