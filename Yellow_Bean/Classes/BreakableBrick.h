//
//  BreakableBrick.h
//  prototype
//
//  Created by Yifan Zhou on 3/2/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BrickBase.h"

@interface BreakableBrick : BrickBase
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
