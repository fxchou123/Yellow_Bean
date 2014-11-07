//
//  CachedSprite.m
//  Yellow_Bean
//
//  Created by Dian Peng on 4/14/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CachedSprite.h"
#import "CCSpriteFrame.h"
#import "CCSpriteFrameCache.h"
#import "CCTexture.h"
#import "CCSprite.h"

@implementation CachedSprite

-(id) initWithImageNamed:(NSString *)imageName {
  CCSpriteFrame* frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:imageName];
  if( frame == nil ) {
    frame = [CCSpriteFrame frameWithImageNamed:imageName];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:imageName];
  }
  self = [super initWithSpriteFrame:frame];
  return self;
}

@end
