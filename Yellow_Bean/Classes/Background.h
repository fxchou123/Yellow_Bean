//
//  Background.h
//  Mario
//
//  Created by Yifan Zhou on 3/8/14.
//  Copyright 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"

@class GameScene;
@class GameMapFileObject;

@interface Background : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
-(void) stop;
@end
