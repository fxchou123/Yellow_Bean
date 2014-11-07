//
//  SoundManager.h
//  Mario
//
//  Created by Dian Peng on 3/21/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GameScene;
@class GameMapFileObject;

@interface SoundManager : NSObject
+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;

-(void) stopBackgroundMusic;
-(void) playBackgroundMusic;
-(void) playEffect:(NSString*)key;
-(void) stopAll;
-(void) playGameOverMusic;
-(void) stopGameOverMusic;
@end
