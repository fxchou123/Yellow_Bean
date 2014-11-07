//
//  PhysicalWorld.m
//  prototype
//
//  Created by Yifan Zhou on 2/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "PhysicalWorld.h"
#import "CCDirector.h"
#import "GameMapFile.h"
#import "chipmunk.h"
#import "chipmunk_unsafe.h"
#import "CCNode.h"

// ---------------------------------------------------
// A jump helper node to fix the physical simulation
// bug for actor
// ---------------------------------------------------

@interface JumpFixNode : CCNode
{
  PhysicalActor* _actor;
}
-(id) init:(PhysicalActor*)actor;
@end

@implementation PhysicalShape
{
  @public
  cpShape* _cp_shape;
  int _type;
  // Simple collision shape data
  rect_t _bound;
  // The bound has a anchor point + width,height
  // This is not typical AABB data structure
  PhysicalEntity* _entity;
  // Offset
  vec2_t _offset;
}


@synthesize collision_type = _type;

-(float) elasticy
{
  if( _type == CP_COLLISION_SHAPE ) {
    assert(_cp_shape != nil);
    return cpShapeGetElasticity(_cp_shape);
  }
  return 0.0f;
}

-(void) setElasticy:(float)elasticy
{
  if( _type == CP_COLLISION_SHAPE ) {
    assert(_cp_shape != nil);
    cpShapeSetElasticity(_cp_shape, elasticy);
  }
}


@synthesize entity = _entity;

// Please call this function AFTER you update the
// actor. This is useful to update the simple collision
// data here.
-(void) tickCollisionShape:(float)delta
{
  if( _type == SIMPLE_COLLISION_SHAPE ) {
    _bound.x = _entity.position.x;
    _bound.y = _entity.position.y;
  }
}

-(rect_t) GetAABB
{
  if(_type == SIMPLE_COLLISION_SHAPE) {
    return MakeRect( _bound.x - _bound.width/2.0f , _bound.y - _bound.height/2.0f ,
                    _bound.width , _bound.height );
  } else {
    cpBody* body = cpShapeGetBody(_cp_shape);
    cpVect pos = cpBodyGetPosition(body);
    return MakeRect( pos.x - _bound.width/2.0f + _offset.x,
                     pos.y - _bound.height/2.0f + _offset.y,
                    _bound.width , _bound.height );
  }
}

@end

@implementation PhysicalEntity
{
  @public
  vec2_t _absolute_screen_speed;
  vec2_t _previous_position;
  vec2_t _speed;
  vec2_t _position;
  vec2_t _absolute_position;
  float _width;
  float _height;
  float _friction;
  float _elasticy;
  BOOL _penetration;
  BOOL _dead;
  SEL _on_out_of_bound;
  SEL _on_actor_collision;
  NSObject* _target;
  cpBody* _cp_body;
  NSMutableArray* _cp_shapes;
  void* _user_data;
  LinkedListIterator* _identity;
  int _collision_type;
  // A weak pointer reference to the cpSpace
  cpSpace* _cp_space;
}
@synthesize position = _position;
@synthesize absolute_position = _absolute_position;
@synthesize width = _width;
@synthesize height = _height;
@synthesize penetration = _penetration;
@synthesize dead = _dead;
@synthesize user_data = _user_data;
@synthesize friction = _friction;
@synthesize elasticy = _elasticy;


// -----------------------------------
// Speed settings goes here
// -----------------------------------
-(vec2_t) speed
{
  return _speed;
}

-(void) setSpeed:(vec2_t)speed
{
  float offset_x = _speed.x-speed.x;
  float offset_y = _speed.y-speed.y;
  _absolute_screen_speed.x += offset_x;
  _absolute_screen_speed.y += offset_y;
}

-(void) updateWorldSpeed:(vec2_t)speed
{
  _absolute_screen_speed = VectorSub(&_speed,&speed);
}
// -----------------------------------
// Physical shape interface comes here
// -----------------------------------
-(PhysicalShape*) createBoxPhysicalShape:(CGSize)size
{
  PhysicalShape* shape = [[PhysicalShape alloc] init];
  shape->_cp_shape = cpBoxShapeNew(_cp_body,size.width,size.height,0.0f);
  shape->_type = CP_COLLISION_SHAPE;
  shape->_bound.width = size.width;
  shape->_bound.height = size.height;
  shape->_entity = self;
  cpShapeSetFriction(shape->_cp_shape, 0.0f);
  return shape;
}

-(PhysicalShape*) createSimpleCollidableBoxShape:(CGSize)size
{
  PhysicalShape* shape = [[PhysicalShape alloc] init];
  shape->_bound.height = size.height;
  shape->_bound.width = size.width;
  shape->_entity  = self;
  shape->_type = SIMPLE_COLLISION_SHAPE;
  return shape;
}

-(void) addPhysicalShape:(PhysicalShape *)shape withOffset:(vec2_t)offset
{
  if( shape->_type == CP_COLLISION_SHAPE ) {
    assert([_cp_shapes containsObject:shape] == NO);
    assert(cpShapeGetBody(shape->_cp_shape) == _cp_body);
    cpShapeSetCollisionType(shape->_cp_shape, (cpCollisionType)_collision_type);
    cpSpaceAddShape(_cp_space,shape->_cp_shape);
    cpShapeSetUserData(shape->_cp_shape, (__bridge cpDataPointer)(self));
  } else {
    shape->_bound.x = self.position.x;
    shape->_bound.y = self.position.y;
    shape->_offset = offset;
  }
  [_cp_shapes addObject:shape];
}

