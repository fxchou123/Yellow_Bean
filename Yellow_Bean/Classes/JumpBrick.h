//
//  JumpBrick.h
//  Mario
//
//  Created by Dian Peng on 3/11/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "BrickBase.h"

@interface JumpBrick : BrickBase
+(id) createObject:(GameMapFileObject *)par withScene:(GameScene *)scene;
@end
