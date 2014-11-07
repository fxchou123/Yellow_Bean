//
//  RestartParticle.m
//  Mario
//
//  Created by Dian Peng on 4/3/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "RestartParticle.h"

@implementation CCParticleSystem (RestartParticle)
-(void)enable
{
  _active = YES;
  _elapsed = 0.0f;
}

-(void)disable
{
  _active = NO;
}
@end