-(void) addPhysicalShape:(PhysicalShape *)shape
{
  if( shape->_type == CP_COLLISION_SHAPE ) {
    assert([_cp_shapes containsObject:shape] == NO);
    assert(cpShapeGetBody(shape->_cp_shape) == _cp_body);
    cpShapeSetCollisionType(shape->_cp_shape, (cpCollisionType)_collision_type);
    cpSpaceAddShape(_cp_space,shape->_cp_shape);
    cpShapeSetUserData(shape->_cp_shape, (__bridge cpDataPointer)(self));
  } else {
    shape->_bound.x = self.position.x;
    shape->_bound.y = self.position.y;
  }
  [_cp_shapes addObject:shape];
}

-(void) removePhysicalShape:(PhysicalShape*)shape
{
  if( shape->_type == CP_COLLISION_SHAPE ) {
    assert(cpShapeGetBody(shape->_cp_shape) == _cp_body);
    cpShapeSetCollisionType(shape->_cp_shape, _collision_type);
    cpSpaceRemoveShape(_cp_space,shape->_cp_shape);
  }
  [_cp_shapes removeObject:shape];
}

-(void) reindexAllShapes
{
  for( int i = 0 ; i < _cp_shapes.count ; ++i ) {
    PhysicalShape* shape = [_cp_shapes objectAtIndex:i];
    if(shape->_type == CP_COLLISION_SHAPE) {
      cpSpaceReindexShape(_cp_space, shape->_cp_shape);
    }
  }
}

-(void) removeAllShapes
{
  for( int i = 0 ; i < _cp_shapes.count ; ++i ) {
    PhysicalShape* shape = [_cp_shapes objectAtIndex:i];
    if( shape->_type == CP_COLLISION_SHAPE ) {
      cpSpaceRemoveShape(_cp_space, shape->_cp_shape);
      cpShapeFree(shape->_cp_shape);
    }
  }
  [_cp_shapes removeAllObjects];
}

-(void) tick:(float)delta
{
  for( int i = 0 ; i < _cp_shapes.count ; ++i ) {
    PhysicalShape* shape = [_cp_shapes objectAtIndex:i];
    [shape tickCollisionShape:delta];
  }
}

-(PhysicalShape*) findCPShape:(cpShape*)cp_shape
{
  for( int i = 0 ; i < _cp_shapes.count ; ++i ) {
    PhysicalShape* shape = [_cp_shapes objectAtIndex:i];
    if( shape->_type == CP_COLLISION_SHAPE ) {
      if( shape->_cp_shape == cp_shape )
        return shape;
    }
  }
  return nil;
}

@end

enum {
  COLLISION_SHAPE_ENTITY =1,
  COLLISION_SHAPE_ACTOR
};

@implementation PhysicalActor
{
  @public
  PhysicalWorld* _world;
  float _mass;
  LinkedListIterator* _identity;
}

-(cpVect) GetCPVelocity
{
  return cpBodyGetVelocity(_cp_body);
}

// ---------------------------------------------
// Override setter/getter for our current speed
// in PhysicalEntity class
// ---------------------------------------------

-(id) init
{
  self = [super init];
  if( self == nil ) return nil;
  return self;
}

-(void) setImpulse:(vec2_t)force
{
  cpVect vec;
  vec.x = force.x;
  vec.y = force.y;
  cpVect pt;
  pt.x = _position.x;
  pt.y = _position.y;
  cpBodyApplyImpulseAtWorldPoint(_cp_body,vec,pt);
}

-(void) applyForce:(vec2_t)force
{
  cpVect f;
  f.x = force.x;
  f.y = force.y;
  cpVect pt;
  pt.x = _position.x;
  pt.y = _position.y;
  cpBodyApplyForceAtWorldPoint(_cp_body, f, pt);
}

-(void) setRelativeVelocity:(vec2_t)velocity
{
  cpVect vel;
  vel.x = velocity.x;
  vel.y = velocity.y;
  cpBodySetVelocity(_cp_body, vel);
}

-(CCNode*) shrink
{
  return [[JumpFixNode alloc] init:self];
}


-(CCNode*) jump:(float) jumpSpeed
{
  [self setRelativeVelocity:MakeVector(0.0f,jumpSpeed)];
  return [[JumpFixNode alloc] init:self];
}

-(void) dump:(float)dumpSpeed
{
  [self setRelativeVelocity:MakeVector(0.0f,dumpSpeed)];
}

-(void) stable
{
  cpVect vel = [self GetCPVelocity];
  [self setRelativeVelocity:MakeVector(0.0f,vel.y)];
}

-(void) dashRight:(float)speed withDuration:(float)duration
{
  vec2_t spd;
  spd.x = speed;
  spd.y = 0.0f;
  [_world addEffect:[[PhysicalWorldEffect_ChangeSpeed alloc]init:spd withDuration:duration withActor:self]];
}

-(void) dash:(float)speed withDuration:(float)duration
{
  vec2_t spd;
  spd.x = speed;
  spd.y = 0.0f;
  [_world addEffect:[[PhysicalWorldEffect_ChangeSpeed alloc]init:spd withDuration:duration withActor:self]];
}

-(BOOL) isStuck
{
  cpVect speed = [self GetCPVelocity];
  return speed.x <0.0f;
}

// ------------------------------
// Rewrite the property method
// ------------------------------

-(void) setPosition:(vec2_t)pos
{
  // --------------------------
  // Setting new relative position.
  // We need to update the absolute
  // position here as well
  // --------------------------
  float offset_x = pos.x - _position.x;
  float offset_y = pos.y - _position.y;
  _absolute_position.x += offset_x;
  _absolute_position.y += offset_y;
  _position = pos;
  _previous_position = _position;
  // Update the position in the chipmunk world
  cpVect ps;
  ps.x = pos.x;
  ps.y = pos.y;
  cpBodySetPosition(_cp_body,ps);
}

@synthesize mass = _mass;

@end


@implementation SimpleCollidableObject
{
  @public
  rect_t _bound;
  SEL _on_collision;
  SEL _on_outof_bound;
  BOOL _dead;
  NSObject* _target;
  LinkedListIterator* _identity;
}
@synthesize bound = _bound;
@synthesize dead = _dead;

