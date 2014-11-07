//
//  GoldenBrick.h
//  prototype
//
//  Created by Dian Peng on 3/1/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BrickBase.h"

@interface BaseBrick : BrickBase
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
