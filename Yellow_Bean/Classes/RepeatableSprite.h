//
//  BrickSprite.h
//  Mario
//
//  Created by Dian Peng on 3/11/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CachedSprite.h"

@interface RepeatableSprite : CachedSprite
-(id) initWithImageNamed:(NSString *)imageName withWidth:(float) width withHeight:(float)height;
@end