-(id) init:(rect_t)bound
{
  self = [self init];
  if(self == nil)return nil;
  _bound = bound;
  return self;
}
@end

@implementation SimpleMovableCollidableObject
{
  @public
  vec2_t _speed;
  float _width,_height;
  vec2_t _position;
  vec2_t _absolute_position;
}

@synthesize speed = _speed;
@synthesize width = _width;
@synthesize height= _height;
@synthesize position = _position;
@synthesize absolute_position = _absolute_position;

-(rect_t) bound
{
  return MakeRect(_position.x,_position.y,_width,_height);
}

-(void) setBound:(rect_t)bound
{
  _width = bound.width;
  _height= bound.height;
  _position.x = bound.x;
  _position.y = bound.y;
  // Do not forget to flush the super::_bound
  _bound = bound;
}

@end

// --------------------------------------------------------------------
// Jump fix node implementation:
// What I gonna do is very simple: I will try to grab the speed in the
// simulation world and if I see that the speed for X axis is negative
// which is because of a stuck, I will continuously setting it to zero.
// Once I find out that the speed is not zero, I will simply remove it.
// --------------------------------------------------------------------

@implementation JumpFixNode

-(void) update:(CCTime)delta
{
  cpVect vec = cpBodyGetVelocity(_actor->_cp_body);
  if(vec.x <0.0f) {
    // Negative! Fix it
    vec.x = 0.0f;
  } else {
    // Remove self
    [self.parent removeChild:self];
    return;
  }
  cpBodySetVelocity(_actor->_cp_body, vec);
}

-(id) init:(PhysicalActor*)actor
{
  self = [super init];
  if(self ==nil) return nil;
  _actor = actor;
  return self;
}

@end


@implementation BannerObject
{
  @public
  rect_t _top;
  rect_t _bottom;
  rect_t _body;
  SEL _on_collision_cb;
  SEL _on_out_of_bound_cb;
  SEL _on_other_collision_cb;
  NSObject* _target;
  LinkedListIterator* _identity;
}

@synthesize top = _top;
@synthesize bottom = _bottom;

-(vec2_t) position
{
  return MakeVector(_bottom.x,_bottom.y);
}

-(void) setPosition:(vec2_t)position
{
  _top.x = position.x;
  _top.y = position.y + 10.0f + _bottom.height/2.0f;
  _bottom.x = position.x;
  _bottom.y = position.y-5.f;
  _body.x = position.x;
  _body.y = position.y;
}


-(rect_t) getBodyAABB
{
  return MakeRect(_body.x-_body.width/2.0f,_body.y-_body.height/2.0f,_body.width,_body.height);
}

@end

@implementation PhysicalWorld
{
  @public
  LinkedList* _entity_list;
  LinkedList* _actor_list;
  LinkedList* _simple_collidable_list;
  LinkedList* _simple_moveable_list;
  LinkedList* _effect_list;
  LinkedList* _banner_list;
  // This array is used to do deletion after collision detection
  NSMutableArray* _discard_list;
  rect_t _viewport;
  vec2_t _speed;
  float _gravity;
  vec2_t _absolute_position;
  cpSpace* _cp_space;
  vec2_t _last_work_speed;
  
  float _cp_space_cur_timer;
  float _cp_space_step_timer;
}


@synthesize viewport = _viewport;
@synthesize gravity = _gravity;
@synthesize absolute_position = _absolute_position;


-(vec2_t) current_speed
{
  return _speed;
}

-(void) setCurrent_speed:(vec2_t)current_speed
{
  _speed = current_speed;
  // Physical Entity Speed Change
  LinkedListIterator* iter = [_entity_list begin];
  while( [iter hasNext] ) {
    PhysicalEntity* entity = (PhysicalEntity*)[iter deref];
    [entity updateWorldSpeed:current_speed];
    [iter move];
  }
}

-(void) stop
{
  _last_work_speed = _speed;
  _speed = MakeVector(0.0f, 0.0f);
  // Remove all the effects
  [_effect_list clear];
}

-(void) resume
{
  _speed = _last_work_speed;
}

-(vec2_t) calculateRelativePosition:(const vec2_t*)absolute_position
{
  return VectorSub(absolute_position,&_absolute_position);
}

-(BOOL) isInViewportWithAbsolutePosition:(vec2_t)absolute_position
                               withWidth:(float)width withHeight:(float)height
{
  vec2_t abs_pos = MakeVector(absolute_position.x-width/2.0f,absolute_position.y-height/2.0f);
  vec2_t position= [self calculateRelativePosition:&abs_pos];
  rect_t bound = MakeRect(position.x,position.y,width,height);
  return RectIsIntersect(&bound, &_viewport);
}

-(PhysicalEntity*) addPhysicalEntity:(const PhysicalEntitySettings *)object
                   onCollision:(SEL)collision
                   onOutOfBound:(SEL)outOfBound
                   targetAt:(NSObject*)target
{
  if( [self isInViewportWithAbsolutePosition:object->absolute_position
            withWidth:object->width withHeight:object->height] == NO ) {
    return nil;
  }
  PhysicalEntity* entity = [[PhysicalEntity alloc] init];
  entity->_absolute_position = object->absolute_position;
  entity->_width = object->width;
  entity->_height= object->height;
  entity->_position = [self calculateRelativePosition:&(object->absolute_position)];
  entity->_speed = object->speed;
  entity->_penetration = object->penetration;
  entity->_on_actor_collision = collision;
  entity->_on_out_of_bound = outOfBound;
  entity->_target = target;
  entity->_dead = NO;
  entity->_previous_position = entity->_position;
  // Chipmunk2d Physical Initialization --------------------------------------------
  entity->_cp_body = cpBodyNewStatic();
  entity->_cp_shapes= [[NSMutableArray alloc]init];
  entity->_identity = [_entity_list pushBack:entity];
  entity->_cp_space = _cp_space;
  // Setting the screen speed
  entity->_absolute_screen_speed = VectorSub(&(entity->_speed),&_speed);
  cpVect vect;
  vect.x = entity->_position.x;
  vect.y = entity->_position.y;
  entity->_collision_type = COLLISION_SHAPE_ENTITY;
  cpBodySetPosition(entity->_cp_body,vect);
  vect.x = entity->_absolute_screen_speed.x;
  vect.y = entity->_absolute_screen_speed.y;
  cpBodySetVelocity(entity->_cp_body, vect);
  
  return entity;
}

