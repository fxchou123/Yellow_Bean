//
//  Background.m
//  Mario
//
//  Created by Yifan Zhou on 3/8/14.
//  Copyright 2014 Yifan Zhou. All rights reserved.
//

#import "Background.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "CCSprite.h"
#import "CCParallaxNode.h"
#import "PhysicalWorld.h"

@implementation Background
{
  CCSprite *_sprite1;
  CCSprite *_sprite2;
  GameScene* _scene;
  float _speed;
}

+(id) createObject:(GameMapFileObject*)par withScene:(GameScene *)scene
{
  return [[Background alloc] init:par withScene:scene];
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if( self == nil ) return nil;
  NSMutableArray* command = [par asCommand];
  assert(command.count ==3);
  
  
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _speed = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  NSString* texture_path = [atomic asString];
  
  atomic = [command objectAtIndex:2];
  NSString* texture_path2 = [atomic asString];
  
  _scene = scene;
  
  _sprite1 =[CCSprite spriteWithImageNamed:texture_path];
  _sprite1.anchorPoint=ccp(0.0, 0.0);
  _sprite1.position = ccp(0, 0);
  /*
  float scale_x = width/_sprite1.textureRect.size.width;
  float scale_y = height/_sprite1.textureRect.size.height;
  _sprite1.scaleX = scale_x;
  _sprite1.scaleY = scale_y;
   */
  
  _sprite2=[CCSprite spriteWithImageNamed:texture_path2];
  _sprite2.anchorPoint=ccp(0, 0);
  _sprite2.position=ccp(_sprite1.boundingBox.size.width,0);
  /*
  _sprite2.scaleX = width/_sprite2.textureRect.size.width;
  _sprite2.scaleY = height/_sprite2.textureRect.size.height;
  */
  [self addChild:_sprite1 z:1];
  [self addChild:_sprite2 z:0];
  return self;
}


- (void)update:(CCTime)dt {
  float offset = -_speed*dt;
  
  _sprite1.position=ccp(_sprite1.position.x+offset,0.0f);
  _sprite2.position=ccp(_sprite2.position.x+offset,0.0f);
  
  if(_sprite1.position.x<-_sprite1.boundingBox.size.width)
  {
    _sprite1.position=ccp(_sprite2.boundingBox.size.width+_sprite2.position.x,_sprite1.position.y);
  }
  if(_sprite2.position.x<-_sprite2.boundingBox.size.width)
  {
    _sprite2.position=ccp(_sprite1.boundingBox.size.width+_sprite1.position.x,_sprite2.position.y);
  }
  
}


-(void) stop
{
  _speed = 0.0f;
}


@end
