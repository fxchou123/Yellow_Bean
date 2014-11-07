//
//  BrickSprite.m
//  Mario
//
//  Created by Dian Peng on 3/11/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "RepeatableSprite.h"
#import "CCTexture_Private.h"
@implementation RepeatableSprite
-(id) initWithImageNamed:(NSString *)imageName withWidth:(float) width withHeight:(float)height;{
  self = [super initWithImageNamed:imageName];
  if(self == nil) return nil;
  // Making the texture repeatable
  ccTexParams params = {GL_LINEAR,GL_LINEAR,GL_REPEAT,GL_REPEAT};
  [self setTextureRect:CGRectMake(0.0,0.0,width,height)];
  [self.texture setTexParameters:&params];
  return self;
}
@end