-(PhysicalActor*) addPhysicalActor:(const PhysicalActorSettings*)object
                  onCollision:(SEL)collision
                  onOutOfBound:(SEL)outOfBound targetAt:(NSObject*)target
{
  if( [self isInViewportWithAbsolutePosition:object->absolute_position
            withWidth:object->width withHeight:object->height] == NO ) {
    return nil;
  }
  PhysicalActor* actor = [[PhysicalActor alloc] init];
  actor->_width = object->width;
  actor->_height= object->height;
  actor->_absolute_position = object->absolute_position;
  actor->_position = [self calculateRelativePosition:&(object->absolute_position)];
  // Using property setter to invoke corresponding initializing parameter
  actor.speed = _speed;
  actor->_penetration = object->penetration;
  actor->_target = target;
  actor->_on_actor_collision = collision;
  actor->_on_out_of_bound = outOfBound;
  actor->_dead = NO;
  actor->_world = self;
  // Chipmunk2d Physical Initialization --------------------------------------------
  actor->_cp_body = cpBodyNew(object->mass,INFINITY);
  actor->_cp_shapes= [[NSMutableArray alloc] init];
  actor->_identity = [_actor_list pushBack:actor];
  actor->_cp_space = _cp_space;
  actor->_absolute_screen_speed.x =
  actor->_absolute_screen_speed.y = 0.0f;
  cpVect pos;
  pos.x = actor->_position.x;
  pos.y = actor->_position.y;
  actor->_collision_type = COLLISION_SHAPE_ACTOR;
  cpBodySetPosition(actor->_cp_body,pos);
  cpSpaceAddBody(_cp_space,actor->_cp_body);
  return actor;
}

-(BannerObject*) addBannerObject:(rect_t)bound
                     onCollision:(SEL)collision
                onOtherCollision:(SEL)other_collision
                    onOutOfBound:(SEL)outOfBound

                        targetAt:(NSObject*)target
{
  BannerObject* banner = [[BannerObject alloc]init];
  if(bound.height < 10.0f)
    bound.height = 10.0f;
  banner->_bottom = MakeRect(bound.x,bound.y-5.0f,bound.width,bound.height - 10.0f);
  banner->_body = bound;
  banner->_top = MakeRect(bound.x,bound.y+10.0f+bound.height/2.0f,bound.width,20.0f);
  banner->_on_collision_cb = collision;
  banner->_on_out_of_bound_cb = outOfBound;
  banner->_on_other_collision_cb = other_collision;
  banner->_target = target;
  banner->_identity = [_banner_list pushBack:banner];
  return banner;
}

static void RemoveObject( PhysicalWorld* world , NSObject* target )
{
  if( [target isKindOfClass:[PhysicalActor class]] )
  {
    PhysicalActor* actor = (PhysicalActor*)target;
    actor->_dead =YES;
    cpSpaceRemoveBody(world->_cp_space,actor->_cp_body);
    cpBodyFree(actor->_cp_body);
    [actor removeAllShapes];
    [world->_actor_list remove:actor->_identity];
  }
  else
  {
    assert([target isKindOfClass:[PhysicalEntity class]]);
    PhysicalEntity* entity = (PhysicalEntity*)target;
    entity->_dead = YES;
    cpBodyFree(entity->_cp_body);
    [entity removeAllShapes];
    [world->_entity_list remove:entity->_identity];
  }
}


static void PostCollision(cpSpace *arb, void *obj, void *data)
{
  PhysicalWorld* world = (__bridge PhysicalWorld*)data;
  for( int i = 0 ; i < world->_discard_list.count ; ++i ) {
    // We are possible to encounter a object that is dead here
    // since this function is called within tick and the delayed
    // deletion operation can happen here as well.
    RemoveObject(world,[world->_discard_list objectAtIndex:i]);
  }
  [world->_discard_list removeAllObjects];
}


