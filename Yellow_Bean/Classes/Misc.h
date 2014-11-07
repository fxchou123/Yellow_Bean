//
//  Misc.h
//  prototype
//
//  Created by Yifan Zhou on 2/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCColor.h"


@class GameMapFileObject;
@class GameScene;

typedef struct {
  float x;
  float y;
} vec2_t;

CG_INLINE vec2_t MakeVector( float x , float y ) {
  vec2_t ret;
  ret.x = x;
  ret.y = y;
  return ret;
}


// ---------------------------------------------------
// It is always not very trival to see how the vec2_t
// is composed since the vector is orgnized by direction
// and the scalar value (length component). For simplicity
// we will define the coordinate system based on OpenGL ES
// since it is the base for the Cocos2D.
//             |
//             |
//             |
//  [270 - 360]| [0 - 90]
//  -------------------------
//  [180 - 270]| [90 - 180]
//             |
//             |
//             |
//             |
// ---------------------------------------------------

// ---------------------------------------------------
// We all know the float point in software has precision
// problem. Therefore, if we use M_PI_2 == PI/2.0f to
// represent the RIGHT direction, we may not really reach
// there , since the ret.y cannot be entirely zero. This is
// a problem if we want to implement dash operation based
// on this model. Since the ret.y cannot be zero, the character
// may fly up a little bit or dash into the ground a little bit
// which may caused our physical engine not work properly.
// So I quantitize them.
// ---------------------------------------------------

CG_INLINE vec2_t MakeVectorByDirectionAndLength( float direction , float length ) {
  vec2_t ret;
  ret.x = sinf(direction)*length;
  ret.y = cosf(direction)*length;
  return ret;
}

enum {
  VECTOR_DIRECTION_LEFT,
  VECTOR_DIRECTION_RIGHT,
  VECTOR_DIRECTION_UP,
  VECTOR_DIRECTION_DOWN
};

CG_INLINE vec2_t MakeVectorPointToDirection( int dir , float length ) {
  vec2_t ret;
  switch(dir) {
    case VECTOR_DIRECTION_LEFT:
      ret.y =0.0f;
      ret.x = -length;
      return ret;
    case VECTOR_DIRECTION_RIGHT:
      ret.y =0.0f;
      ret.x = length;
      return ret;
    case VECTOR_DIRECTION_UP:
      ret.x =0.0f;
      ret.y = length;
      return ret;
    case VECTOR_DIRECTION_DOWN:
      ret.x = 0.0f;
      ret.y = -length;
      return ret;
    default:
      assert(0);
      return ret;
  }
}

CG_INLINE float Clamp( float val ) {
  return val;
}

CG_INLINE vec2_t VectorAdd( const vec2_t* l , const vec2_t* r ) {
  vec2_t ret;
  ret.x = Clamp(l->x + r->x);
  ret.y = Clamp(l->y + r->y);
  return ret;
}

CG_INLINE vec2_t VectorSub( const vec2_t* l , const vec2_t* r ) {
  vec2_t ret;
  ret.x = Clamp(l->x - r->x);
  ret.y = Clamp(l->y - r->y);
  return ret;
}

CG_INLINE vec2_t VectorMul( const vec2_t* l, float scaler ) {
  vec2_t ret;
  ret.x = Clamp(l->x*scaler);
  ret.y = Clamp(l->y*scaler);
  return ret;
}

CG_INLINE vec2_t VectorNormalize( const vec2_t* l )
{
  float ratio = 1.0f/sqrt((l->x*l->x+l->y*l->y));
  return MakeVector(ratio*l->x,ratio*l->y);
}

CG_INLINE float VectorGetRotation( const vec2_t* l )
{
  float dotProduct = l->y;
  return (acosf( dotProduct/sqrt(l->x*l->x +l->y*l->y) ) / M_PI)*180;
}

CG_INLINE float VectorGetRotationByAxis( const vec2_t* l , const vec2_t* axis ) {
  assert(fabs(axis->x) == 1 || fabs(axis->y) ==1);
  assert(!(fabs(axis->x) ==1 && fabs(axis->y) ==1));
  float dotProduct = l->x*axis->x + l->y * axis->y;
  return (acosf( dotProduct/(sqrt(l->x*l->x+l->y*l->y)))/M_PI)*180;
}

CG_INLINE float VectorDotProduct( const vec2_t* l , const vec2_t* r ) {
  return (l->x)*(r->x) + (l->y)*(r->y);
}

CG_INLINE BOOL VectorSameDirection( const vec2_t* l , const vec2_t* r ) {
  return VectorDotProduct(l,r) > 0.01f ? YES : NO ;
}

CCColor* StringToColor( const NSString* name );


#define FLOAT_ZERO(f) \
  ((f) <= 0.0001f && (f)>= -0.0001f)

#define FLOAT_ZERO_CP(f,threshold) \
  ((f) <= (threshold) && (f)>= -(threshold))

// ------------------------------------------------------------
// This rect represents a AABB in the game world. The point(x,y)
// represents the left lower point coordinates , the width and
// heigh represent the box width and height
// ------------------------------------------------------------

typedef struct {
  float x,y;
  float width,height;
} rect_t;

CG_INLINE rect_t MakeRect( float x , float y , float w , float h ) {
  rect_t ret;
  ret.x = x;
  ret.y = y;
  ret.width = w;
  ret.height = h;
  return ret;
}

enum {
  RECT_COLLISION_UP,
  RECT_COLLISION_DOWN,
  RECT_COLLISION_OTHER, // Since we only need to figure out the upper and lower when CBD is on, just leave it as OTHER
  RECT_NO_COLLISION
};


CG_INLINE BOOL RectIsIntersect( const rect_t* l , const rect_t* r ) {
  CGRect rect1 = CGRectMake(l->x, l->y, l->width, l->height);
  CGRect rect2 = CGRectMake(r->x, r->y, r->width, r->height);
  return CGRectIntersectsRect(rect1, rect2);
}



// --------------------------------------------------------------------------------------------
// Rectangle collision detection. This collision detection will give you much more information
// than simple telling you that a collision just happened. It will cover which face is collided
// and the adjustable position of the rectangle
// --------------------------------------------------------------------------------------------
enum {
  RECT_FACE_UP,
  RECT_FACE_DOWN,
  RECT_FACE_LEFT,
  RECT_FACE_RIGHT,
  SKIP
};

int RectCollisionDetect( const vec2_t* prev_position, const vec2_t* next_position,
                         float object_width , float object_height ,
                         const rect_t* target, rect_t* output );


id CreateObjectByReflection( NSString* object , NSString* factory , GameMapFileObject* par , GameScene* scene );



// I didn't find any linked list in the Objective-C library
// so I have to make one. It is nearly a one-by-one copy of
// std::list in C++.

@interface LinkedListIterator : NSObject
-(NSObject*) deref;
-(void) move;
-(BOOL) hasNext;
@end

@interface LinkedList : NSObject
@property (readonly) int size;

-(id) init;
-(BOOL) isEmpty;
-(LinkedListIterator*) insert:(NSObject*) object where:(LinkedListIterator*)pos;
-(LinkedListIterator*) remove:(LinkedListIterator*)pos;
-(LinkedListIterator*) begin;
-(LinkedListIterator*) pushBack:(NSObject*) object;
-(NSObject*) popBack;
-(LinkedListIterator*) pushFront:(NSObject*) object;
-(NSObject*) popFront;
-(NSObject*) first;
-(NSObject*) last;
-(void) clear;

@end