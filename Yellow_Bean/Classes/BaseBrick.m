//
//  GoldenBrick.m
//  prototype
//
//  Created by Dian Peng on 3/1/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "BaseBrick.h"
#import "PhysicalWorld.h"
#import "RepeatableSprite.h"
#import "CCTexture_Private.h"
#import "GameScene.h"

@implementation BaseBrick
{
  RepeatableSprite* _sprite;
}

+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene
{
  id obj = [[BaseBrick alloc]init:par withScene:scene];
  return obj;
}



-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  NSString* path;
  self = [super init:par withScene:scene withPath:&path];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  _sprite = [[RepeatableSprite alloc ] initWithImageNamed:path
                                       withWidth:self.physical_entity.width
                                       withHeight:self.physical_entity.height];
  if( _sprite == nil )
    return nil;
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
