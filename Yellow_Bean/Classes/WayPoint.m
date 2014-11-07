//
//  WayPoint.m
//  Mario
//
//  Created by Yifan Zhou on 3/18/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "WayPoint.h"
#import "GameMapFile.h"
#import "PhysicalWorld.h"

@protocol WayPointInstruction <NSObject>
-(BOOL) update:(float)delta;
-(vec2_t) getPosition;
@end

// ------------------------------------------------------------
// Delay
// ------------------------------------------------------------
@interface WayPoint_Delay : NSObject<WayPointInstruction>
+(id) createObject:(GameMapFileObject*)par withPoint:(NSValue*)point;
-(BOOL) update:(float)delta;
-(vec2_t) getPosition;
@end

// ------------------------------------------------------------
// MoveTo
// ------------------------------------------------------------
@interface WayPoint_MoveTo : NSObject<WayPointInstruction>
+(id) createObject:(GameMapFileObject*)par withPoint:(NSValue*)point;
-(BOOL) update:(float)delta;
-(vec2_t) getPosition;
@end

// ------------------------------------------------------------
// Linear Move
// ------------------------------------------------------------
@interface WayPoint_Move : NSObject<WayPointInstruction>
+(id) createObject:(GameMapFileObject*)par withPoint:(NSValue*)point;
-(id) initWithManualConfig:(vec2_t)velocity withPoint:(vec2_t)pt;
-(BOOL) update:(float)delta;
-(vec2_t) getPosition;
-(void) setVelocity:(vec2_t)vec;
@end

@interface WayPoint_MoveWithPhysicalWorld : NSObject<WayPointInstruction>
-(id) initWithManualConfig:(GameMapFileObject*)par
         withPhysicalWorld:(PhysicalWorld*)physical_world
                 withPoint:(vec2_t)pt;
-(BOOL) update:(float)delta;
-(vec2_t) getPosition;
-(void) setVelocity:(vec2_t)vec;
@end

// ----------------------------------------------------
// Implementation of each instruction
// ----------------------------------------------------
@implementation WayPoint_Delay
{
  vec2_t _cur_point;
  float _cur_timer;
  float _time_duration;
}

+(id) createObject:(GameMapFileObject *)par withPoint:(NSValue*)point
{
  vec2_t pt;
  [point getValue:&pt];
  return [[WayPoint_Delay alloc] init:par withPoint:pt];
}

-(id) init:(GameMapFileObject*)par withPoint:(vec2_t)pt
{
  self = [super init];
  if( self == nil ) return nil;
  _cur_point = pt;
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _time_duration = [atomic asNumber];
  _cur_timer = 0.0f;
  return self;
}

-(BOOL) update:(float)delta
{
  if(_time_duration <0.0f) return YES;
  _cur_timer += delta;
  if( _cur_timer > _time_duration ) return NO;
  return YES;
}

-(vec2_t) getPosition
{
  return _cur_point;
}

@end


@implementation WayPoint_MoveTo
{
  vec2_t _cur_point;
  vec2_t _speed;
  vec2_t _target_point;
  float _duration;
  float _cur_time;
}

+(id) createObject:(GameMapFileObject*)par withPoint:(NSValue*)point
{
  vec2_t pt;
  [point getValue:&pt];
  return [[WayPoint_MoveTo alloc] init:par withPoint:pt];
}

-(id) init:(GameMapFileObject*)par withPoint:(vec2_t)pt
{
  self = [super init];
  if( self == nil ) return nil;
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _target_point.x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  _target_point.y = [atomic asNumber];
  
  atomic = [command objectAtIndex:2];
  _duration = [atomic asNumber];
  _cur_time = 0.0f;
  _speed = VectorSub(&_target_point,&pt);
  _speed = VectorMul(&_speed,1.0f/_duration);
  _cur_point = pt;
  return self;
}


-(BOOL) update:(float)delta
{
  vec2_t offset = VectorMul(&_speed,delta);
  _cur_point = VectorAdd(&_cur_point,&offset);
  _cur_time += delta;
  if( _cur_time >= _duration ) return NO;
  return YES;
}

-(vec2_t) getPosition
{
  return _cur_point;
}

@end


@implementation WayPoint_Move
{
  vec2_t _velocity;
  vec2_t _cur_point;
}

+(id) createObject:(GameMapFileObject*)par withPoint:(NSValue*)point
{
  vec2_t pt;
  [point getValue:&pt];
  return [[WayPoint_Move alloc] init:par withPoint:pt];
}

-(id) initWithManualConfig:(vec2_t)velocity withPoint:(vec2_t)pt
{
  self = [super init];
  if(self == nil) return nil;
  _velocity = velocity;
  _cur_point = pt;
  return self;
}


-(id) init:(GameMapFileObject*)par withPoint:(vec2_t)pt
{
  self = [super init];
  if( self == nil ) return nil;
  NSMutableArray* command = [par asCommand];
  assert(command.count == 2);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _velocity.x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  _velocity.y = [atomic asNumber];
  _cur_point = pt;
  return self;
}

