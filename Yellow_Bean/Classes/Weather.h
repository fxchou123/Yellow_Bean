//
//  Weather.h
//  Yellow_Bean
//
//  Created by Yifan Zhou on 4/10/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "CCNode.h"


@class GameMapFileObject;
@class GameScene;

@interface Weather : CCNode
+(id)createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
