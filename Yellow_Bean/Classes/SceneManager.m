//
//  SceneManager.h
//  prototype
//
//  Created by Dian Peng on 2/21/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "SceneManager.h"
#import "GameMapFile.h"
#import "Misc.h"
#import "PhysicalWorld.h"
#import "GameScene.h"

static SceneManager *_manager=nil;

@implementation SceneManager
-(CCScene*) loadScene:(NSString*)sceneFileName
{
  GameMapFileErrorCollector* collector = [[GameMapFileErrorCollector alloc]init];
  GameMapFileObject* object = [[[GameMapFileParser alloc]init] parse:sceneFileName withError:collector];
  assert(object);
  return [[GameScene alloc]init:object];
}

+(SceneManager *)sharedManager
{
    if (_manager==nil){
        _manager=[[SceneManager alloc]init];
    }
    return _manager;
}


@end
