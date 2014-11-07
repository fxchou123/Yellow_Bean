//
//  Score.h
//  Mario
//
//  Created by Yifan Zhou on 3/10/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"
#import "Misc.h"
#import "BaseItem.h"

@interface Gold : CCNode
+(id)createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
enum {
  GOLD_BROWNZE =1,
  GOLD_SILVER,
  GOLD_GOLD,
  GOLD_STAR
};

@end

@protocol GoldProtocol
-(void) forceToDie;
-(void) levelUp;
// This is used for magnitude
-(void) setSpeed:(vec2_t)vel;
@property (readonly) vec2_t scene_position;
@end


// ----------------------------------------------------
// This is useful for the implementation of Gold class
// since the Gold class can simply inherit this class
// and write its own implementation of onChange.
// ----------------------------------------------------
@interface Gold_OldCompatible : BaseItem<GoldProtocol>
-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene withSoundName:(NSString*)sfx;
-(void) forceToDie;
-(void) onChange:(int)value;
-(void) levelUp;
// This is used for magnitude
-(void) setSpeed:(vec2_t)vel;
@property (readonly) vec2_t scene_position;
@end