static cpBool BeginCollision(cpArbiter *arb, struct cpSpace *space, void *data)
{
  cpShape* l,*r;
  cpArbiterGetShapes(arb, &l, &r);
  PhysicalWorld* world = (__bridge PhysicalWorld*)data;
  NSObject* left ;
  NSObject* right ;
  SEL callback_left,callback_right;
  NSObject* left_object , *right_object;
  BOOL ret_value = YES;
  cpCollisionType left_collision_type = cpShapeGetCollisionType(l);
  cpCollisionType right_collision_type= cpShapeGetCollisionType(r);
  PhysicalShape* left_shape;
  PhysicalShape* right_shape;
  
  if( left_collision_type == COLLISION_SHAPE_ACTOR ) {
    if( right_collision_type == COLLISION_SHAPE_ACTOR ) {
      PhysicalActor* a1 = (__bridge PhysicalActor*)cpShapeGetUserData(l);
      PhysicalActor* a2 = (__bridge PhysicalActor*)cpShapeGetUserData(r);
      callback_left = a1->_on_actor_collision;
      callback_right= a2->_on_actor_collision;
      left = a1->_target;
      right= a2->_target;
      left_object = a1;
      right_object= a2;
      left_shape = [a1 findCPShape:l];
      right_shape= [a2 findCPShape:r];
      assert(left_shape && right_shape);
      if(a1->_penetration != NO || a1->_penetration != NO)
        ret_value = NO;
    } else {
      PhysicalActor* a1 = (__bridge PhysicalActor*)cpShapeGetUserData(l);
      PhysicalEntity* e2 = (__bridge PhysicalEntity*)cpShapeGetUserData(r);
      callback_left = a1->_on_actor_collision;
      callback_right= e2->_on_actor_collision;
      left = a1->_target;
      right= e2->_target;
      left_object = a1;
      right_object= e2;
      if(a1->_penetration != NO || e2->_penetration != NO)
        ret_value = NO;
      left_shape = [a1 findCPShape:l];
      right_shape= [e2 findCPShape:r];
      assert(left_shape && right_shape);
    }
  } else {
    if( right_collision_type == COLLISION_SHAPE_ACTOR ) {
      PhysicalEntity* e1 = (__bridge PhysicalEntity*)cpShapeGetUserData(l);
      PhysicalActor* a2 = (__bridge PhysicalActor*)cpShapeGetUserData(r);
      callback_left = e1->_on_actor_collision;
      callback_right= a2->_on_actor_collision;
      left = e1->_target;
      right= a2->_target;
      left_object = e1;
      right_object= a2;
      if(e1->_penetration != NO || a2->_penetration != NO)
        ret_value = NO;
      left_shape = [e1 findCPShape:l];
      right_shape= [a2 findCPShape:r];
      assert(left_shape && right_shape);
    } else {
      PhysicalEntity* e1 = (__bridge PhysicalEntity*)cpShapeGetUserData(l);
      PhysicalEntity* e2 = (__bridge PhysicalEntity*)cpShapeGetUserData(r);
      callback_left = e1->_on_actor_collision;
      callback_right= e2->_on_actor_collision;
      left = e1->_target;
      right= e2->_target;
      left_object = e1;
      right_object= e2;
      if(e1->_penetration != NO || e2->_penetration != NO)
        ret_value = NO;
      left_shape = [e1 findCPShape:l];
      right_shape= [e2 findCPShape:r];
      assert(left_shape && right_shape);
    }
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  BOOL ret1 = [left performSelector:callback_left withObject:right withObject:left_shape];
  BOOL ret2 = [right performSelector:callback_right withObject:left withObject:right_shape];
#pragma clang diagnostic pop
  if( ret1 ) {
    if([world->_discard_list containsObject:left_object] == NO )
      [world->_discard_list addObject:left_object];
  }
  if( ret2 ) {
    if([world->_discard_list containsObject:right_object] == NO )
      [world->_discard_list addObject:right_object];
  }
  cpSpaceAddPostStepCallback(world->_cp_space,PostCollision,(__bridge void *)(world), (__bridge void *)(world));
  return ret_value;
}

-(void) addEffect:(id<PhysicalWorldEffect>)effect
{
  [_effect_list pushBack:effect];
}


-(id) initWithConfig:(const PhysicalWorldSettings *)settings
{
  self = [super init];
  if( self == nil ) return nil;
  _entity_list = [[LinkedList alloc] init];
  _actor_list = [[LinkedList alloc] init];
  _simple_collidable_list = [[LinkedList alloc] init];
  _simple_moveable_list = [[LinkedList alloc] init];
  _effect_list = [[LinkedList alloc]init];
  _banner_list = [[LinkedList alloc]init];
  _discard_list= [[NSMutableArray alloc] init];
  _viewport.x =0.0f;
  _viewport.y =0.0f;
  CGSize screen_size = [[CCDirector sharedDirector] viewSize];
  _viewport.width = screen_size.width;
  _viewport.height= screen_size.height;
  _gravity = settings->gravity;
  _speed = settings->move_speed;
  _absolute_position = settings->absolute_position;
  _cp_space_cur_timer = 0.0f;
  _cp_space_step_timer = 0.03f;
  _cp_space = cpSpaceNew();
  cpVect pt;
  pt.x = 0.0f;
  pt.y = -settings->gravity;
  cpSpaceSetGravity(_cp_space, pt);
  // Set collision resolving handler for chipmunk
  // Actor->Actor
  cpCollisionHandler* handler = cpSpaceAddCollisionHandler(_cp_space, COLLISION_SHAPE_ACTOR , COLLISION_SHAPE_ACTOR );
  handler->beginFunc = BeginCollision;
  handler->userData = (__bridge cpDataPointer)(self);
  // Entity->Actor
  handler = cpSpaceAddCollisionHandler(_cp_space, COLLISION_SHAPE_ACTOR , COLLISION_SHAPE_ENTITY );
  handler->beginFunc = BeginCollision;
  handler->userData = (__bridge cpDataPointer)(self);
  return self;
}


-(BOOL) isInViewportWithRelativePosition:(vec2_t) position
                               withWidth:(float)width withHeight:(float) height
{
  vec2_t pos = MakeVector(position.x-width/2.0f, position.y - height/2.0f);
  rect_t bound = MakeRect(pos.x,pos.y,width,height);
  return RectIsIntersect(&bound,&_viewport);
}

-(void) updateEntity:(float)timeDiff
{
  LinkedListIterator* it = [_entity_list begin];
  while( [it hasNext] == YES ) {
    PhysicalEntity* entity = (PhysicalEntity*)[it deref];
    if( entity->_dead == YES ) {
      [it move];
      continue;
    }
    vec2_t offset = VectorMul(&(entity->_speed),timeDiff);
    entity->_absolute_position = VectorAdd(&(entity->_absolute_position ),&offset);
    entity->_previous_position = entity->_position;
    entity->_position = [self calculateRelativePosition:&(entity->_absolute_position)];
    cpVect vect;
    vect.x=entity->_position.x;
    vect.y=entity->_position.y;
    // If omit this position, the collision will not work ??
    cpBodySetPosition(entity->_cp_body,vect);
    [entity reindexAllShapes];
    if( [self isInViewportWithRelativePosition:entity->_position
                                     withWidth:entity->_width withHeight:entity->_height] == NO ) {
      // This work around is based on :
      // http://stackoverflow.com/questions/10793116/to-prevent-warning-from-performselect-may-cause-a-leak-because-its-selector-is
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [entity->_target performSelector:entity->_on_out_of_bound];
#pragma clang diagnostic pop
      cpBodyFree(entity->_cp_body);
      [entity removeAllShapes];
      entity->_dead = YES;
      it = [_entity_list remove:it];
    } else {
      [it move];
    }
  }
  cpSpaceReindexStatic(_cp_space);
  
}


-(void) updateActor:(float)timeDiff
{
  LinkedListIterator* it =[_actor_list begin];
  while( [it hasNext] ) {
    PhysicalActor* actor = (PhysicalActor*)[it deref];
    if( actor->_dead == YES ) {
      [it move];
      continue;
    }
    actor->_previous_position = actor->_position;
    cpVect pos = cpBodyGetPosition(actor->_cp_body);
    cpVect spd = cpBodyGetVelocity(actor->_cp_body);
    actor->_speed.x = _speed.x+spd.x;
    actor->_speed.y = _speed.y+spd.y;
    actor->_position.x = pos.x;
    actor->_position.y = pos.y;
    float offset_x = actor->_position.x - actor->_previous_position.x;
    float offset_y = actor->_position.y - actor->_previous_position.y;
    actor->_absolute_position.x = _absolute_position.x + offset_x;
    actor->_absolute_position.y = _absolute_position.y + offset_y;
    if( [self isInViewportWithRelativePosition:actor->_position
                                     withWidth:actor->_width withHeight:actor->_height] == NO ) {
      // This work around is based on :
      // http://stackoverflow.com/questions/10793116/to-prevent-warning-from-performselect-may-cause-a-leak-because-its-selector-is
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [actor->_target performSelector:actor->_on_out_of_bound];
#pragma clang diagnostic pop
      cpSpaceRemoveBody(_cp_space, actor->_cp_body);
      [actor removeAllShapes];
      cpBodyFree(actor->_cp_body);
      actor->_dead = YES;
      it = [_actor_list remove:it];
    } else {
      [it move];
    }
  }
}

-(SimpleCollidableObject*) addSimpleCollidableObject:(rect_t)bound  onCollision:(SEL)collision
                           onOutOfBound:(SEL)outOfBound targetAt:(NSObject*) target
{
  SimpleCollidableObject* obj = [[SimpleCollidableObject alloc]init:bound];
  obj->_on_collision = collision;
  obj->_on_outof_bound = outOfBound;
  obj->_target = target;
  obj->_identity = [_simple_collidable_list pushBack:obj];
  obj->_dead = NO;
  return obj;
}

-(SimpleMovableCollidableObject*) addMovableCollidableObject:(SimpleMovableCollidableObjectSettings*)settings
                                  onCollision:(SEL)collision  onOutOfBound:(SEL)outOfBound targetAt:(NSObject*)target
{
  SimpleMovableCollidableObject* obj = [[SimpleMovableCollidableObject alloc]init];
  // Initialize the position of the object
  obj->_absolute_position = settings->absolute_position;
  obj->_position = [self calculateRelativePosition:&(settings->absolute_position)];
  obj->_speed = settings->speed;
  obj->_on_collision = collision;
  obj->_on_outof_bound = outOfBound;
  obj->_dead = NO;
  obj->_height = settings->height;
  obj->_width = settings->width;
  obj->_identity = [_simple_moveable_list pushBack:obj];
  obj->_target = target;
  return obj;
}


-(void) updateSimpleObject:(LinkedList*)object_list;
{
  LinkedListIterator* iter = [object_list begin];
loop:
  while( [iter hasNext] == YES ) {
    SimpleCollidableObject* obj = (SimpleCollidableObject*)[iter deref];
    vec2_t pos = MakeVector(obj.bound.x,obj.bound.y);
    if( [self isInViewportWithRelativePosition:pos withWidth:obj.bound.width withHeight:obj.bound.height] == NO ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      BOOL ret = [obj->_target performSelector:obj->_on_outof_bound];
#pragma clang diagnostic pop
      if( ret == YES ) {
        obj->_dead = YES;
        iter = [object_list remove:iter];
        continue;
      }
    } else {
      rect_t collidable_object_bound =
      MakeRect(pos.x-obj.bound.width/2.0f,pos.y-obj.bound.height/2.0f,obj.bound.width,obj.bound.height);
      // Testing the collision here
      LinkedListIterator* actor_iter = [_actor_list begin];
    loop_actor:
      while( [actor_iter hasNext] ) {
        PhysicalActor* actor = (PhysicalActor*)[actor_iter deref];
        if(actor->_dead == YES) {
          [actor_iter move];
          continue;
        }
        // ---------------------------------------------
        // Since we allow the actor have multiple shapes
        // We have to do collision detection for all the
        // shapes attached to this actor.
        // ---------------------------------------------
        
        for( int k = 0 ; k < actor->_cp_shapes.count  ; ++k ) {
          
          PhysicalShape* actor_shape = (PhysicalShape*)[actor->_cp_shapes objectAtIndex:k];
          rect_t actor_bound = [actor_shape GetAABB];
          if( RectIsIntersect(&actor_bound, &collidable_object_bound) ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            BOOL ret1= [obj->_target performSelector:obj->_on_collision
                                     withObject:actor->_target withObject:actor_shape];
            
            BOOL ret2= [actor->_target performSelector:actor->_on_actor_collision withObject:obj->_target
                                            withObject:actor_shape];
#pragma clang diagnostic pop
            if( ret1 ) {
              obj->_dead = YES;
              iter = [object_list remove:iter];
              if( ret2 ) {
                cpSpaceRemoveBody(_cp_space, actor->_cp_body);
                cpBodyFree(actor->_cp_body);
                [actor removeAllShapes];
                [_actor_list remove:actor_iter];
              }
              goto loop;
            }
            if( ret2 ) {
              cpSpaceRemoveBody(_cp_space, actor->_cp_body);
              cpBodyFree(actor->_cp_body);
              [actor removeAllShapes];
              actor_iter = [_actor_list remove:actor_iter];
              goto loop_actor;
            }
          }
        }// for
        [actor_iter move];
      }// while
    }// else
    [iter move];
  }// while
}

-(void) updateCollidableObject
{
  [self updateSimpleObject:_simple_collidable_list];
}


-(void) updateMoveableCollidableObject:(float)timeDiff
{
  LinkedListIterator* iterator = [_simple_moveable_list begin];
  while( [iterator hasNext] ) {
    SimpleMovableCollidableObject* object = (SimpleMovableCollidableObject*)[iterator deref];
    vec2_t offset = VectorMul(&(object->_speed),timeDiff);
    object->_absolute_position = VectorAdd(&(object->_absolute_position),&offset);
    object->_position = [self calculateRelativePosition:&(object->_absolute_position)];
    [iterator move];
  }
  [self updateSimpleObject:_simple_moveable_list];
}

-(void) updateEffect:(float)timeDiff
{
  LinkedListIterator* it = [_effect_list begin];
  while( [it hasNext] ) {
    id<PhysicalWorldEffect> effect = (id<PhysicalWorldEffect>)[it deref];
    [effect takeEffect:self withDelta:timeDiff];
    if([effect isAlive] == NO) {
      it = [_effect_list remove:it];
    } else {
      [it move];
    }
  }
}

-(rect_t) fixBoundBox:(rect_t)aabb {
  return MakeRect(aabb.x - aabb.width/2.0f, aabb.y-aabb.height/2.0f, aabb.width, aabb.height);
}

-(void) updateBanner:(float) timeDiff
{
  LinkedListIterator* banner_it = [_banner_list begin];
  LinkedListIterator* actor_it;
loop:
  while( [banner_it hasNext] ) {
    BannerObject* banner = (BannerObject*)[banner_it deref];
    // Testing the boundary object here
    rect_t banner_top = [self fixBoundBox:banner.top];
    rect_t banner_bot = [self fixBoundBox:banner.bottom];
    rect_t banner_body =[banner getBodyAABB];
    if( [self isInViewportWithRelativePosition:MakeVector(banner_body.x,banner_body.y)
                                     withWidth:banner_body.width
                                    withHeight:banner_body.height] == NO ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [banner->_target performSelector:banner->_on_out_of_bound_cb];
#pragma clang diagnostic pop
      banner_it = [_banner_list remove:banner_it];
      banner->_identity = nil;
      continue;
    }
loop_actor:
    actor_it = [_actor_list begin];
    while( [actor_it hasNext] ) {
      PhysicalActor* actor = (PhysicalActor*)[actor_it deref];
      if(actor->_dead == YES) {
        [actor_it move];
        continue;
      }
      for( int i = 0 ; i < actor->_cp_shapes.count ; ++i ) {
        PhysicalShape* shape = [actor->_cp_shapes objectAtIndex:i];
        rect_t actor_bound = [shape GetAABB];
        
        BOOL bret_bot = RectIsIntersect(&banner_bot, &actor_bound);
        BOOL bret_top = RectIsIntersect(&banner_top, &actor_bound);
        
        if(bret_top) {
          if(bret_bot) {
            if( actor->_previous_position.y > actor->_position.y ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
              BOOL ret1= [banner->_target performSelector:banner->_on_collision_cb
                                               withObject:actor->_target
                                               withObject:shape];
#pragma clang diagnostic pop
              if(ret1) {
                banner_it = [_banner_list remove:banner_it];
                banner->_identity = nil;
                goto loop;
              }
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
              BOOL ret1= [banner->_target performSelector:banner->_on_other_collision_cb
                                               withObject:actor->_target
                                               withObject:shape];
#pragma clang diagnostic pop
              if(ret1) {
                banner_it = [_banner_list remove:banner_it];
                banner->_identity = nil;
                goto loop;
              }
            }
          } else {
            // Top hit/Bottom not hit
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            BOOL ret1= [banner->_target performSelector:banner->_on_collision_cb
                                             withObject:actor->_target
                                             withObject:shape];
#pragma clang diagnostic pop
            if(ret1) {
              banner_it = [_banner_list remove:banner_it];
              banner->_identity = nil;
              goto loop;
            }
          }
        } else {
          if(bret_bot) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            BOOL ret1= [banner->_target performSelector:banner->_on_other_collision_cb
                                             withObject:actor->_target
                                             withObject:shape];
#pragma clang diagnostic pop
            if(ret1) {
              banner_it = [_banner_list remove:banner_it];
              banner->_identity = nil;
              goto loop;
            }
          }
        }
      }// for
      [actor_it move];
    }
    [banner_it move];
  }
}

