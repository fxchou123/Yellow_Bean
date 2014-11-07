//
//  Fire.h
//  Yellow_Bean
//
//  Created by Dian Peng on 4/8/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"

@class GameMapFileObject;
@class GameScene;

@interface Fire : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
