//
//  BlinkSprite.h
//  Mario
//
//  Created by Dian Peng on 3/20/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"
#import "Misc.h"
@class CCSprite;


// The blink sprite will help you to simulate blink effect for a certain sprite
// or certain texture image . It's useful !!!
@interface BlinkSprite : CCNode

-(void) setSpritePosition:(vec2_t)position;
-(id) initWithNamedImage:(NSString*)name withFrequency:(float)freq withDuration:(float)duration;
-(id) initWithSprite:(CCSprite*)sprite withFrequency:(float)freq withDuration:(float)duration;
@property (readonly) BOOL alive;

@end
