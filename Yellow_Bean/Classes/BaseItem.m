//
//  BaseItem.m
//  Mario
//
//  Created by Dian Peng on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "BaseItem.h"
#import "GameScene.h"
#import "PhysicalWorld.h"
#import "GameMapFile.h"

@implementation BaseItem
{
  GameScene* _scene;
  SimpleMovableCollidableObject* _movable_object;
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
    withStartX:(float)startx withStartY:(float)starty
{
  self = [super init];
  if( self == nil ) return nil;
  _scene = scene;
  SimpleMovableCollidableObjectSettings settings;
  NSMutableArray* command = [par asCommand];
  // Speed
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  settings.speed.x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  settings.speed.y = [atomic asNumber];
  
  // Width/Height
  atomic = [command objectAtIndex:2];
  settings.width = [atomic asNumber];
  
  atomic = [command objectAtIndex:3];
  settings.height= [atomic asNumber];
  
  settings.absolute_position.x = startx + settings.width/2.0f;
  settings.absolute_position.y = starty + settings.height/2.0f;
  
  _movable_object = [scene.physical_world addMovableCollidableObject:&settings
                                                         onCollision:@selector(onCollision:withShape:)
                                                        onOutOfBound:@selector(onOutOfBound)
                                                            targetAt:self];
  
  return self;

}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  float startx = [self getPropertyNumber:par withKey:@"StartX"];
  float starty = [self getPropertyNumber:par withKey:@"StartY"];
  return [self init:par withScene:scene withStartX:startx withStartY:starty];
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  return NO;
}

-(BOOL) onOutOfBound
{
  return YES;
}

@synthesize game_scene = _scene;
@synthesize movable_object = _movable_object;
@end
