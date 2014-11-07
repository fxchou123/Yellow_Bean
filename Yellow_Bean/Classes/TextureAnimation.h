//
//  TextureAnimation.h
//  Mario
//
//  Created by Dian Peng on 3/22/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCSprite.h"
#import "Misc.h"

@interface TextureAnimation : CCSprite

-(id) initAnimationWithNamedImage:(NSString*)name
                       withFrames:(int) frames
                    withFrequency:(float) freq
                    withFrameSize:(vec2_t)size;

-(id) initAnimationWithNamedImage:(NSString*)name
                       withFrames:(int) frames
                    withFrequency:(float) freq
                    withFrameSize:(vec2_t)size
                             loop:(BOOL)loop;

-(void) Replay;
-(void) Play;
-(void) Pause;
-(void) Stop;
-(BOOL) isStopped;

@property float frequency;
@property int current_frame;
@property BOOL loop;
@end
