//
//  Hint.h
//  Yellow_Bean
//
//  Created by Dian Peng on 4/21/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"


@class GameMapFileObject;
@class GameScene;

// This class is used for tutorial level design.
// The level designer can put this to the tutorial level
// and give hint for the player.

// ---------------------------------------------------------
// [StartX:]
// [StartY:]
// Hint = {
//   Message("");
//   Effect(color,size,font-family,fadein,duration,fadeout);
// };
// ---------------------------------------------------------

@interface Hint : CCNode
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
@end