-(void) tickCamera:(float)timeDiff
{
  vec2_t offset = VectorMul(&_speed,timeDiff);
  _absolute_position = VectorAdd(&_absolute_position,&offset);
}

-(void) doCleanUp
{
  // This is used to do the clean up for the whole pending deletion
  // It may be called because of collision or not be called !
  PostCollision(nil, nil, (__bridge void*)self);
}


-(void) tickWorld:(float)timeDiff
{
  // ----------------------------------------
  // A small fix for step the world
  // ----------------------------------------
  _cp_space_cur_timer += timeDiff;
  while( _cp_space_cur_timer > _cp_space_step_timer ) {
    _cp_space_cur_timer -= _cp_space_step_timer;
    cpSpaceStep(_cp_space, _cp_space_step_timer);
  }
  
  [self tickCamera:timeDiff];
  [self updateCollidableObject];
  [self updateMoveableCollidableObject:timeDiff];
  [self updateActor:timeDiff];
  [self updateEntity:timeDiff];
  [self updateEffect:timeDiff];
  [self updateBanner:timeDiff];
  [self doCleanUp];
}


-(void) removePhysicalActor:(PhysicalActor *)actor
{
  if( [_discard_list containsObject:actor] == NO ) {
    [_discard_list addObject:actor];
    actor->_dead = YES;
  }
}

