//
//  AirObstacle.m
//  Mario
//
//  Created by Yifan Zhou on 4/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "AirObstacle.h"
#import "CCSprite.h"
#import "PhysicalWorld.h"
#import "GameScene.h"

@implementation AirObstacle
{
  CCSprite* _sprite;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  id obj = [[AirObstacle alloc]init:par withScene:scene];
  return obj;
}



-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  NSString* path;
  self = [super init:par withScene:scene withPath:&path];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  _sprite = [[CCSprite alloc ] initWithImageNamed:path ];
  assert(_sprite);
  _sprite.scaleY = self.physical_entity.height/ _sprite.textureRect.size.height;
  _sprite.position = ccp(self.physical_entity.position.x,self.physical_entity.position.y);
  [self addChild:_sprite];
  return self;
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  return NO;
}

-(void) onOutOfBound
{
  [self.game_scene removeChild:self];
}

-(void) update:(CCTime)delta
{
  _sprite.position = ccp(self.physical_entity.position.x,self.physical_entity.position.y);
}

@end
