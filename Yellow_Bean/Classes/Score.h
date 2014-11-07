//
//  Gold.h
//  Mario
//
//  Created by Dian Peng on 3/31/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Gold.h"

@interface Score : Gold_OldCompatible
+(id)createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;
-(void) onChange:(int)value;
@end
