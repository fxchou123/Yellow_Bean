//
//  NodeRotator.h
//  Mario
//
//  Created by Dian Peng on 3/11/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"
#import "Misc.h"

@interface NodeRotator : CCNode
-(id) init:(vec2_t) position withRadius:(float)radius withFrequency:(float)time;
@property vec2_t anchor_point;
@property float radius;
@property float frequency;
-(void) setTarget:(CCNode*)node;
-(void) removeTarget:(CCNode*)node;
@end
