//
//  AirObstacle.h
//  Mario
//
//  Created by Yifan Zhou on 4/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "BlockBase.h"

@interface AirObstacle : BlockBase
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
