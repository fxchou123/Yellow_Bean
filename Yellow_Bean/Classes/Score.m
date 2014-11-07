//
//  Gold.m
//  Mario
//
//  Created by Dian Peng on 3/31/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Score.h"
#import "GameScene.h"
#import "GameStatistics.h"

@implementation Score
+(id)createObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return [[Score alloc]init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return [self init:par withScene:scene withSoundName:@"Score"];
}

-(void) onChange:(int)value
{
  [self.game_scene.game_statistics addScore:value];
}

@end