-(void) removePhysicalEntity:(PhysicalEntity *)entity
{
  if( [_discard_list containsObject:entity] == NO ) {
    [_discard_list addObject:entity];
    entity->_dead = YES;
  }
}

-(void) removeSimpleCollidableObject:(SimpleCollidableObject *)collision_object
{
  [_simple_collidable_list remove:collision_object->_identity];
}

-(void) removeMoveableCollidableObject:(SimpleMovableCollidableObject*)collision_object
{
  [_simple_moveable_list remove:collision_object->_identity];
}

-(void) removeBanner:(BannerObject*)banner
{
  if( banner->_identity != nil ) {
    [_banner_list remove:banner->_identity];
    banner->_identity = nil;
  }
}

// ----------------------------------------------------
// Fast, one time query operation. This operation is used
// to do a one time query. It runs in all the SimpleCollidableObject
// and also the SimpleMovableCollidableObject ! Typically
// helpful for performing special effect implementation.
// ----------------------------------------------------
-(NSMutableArray*) querySimpleObjectCollision:(rect_t)bound withClass:(Class)cls
{
  NSMutableArray* ret = [[NSMutableArray alloc] init];
  LinkedListIterator* iter;
  // For simple collidable object
  iter = [_simple_collidable_list begin];
  while([iter hasNext]) {
    SimpleCollidableObject* object = (SimpleCollidableObject*)[iter deref];
    rect_t real_bound = MakeRect(object.bound.x-object.bound.width/2.0f,
                                 object.bound.y-object.bound.height/2.0f,
                                 object.bound.x,object.bound.y);
    if(RectIsIntersect(&real_bound, &bound) == YES)
      if([object->_target isKindOfClass:cls])
        [ret addObject:object->_target];
    [iter move];
  }
  // For simple movable object
  iter = [_simple_moveable_list begin];
  while([iter hasNext]) {
    SimpleMovableCollidableObject* object = (SimpleMovableCollidableObject*)[iter deref];
    rect_t real_bound = MakeRect(object.bound.x-object.bound.width/2.0f,
                                 object.bound.y-object.bound.height/2.0f,
                                 object.bound.x,object.bound.y);
    if(RectIsIntersect(&real_bound, &bound) == YES)
      if([object->_target isKindOfClass:cls])
        [ret addObject:object->_target];
    [iter move];
  }
  return ret;
}

