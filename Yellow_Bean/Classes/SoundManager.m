//
//  SoundManager.m
//  Mario
//
//  Created by Dian Peng on 3/21/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "SoundManager.h"
#import "OALSimpleAudio.h"
#import "GameMapFile.h"

@implementation SoundManager
{
  NSString* _background_music;
  NSString* _game_over_music;
  NSMutableDictionary* _effect_dict;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[SoundManager alloc] init:par];
}

-(NSString*) loadStringValue:(GameMapFileObject*)object
{
  NSMutableArray* command = [object asCommand];
  return [[command objectAtIndex:0] asString];
}

-(id) init:(GameMapFileObject*)par
{
  self = [super init];
  if(self == nil) return nil;
  _effect_dict = [[NSMutableDictionary alloc] init];
  // Loading all the possible Audio Key/Value pair here
  NSMutableArray* collection = [par asCollection];
  for( int i = 0; i < collection.count ; ++i ) {
    GameMapFileObject* object = [collection objectAtIndex:i];
    if( [object.name isEqual:@"BackgroundMusic"] ) {
      _background_music = [self loadStringValue:object];
    } else if( [object.name isEqual:@"GameOverMusic"]) {
      _game_over_music = [self loadStringValue:object];
    } else {
      NSString* path = [self loadStringValue:object];
      ALBuffer* buffer = [[OALSimpleAudio sharedInstance]preloadEffect:path];
      [_effect_dict setObject:buffer forKey:object.name];
    }
  }
  return self;
}

-(void) playBackgroundMusic
{
  [[OALSimpleAudio sharedInstance] playBg:_background_music loop:YES];
}

-(void) stopBackgroundMusic
{
  [[OALSimpleAudio sharedInstance] stopBg];
}

-(void) playGameOverMusic
{
  [[OALSimpleAudio sharedInstance] playBg:_game_over_music loop:YES];
}

-(void) stopGameOverMusic
{
  [[OALSimpleAudio sharedInstance] stopBg];
}

-(void) playEffect:(NSString *)key
{
  ALBuffer* buffer = [_effect_dict objectForKey:key];
  if(buffer == nil)
    return;
  [[OALSimpleAudio sharedInstance] playBuffer:buffer volume:1.0f pitch:1.0f pan:0.0f loop:NO];
}

-(void) stopAll
{
  [[OALSimpleAudio sharedInstance] stopEverything];
}

@end
