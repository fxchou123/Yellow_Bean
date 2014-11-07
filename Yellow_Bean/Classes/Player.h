//
//  Player.h
//  prototype
//
//  Created by Yifan Zhou on 3/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"
#import "Misc.h"

@class CCParticleSystem;
@class Player;
@class PhysicalActor;
@class GameScene;
@class GameMapFileObject;
@class PhysicalShape;

@protocol PlayerEffect <NSObject>
-(BOOL) isAlive;
-(void) takeEffect:(Player*) player withDelta:(float)dt;
-(void) destroy;
@end

@protocol PlayerLifeWatcher <NSObject>
-(BOOL) onPlayerDieInvoked;
-(BOOL) update:(Player*)player withDelta:(float)dt;
-(void) destroy;
@end

@interface PlayerAttachObject : NSObject
@property PhysicalShape* physical_shape;
@end

@interface Player : CCNode

@property float scale_x;
@property float scale_y;
@property float jump_height;
@property float jump_cool_down;
@property int jump_time;
@property (readonly) vec2_t scene_position;
@property (readonly) float width;
@property (readonly) float height;

+(id) createObject:(GameMapFileObject*)par withScene:(GameScene*)scene;

-(void) update:(CCTime)delta;
-(void) leftButtonCall;
-(void) leftButtonRelease;
-(void) rightButtonCall;
-(void) rightButtonRelease;

// This interface will force the player to jump here, it will ignore
// the cool down and also any other related time issue related to jump
-(void) forceJump;
-(void) addEffect:(id<PlayerEffect>)effect;

// ---------------------------------------------------------
// Notification function to synchronize player state change
// ---------------------------------------------------------
-(void) addPlayerStateNotification:(NSObject*)object withHandler:(SEL)notifier;


// Call this function to end the game. The player itself will test
// itself that it needs to die or not since the player will be in
// certain condition that is invincible
-(void) die;
-(void) addPlayerLifeWatcher:(id<PlayerLifeWatcher>)watcher;
-(BOOL) isAlive;
-(BOOL) isStand;
-(BOOL) isShrink;


// ----------------------------------------------------------
// Helper function for creating customize attachable object
// ----------------------------------------------------------
-(PlayerAttachObject*) attachPhysicalShape:(CGSize)size onCollision:(SEL)collision targetAt:(NSObject*)target;
-(void) removePhysicalShape:(PlayerAttachObject*)object;

// -----------------------------------------------------------
// Please call this function to test this collision is really
// a player collision instead of attach object collision
// -----------------------------------------------------------
-(BOOL) isPlayerCollided:(PhysicalShape*)shape;

@property PhysicalActor* physical_actor;

@end

// ----------------------------------
// This effect will make the player
// invincible and not to react to the
// dead operation here !
// ----------------------------------
@interface PlayerInvincibleEffect : NSObject<PlayerEffect>

@end