@end


@implementation PhysicalWorldEffect_ChangeSpeed
{
  float _cur_timer;
  float _exp_timer;
  int _state;
  float _step_x , _step_y;
  vec2_t _min_speed , _max_speed;
  PhysicalActor* _actor;
}

enum
{
  INIT,
  UP,DOWN,
  DONE
};

+(id) createObject:(GameMapFileObject *)par
{
  return [[PhysicalWorldEffect_ChangeSpeed alloc]init:par];
}


-(id) init:(GameMapFileObject*)par
{
  self = [super init];
  if( self == nil ) return nil;
  
  NSMutableArray* command = [par asCommand];
  assert(command.count ==3);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _max_speed.x = [atomic asNumber];
  atomic = [command objectAtIndex:1];
  _max_speed.y = [atomic asNumber];
  atomic = [command objectAtIndex:2];
  _exp_timer = [atomic asNumber];
  _state = INIT;
  return self;
}


-(id) init:(vec2_t)speed withDuration:(float)duration withActor:(PhysicalActor*)actor
{
  self = [super init];
  if( self == nil ) return nil;
  _actor = actor;
  _max_speed = speed;
  _exp_timer = duration;
  _state = INIT;
  _actor =actor;
  return self;
}

-(void) takeEffect:(PhysicalWorld *)world withDelta:(float)dt
{
  vec2_t speed;
  vec2_t world_speed;
  switch(_state) {
    case INIT:
      _min_speed = world.current_speed;
      _max_speed.x += _min_speed.x;
      _max_speed.y += _min_speed.y;
      _step_x = (_max_speed.x - _min_speed.x)/_exp_timer;
      _step_y = (_max_speed.y - _min_speed.y)/_exp_timer;
      _cur_timer = 0.0f;
      _state = UP;
      return;
    case UP:
      _cur_timer += dt;
      if(_cur_timer > _exp_timer) {
        _step_x = (_min_speed.x - _max_speed.x)/_exp_timer;
        _step_y = (_min_speed.y - _max_speed.y)/_exp_timer;
        _cur_timer = 0.0f;
        _state =DOWN;
        return;
      }
      speed = world.current_speed;
      speed.x += _step_x *dt;
      speed.y += _step_y *dt;
      world.current_speed = speed;
      world_speed = world.current_speed;
      speed = _actor.speed;
      _actor.speed = VectorAdd(&world_speed,&speed);
      return;
    case DOWN:
      _cur_timer += dt;
      if(_cur_timer > _exp_timer) {
        world.current_speed = _min_speed;
        _state =DONE;
        return;
      }
      speed = world.current_speed;
      speed.x += _step_x *dt;
      speed.y += _step_y *dt;
      world.current_speed = speed;
      world_speed = world.current_speed;
      speed = _actor.speed;
      _actor.speed = VectorAdd(&world_speed,&speed);
      return;
    default:
      return;
  }
}

-(BOOL) isAlive
{
  return _state != DONE;
}

@end
