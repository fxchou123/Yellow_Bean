//
//  WayPoint.h
//  Mario
//
//  Created by Yifan Zhou on 3/18/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Misc.h"

@class GameMapFileObject;
@class GameScene;
@class PhysicalWorld;
// ---------------------------------------------------------------
// Way point class. This class is used to generate next position
// if you want to use the WayPoint feature that it has.
// The way point configuration will be placed inside of the game
// scene file .
// ---------------------------------------------------------------
@interface WayPoint : NSObject
-(id) init:(GameMapFileObject*)par withPoint:(vec2_t)pt withPhysicalWorld:(PhysicalWorld*)world;
-(void) setAsLinearMovement:(vec2_t)velocity;
-(BOOL) update:(float)delta;
@property (readonly) vec2_t position;
@property (readonly) BOOL dead;
@end


