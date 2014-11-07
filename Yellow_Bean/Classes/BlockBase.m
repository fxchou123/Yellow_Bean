//
//  BlockBase.m
//  Mario
//
//  Created by Yifan Zhou on 4/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "BlockBase.h"
#import "CCSprite.h"
#import "PhysicalWorld.h"
#import "GameScene.h"

@implementation BlockBase
{
  GameScene* _scene;
  PhysicalEntity* _entity;
  PhysicalShape* _base_shape;
}

@synthesize game_scene = _scene;
@synthesize physical_entity = _entity;
@synthesize base_shape = _base_shape;

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  NSString* path;
  id obj = [[BlockBase alloc]init:par withScene:scene withPath:&path];
  return obj;
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}


-(void) parseCommandParameter:(GameMapFileObject*)par withSpeed:(vec2_t*)speed
                    withWidth:(float*)width withHeight:(float*)height
                 withElasticy:(float*)elasticy withTexturePath:(NSString**)path
{
  NSMutableArray* command = [par asCommand];
  assert(command.count >=6);
  // (1) parse speed here
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  speed->x = [atomic asNumber];
  atomic = [command objectAtIndex:1];
  speed->y = [atomic asNumber];
  // (2) parse width/height
  atomic = [command objectAtIndex:2];
  *width = [atomic asNumber];
  atomic = [command objectAtIndex:3];
  *height= [atomic asNumber];
  // (4) friction/elasticy
  atomic = [command objectAtIndex:4];
  *elasticy = [atomic asNumber];
  // (3) texture path
  atomic = [command objectAtIndex:5];
  *path = [atomic asString];
}


-(id) init:(GameMapFileObject*)par withScene:(GameScene *)scene
    startX:(float)startX startY:(float)startY withPath:(NSString *__autoreleasing *)path
{
  self = [super init];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  PhysicalEntitySettings settings;
  _scene = scene;
  float elasticy;
  [self parseCommandParameter:par
                    withSpeed:&(settings.speed)
                    withWidth:&(settings.width)
                   withHeight:&(settings.height)
                 withElasticy:&(elasticy)
              withTexturePath:path];
  settings.absolute_position.x = startX + settings.width/2.0f;
  settings.absolute_position.y = startY + settings.height/2.0f;
  settings.penetration = NO;
  
  _entity = [scene.physical_world addPhysicalEntity:&settings
                                        onCollision:@selector(onCollision:withShape:)
                                       onOutOfBound:@selector(onOutOfBound)
                                           targetAt:self];
  _base_shape = [_entity
                 createBoxPhysicalShape:
                 CGSizeMake(settings.width,settings.height)];
  
  [_entity addPhysicalShape:_base_shape];
  
  _base_shape.elasticy = elasticy;
  
  assert(_entity);
  return self;
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene withPath:(NSString**)p
{
  float startX = [self getPropertyNumber:par withKey:@"StartX"];
  float startY = [self getPropertyNumber:par withKey:@"StartY"];
  self = [self init:par withScene:scene startX:startX startY:startY withPath:p];
  return self;
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  return NO;
}


-(void) onOutOfBound
{
}

@end
