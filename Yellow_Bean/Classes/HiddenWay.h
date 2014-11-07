//
//  HiddenWay.h
//  Mario
//
//  Created by Yifan Zhou on 4/4/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "WayPointBaseItem.h"

@interface HiddenWay : WayPointBaseItem
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
