//
//  Environment.m
//  Yellow_Bean
//
//  Created by Dian Peng on 4/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Environment.h"
#import "Weather.h"
#import "Background.h"
#import "GameScene.h"
#import "GameMapFile.h"
#import "Misc.h"

//
// [Z:10]
// Environment = {
//   Weather = {};
//   Background();
// };
//

@implementation Environment
{
  Weather* _weather;
  Background* _background;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  return [[Environment alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  NSMutableArray* collection = [par asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* object = [collection objectAtIndex:i];
    CCNode* node = CreateObjectByReflection(object.name,@"createObject:withScene:",
                                            object, scene);
    [scene addChild:node z:node.zOrder];
  }
  return self;
}

-(void) update:(CCTime)delta
{
  [self.parent removeChild:self];
}

-(void) stop
{
  if(_background)
    [_background stop];
}

@end
