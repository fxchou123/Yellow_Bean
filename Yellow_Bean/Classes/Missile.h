//
//  Missle.h
//  prototype
//
//  Created by Dian Peng on 3/2/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"


@class GameMapFileObject;
@class GameScene;

@interface Missile : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
-(void) update:(CCTime)delta;
@end
