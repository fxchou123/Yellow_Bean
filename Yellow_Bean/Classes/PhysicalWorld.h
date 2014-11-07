//
//  PhysicalWorld.h
//  prototype
//
//  Created by Yifan Zhou on 2/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Misc.h"
@class PhysicalEntity;
@class CCNode;

enum {
  SIMPLE_COLLISION_SHAPE,
  CP_COLLISION_SHAPE
};

@interface PhysicalShape :NSObject
@property float elasticy;
@property PhysicalEntity* entity;
@property (readonly) int collision_type;
@end

// ---------------------------------------------
// Here all the physical entity is ridgid body
// which means that all the entities will be acted
// as none penetration entity.
// ----------------------------------------------
@interface PhysicalEntity: NSObject
@property vec2_t speed;
@property (readonly) vec2_t position;
@property (readonly) vec2_t absolute_position;
@property (readonly) float width;
@property (readonly) float height;
@property (readonly) float friction;
@property (readonly) float elasticy;
@property BOOL penetration;
@property BOOL dead;
@property void* user_data;
// ------------------------------------------
// Instead of creating the shape automatically,
// here I will let the user create the shape
// manually.
// ------------------------------------------
-(PhysicalShape*) createBoxPhysicalShape:(CGSize)size;
// ---------------------------------------------------
// This type of shape will only do collision detection
// and not physical simulation. It is useful when you
// want to detect it with other simple collidable object
// ---------------------------------------------------
-(PhysicalShape*) createSimpleCollidableBoxShape:(CGSize)size;
-(void) addPhysicalShape:(PhysicalShape*)shape;
-(void) addPhysicalShape:(PhysicalShape *)shape withOffset:(vec2_t)offset;
-(void) removePhysicalShape:(PhysicalShape*)shape;

@end

// ------------------------------------------------
// A physical actor is a object that can be used to
// represent the player since it will do collision
// detection with ground.
// And also it provides convinient method to change
// states of the object.
// ------------------------------------------------
@interface PhysicalActor : PhysicalEntity
@property (readonly) float mass;
// ------------------------------------------------------------
// Since our platform has INFINITE mass,jump operation must be
// fixed by continuously setting the speed of X to zero to acheive
// The caller function should add its return CCNode to its child
// and this node will be removed by itself.
// ------------------------------------------------------------
-(CCNode*) jump:(float) jumpSpeed;
-(void) dump:(float) dumpSpeed;
-(void) stable;
// ------------------------------------------------------------
// Shrink operation.
// ------------------------------------------------------------
-(CCNode*) shrink;

-(void) dashRight:(float)speed withDuration:(float)duration;
-(void) dash:(float)speed withDuration:(float)duration;
// -----------------------------------
// Give you method to set a impulse to
// change the states of the character in
// the physical world
// -----------------------------------
-(void) setImpulse:(vec2_t)force;
-(BOOL) isStuck;
-(void) applyForce:(vec2_t)force;
-(void) setPosition:(vec2_t)pos;
@end


@interface SimpleCollidableObject : NSObject
@property rect_t bound;
@property BOOL dead;
@end


@interface SimpleMovableCollidableObject: SimpleCollidableObject
@property vec2_t position;
@property vec2_t absolute_position;
@property float width;
@property float height;
@property vec2_t speed;
@end


@interface BannerObject : NSObject
@property (readonly) rect_t top;
@property (readonly)rect_t bottom;
@property vec2_t position;
@end

typedef struct {
  vec2_t move_speed;
  // gravity length for the world
  float gravity;
  rect_t viewport;
  vec2_t absolute_position;
} PhysicalWorldSettings;

typedef struct {
  float width;
  float height;
  vec2_t absolute_position;
  vec2_t speed;
  BOOL penetration;
} PhysicalEntitySettings;

typedef struct {
  float width;
  float height;
  vec2_t absolute_position;
  BOOL penetration;
  float mass;
} PhysicalActorSettings;


typedef struct {
  float width;
  float height;
  vec2_t absolute_position;
  vec2_t speed;
} SimpleMovableCollidableObjectSettings;

@class PhysicalWorld;

@protocol PhysicalWorldEffect<NSObject>
-(BOOL) isAlive;
-(void) takeEffect:(PhysicalWorld*)world withDelta:(float)dt;
@end


@interface PhysicalWorld : NSObject

@property vec2_t current_speed;
@property float gravity;
@property rect_t viewport;

@property vec2_t absolute_position;

-(void) stop;
-(void) resume;

-(id) initWithConfig:(const PhysicalWorldSettings*)settings;

// -----------------------------------------------------
// Call this function in frame update to tick the world
// -----------------------------------------------------
-(void) tickWorld:(float)timeDiff;

-(PhysicalEntity*) addPhysicalEntity:(const PhysicalEntitySettings*)object
                         onCollision:(SEL)entityCollision
                         onOutOfBound:(SEL)outOfBound targetAt:(NSObject*) target;

-(PhysicalActor*) addPhysicalActor:(const PhysicalActorSettings*)object
                         onCollision:(SEL)entityCollision
                         onOutOfBound:(SEL)outOfBound targetAt:(NSObject*) target;


-(SimpleCollidableObject*) addSimpleCollidableObject:(rect_t)bound  onCollision:(SEL)collision
                           onOutOfBound:(SEL)outOfBound targetAt:(NSObject*) target;


-(SimpleMovableCollidableObject*) addMovableCollidableObject:(SimpleMovableCollidableObjectSettings*)settings
                          onCollision:(SEL)collision
                          onOutOfBound:(SEL)outOfBound
                          targetAt:(NSObject*)target;


-(BannerObject*) addBannerObject:(rect_t)bound
                     onCollision:(SEL)collision
                onOtherCollision:(SEL)other_collision
                    onOutOfBound:(SEL)outOfBound
                        targetAt:(NSObject*)target;


-(void) addEffect:(id<PhysicalWorldEffect>)effect;


-(void) removePhysicalEntity:(PhysicalEntity*)entity;
-(void) removePhysicalActor:(PhysicalActor*)actor;
-(void) removeSimpleCollidableObject:(SimpleCollidableObject*)collision_object;
-(void) removeMoveableCollidableObject:(SimpleMovableCollidableObject*)collision_object;
-(void) removeBanner:(BannerObject*)banner;
-(NSMutableArray*) querySimpleObjectCollision:(rect_t)bound withClass:(Class)cls;

@end


@class GameMapFileObject;

// ---------------------------------------------------------
// Some useful PhysicalWorldEffect class that can help you !!
// -----------------------------------------------------------

@interface PhysicalWorldEffect_ChangeSpeed : NSObject<PhysicalWorldEffect>

-(void) takeEffect:(PhysicalWorld *)world withDelta:(float)dt;
-(id) init:(vec2_t) speed withDuration:(float)duration withActor:(PhysicalActor*)actor;
-(BOOL) isAlive;
// ----------------------------------------
// Supporting script initialization here
// ----------------------------------------
+(id) createObject:(GameMapFileObject*)par;

@end