-(void) setVelocity:(vec2_t)vec
{
  _velocity = vec;
}

-(vec2_t) getPosition
{
  return _cur_point;
}

-(BOOL) update:(float)delta
{
  vec2_t offset = VectorMul(&_velocity, delta);
  _cur_point = VectorAdd(&_cur_point,&offset);
  return YES;
}

@end // WayPoint_LinearMove


@implementation WayPoint_MoveWithPhysicalWorld
{
  PhysicalWorld* _physical_world;
  vec2_t _relative_velocity;
  vec2_t _cur_point;
}

-(id) initWithManualConfig:(GameMapFileObject*)par
         withPhysicalWorld:(PhysicalWorld*)physical_world
                 withPoint:(vec2_t)pt
{
  self = [super init];
  if( self == nil ) return nil;
  
  _physical_world = physical_world;
  _cur_point = pt;
  // Grab the relative speed here
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  float x = [atomic asNumber];
  
  atomic = [command objectAtIndex:1];
  float y = [atomic asNumber];
  
  _relative_velocity = MakeVector(x, y);
  
  return self;
}


-(BOOL) update:(float)delta
{
  vec2_t vel;
  vel.x = -_physical_world.current_speed.x + _relative_velocity.x;
  vel.y = -_physical_world.current_speed.y + _relative_velocity.y;
  vec2_t offset = VectorMul(&vel,delta);
  _cur_point = VectorAdd(&_cur_point,&offset);
  return YES;
}

-(vec2_t) getPosition
{
  return _cur_point;
}

-(void) setVelocity:(vec2_t)vec
{
  _relative_velocity.x = vec.x;
  _relative_velocity.y = vec.y;
}

@end



@implementation WayPoint
{
  NSMutableArray* _instructions;
  int _cur_index;
  // Grab the current instructions
  id<WayPointInstruction> _pc;
  PhysicalWorld* _physical_world;
}


-(vec2_t) position
{
  if(_pc == nil)
    return MakeVector(0.0f,0.0f);
  return [_pc getPosition];
}

-(id) createInstance:(NSString*)instruction
          withObject:(GameMapFileObject*)par
           withPoint:(NSValue*)pt
   withPhysicalWorld:(PhysicalWorld*)world
{
  // ------------------------------------------------------------------------------
  // 1. An ugly hack here for MoveWithPhysicalWorld since we need to pass another
  // parameter for MoveWithPhysicalWorld
  // ------------------------------------------------------------------------------
  if([instruction isEqual:@"MoveWithPhysicalWorld"]) {
    vec2_t point;
    [pt getValue:&point];
    return [[WayPoint_MoveWithPhysicalWorld alloc] initWithManualConfig:par
                                                      withPhysicalWorld:world
                                                              withPoint:point];
  }
  // Grab the instruction class name from instruction name
  NSString* instruct_class_name = [@"WayPoint_" stringByAppendingString:instruction];
  id clazz = NSClassFromString(instruct_class_name);
  if( clazz == nil ) return nil;
  SEL methodInstance = NSSelectorFromString(@"createObject:withPoint:");
  if( methodInstance == nil ) return nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  return [clazz performSelector:methodInstance withObject:par withObject:pt];
#pragma clang diagnostic pop
}

-(BOOL) moveCounter:(vec2_t)point
{
  assert(_instructions != nil);
  if( _cur_index == _instructions.count ) {
    _pc = nil;
    return NO;
  }
  GameMapFileObject* instruct = [_instructions objectAtIndex:_cur_index];
  // Grab the instace of that instruction
  NSValue* pt = [[NSValue alloc] initWithBytes:&point objCType:@encode(vec2_t)];
  _pc = [self createInstance:instruct.name withObject:instruct withPoint:pt withPhysicalWorld:_physical_world];
  assert(_pc != nil);
  ++_cur_index;
  return YES;
}


-(void) setAsLinearMovement:(vec2_t)velocity
{
  if([_pc isKindOfClass:[WayPoint_Move class]] == NO) {
    [_instructions removeAllObjects];
    WayPoint_Move* move = [[WayPoint_Move alloc] initWithManualConfig:velocity withPoint:[_pc getPosition]];
    _pc = move;
  } else {
    WayPoint_Move* move = (WayPoint_Move*)_pc;
    [move setVelocity:velocity];
  }
}

-(id) init:(GameMapFileObject*)par withPoint:(vec2_t)pt withPhysicalWorld:(PhysicalWorld *)world
{
  self = [super init];
  if( self == nil ) return nil;
  _instructions = [par asCollection];
  _cur_index = 0;
  _physical_world = world;
  [self moveCounter:pt];
  return self;
}

-(BOOL) update:(float)delta
{
  if( _pc == nil ) return NO;
  // Updating the current pc
  if( [_pc update:delta] == NO ) {
    // Move the counter
    [self moveCounter:[_pc getPosition]];
    return _pc == nil ? NO : YES ;
  }
  return YES;
}

-(BOOL) dead
{
  return _pc == nil;
}


@end
