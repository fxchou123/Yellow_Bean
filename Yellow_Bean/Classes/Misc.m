//
//  Misc.m
//  prototype
//
//  Created by Yifan Zhou on 2/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "Misc.h"



enum {
  COORDINATE_I,
  COORDINATE_II,
  COORDINATE_III,
  COORDINATE_VI
};

CG_INLINE int GetCoordinate( const vec2_t* direction ) {
  assert(direction->x !=0 || direction->y !=0);
  if( direction->x >=0 ) {
    if(direction->y>0)
      return COORDINATE_I;
    else
      return COORDINATE_II;
  } else {
    if(direction->y <=0 )
      return COORDINATE_III;
    else
      return COORDINATE_VI;
  }
}


int RectCollisionDetect( const vec2_t* prev_position, const vec2_t* next_position,
                        float width , float height , const rect_t* target, rect_t* output  ) {
  // -------------------------------------------------------------------------------------------
  // This is a trick.It avoids the object error moving behavior once the the object is on the
  // entity surface. By doing a real intersection collision detection of a smaller object we
  // can avoid this.
  // -------------------------------------------------------------------------------------------
  rect_t inner_object = MakeRect(target->x+1.0f,target->y+1.0f,target->width-2.0f,target->height-2.0f);
  rect_t hit_box = MakeRect(next_position->x, next_position->y, width, height);
  if( RectIsIntersect(&inner_object, &hit_box) == NO )
    return SKIP;
  vec2_t direction_vec = VectorSub(next_position,prev_position);
  if( FLOAT_ZERO(direction_vec.x) && FLOAT_ZERO(direction_vec.y) )
    return SKIP;
  int type = GetCoordinate(&direction_vec);
  switch(type) {
    case COORDINATE_I:
      // ----------------------
      // Coordinate I
      // ----------------------
      if( FLOAT_ZERO(direction_vec.x) ) {
        output->x = next_position->x;
        output->y = target->y - height;
        output->width = width;
        output->height= height;
        return RECT_FACE_DOWN;
      } else {
        assert(!FLOAT_ZERO(direction_vec.y));
        vec2_t reference_pt = MakeVector(prev_position->x+width,prev_position->y+height);
        float ratio = direction_vec.y/direction_vec.x;
        float y = ratio*(target->x-reference_pt.x) + reference_pt.y;
        if( y >= target->y && y <= target->y + target->height + height ) {
          output->x = target->x-width;
          output->y = y - height;
          output->width = width;
          output->height= height;
          return RECT_FACE_LEFT;
        } else {
          float x = (target->y-reference_pt.y)/ratio + reference_pt.x;
          assert(x >= target->x && x<= target->x + width + target->width );
          output->x = x - width;
          output->y = target->y;
          output->width = width;
          output->height = height;
          return RECT_FACE_DOWN;
        }
      }
      break;
    case COORDINATE_II:
      if(FLOAT_ZERO(direction_vec.y)) {
        output->x = target->x - width;
        output->y = next_position->y;
        output->width = width;
        output->height= height;
        return RECT_FACE_LEFT;
      } else {
        vec2_t reference_pt = MakeVector(prev_position->x+width, prev_position->y);
        float ratio = direction_vec.y / direction_vec.x;
        float x = (target->y+height-reference_pt.y)/ratio + reference_pt.x;
        if(x >= target->x && x <= target->x + width + target->width) {
          output->x = x-width;
          output->y = target->y + target->height;
          output->width = width;
          output->height = height;
          return RECT_FACE_UP;
        } else {
          float y = ratio*(target->x-reference_pt.x) + reference_pt.y;
          assert( y <= target->y+height && y >= target->y-height);
          output->x = target->x-width;
          output->y = y;
          output->width = width;
          output->height = height;
          return RECT_FACE_LEFT;
        }
      }
      break;
    case COORDINATE_III:
      if(FLOAT_ZERO(direction_vec.x)) {
        output->x = prev_position->x;
        output->y = target->y + target->height;
        output->width = width;
        output->height= height;
        return RECT_FACE_UP;
      } else {
        vec2_t reference_pt = MakeVector(prev_position->x,prev_position->y);
        float ratio = direction_vec.y/direction_vec.x;
        float x = (target->y+height-reference_pt.y)/ratio + reference_pt.x;
        if( x >= target->x - width && x <= target->x + target->width ) {
          output->x = x;
          output->y = target->y + target->height;
          output->width = width;
          output->height = height;
          return RECT_FACE_UP;
        } else {
          float y = ratio*(target->x+width-reference_pt.x) + reference_pt.y;
          assert( y <= target->y + target->height && y >= target->y - height );
          output->x = target->x+width;
          output->y = y ;
          output->width = width;
          output->height = height;
          return RECT_FACE_RIGHT;
        }
      }
      break;
    case COORDINATE_VI:
      if(FLOAT_ZERO(direction_vec.y)) {
        output->x = target->x+width;
        output->y = prev_position->y;
        output->width = width;
        output->height = height;
        return RECT_FACE_RIGHT;
      } else {
        vec2_t reference_pt = MakeVector(prev_position->x,prev_position->y+height);
        float ratio = direction_vec.y/direction_vec.x;
        float x = (target->y-reference_pt.y)/ratio + reference_pt.x;
        if(x<=target->x+width &&x>=target->x-width) {
          output->x = x;
          output->y = target->y-height;
          output->width = width;
          output->height = height;
          return RECT_FACE_DOWN;
        } else {
          float y = (target->x+width - reference_pt.x)*ratio + reference_pt.y;
          assert( y <= target->y + height + target->height && y >= target->y );
          output->x = target->x + width;
          output->y = y-height;
          output->width = width;
          output->height = height;
          return RECT_FACE_RIGHT;
        }
      }
      break;
    default:
      assert(0);
      break;
  }
}




@interface LinkedListNode : NSObject
@property LinkedListNode* prev;
@property LinkedListNode* next;
@property NSObject* data;
@end


@implementation LinkedListNode
@synthesize prev;
@synthesize next;
@synthesize data;
@end

@implementation LinkedListIterator
{
@public
  LinkedListNode* _cur;
  LinkedListNode* _end;
}

-(id) init:(LinkedListNode*) next endOf:(LinkedListNode*)end
{
  _cur = next;
  _end = end;
  return self;
}

-(NSObject*) deref
{
  assert( _cur != _end );
  NSObject* ret = _cur.data;
  return ret;
}

-(void) move
{
  assert(_cur != nil);
  _cur = _cur.next;
}

-(BOOL) hasNext
{
  if( _cur == _end ) return NO;
  assert(_cur.next !=NULL);
  return YES;
}

@end


@implementation LinkedList
{
  int _size;
  LinkedListNode* _end;
}
@synthesize size = _size;

-(id)init
{
  _size = 0;
  _end = [LinkedListNode alloc];
  _end.next = _end;
  _end.prev = _end;
  _end.data = nil;
  return self;
}

-(LinkedListIterator*) insert:(NSObject *)object where:(LinkedListIterator *)pos
{
  assert(pos->_cur != nil);
  return [[LinkedListIterator alloc] init:[self insertNode:object where:pos->_cur] endOf:_end];
}

-(LinkedListNode*) insertNode:(NSObject*)object where:(LinkedListNode*)pos
{
  LinkedListNode* node = [LinkedListNode alloc];
  node.data = object;
  node.next = pos;
  node.prev = pos.prev;
  pos.prev.next = node;
  pos.prev = node;
  ++_size;
  return node;
}

-(LinkedListNode*) removeNode:(LinkedListNode*)pos
{
  LinkedListNode* ret = pos.next;
  pos.prev.next = pos.next;
  pos.next.prev = pos.prev;
  --_size;
  return ret;
}

-(BOOL) isInList:(LinkedListIterator*)pos {
  LinkedListNode* node = pos->_cur;
  LinkedListNode* head = _end.next;
  while( head != _end ) {
    if( head == node )
      return YES;
    head = head.next;
  }
  return NO;
}

-(LinkedListIterator*) remove:(LinkedListIterator *)pos
{
  if( pos->_cur == _end ) return nil;
  assert(pos->_cur != nil);
  assert([self isInList:pos] == YES);
  return [[LinkedListIterator alloc] init:[self removeNode:pos->_cur] endOf:_end];
}


-(LinkedListIterator*) pushBack:(NSObject *)object
{
  return [[LinkedListIterator alloc] init:[self insertNode:object where:_end] endOf:_end];
}

-(LinkedListIterator*) pushFront:(NSObject*)object
{
  return [[LinkedListIterator alloc] init:[self insertNode:object where:_end.next] endOf:_end];
}

-(NSObject*) popBack
{
  if( _end == _end.prev ) return nil;
  LinkedListNode* last = _end.prev;
  last.prev.next = _end;
  _end.prev = last.prev;
  --_size;
  return last.data;
}

-(NSObject*) popFront
{
  if(_end == _end.next) return nil;
  LinkedListNode* first = _end.next;
  first.prev.next = first.next;
  _end.prev = first.prev;
  --_size;
  return first.data;
}

-(NSObject*) last
{
  if(_end == _end.prev) return nil;
  return _end.prev.data;
}

-(NSObject*) first
{
  if(_end == _end.next) return nil;
  return _end.next.data;
}

-(BOOL) isEmpty
{
  return _size ==0 ? YES:NO;
}

-(LinkedListIterator*) begin
{
  return [[LinkedListIterator alloc] init:_end.next endOf:_end];
}

-(void) clear
{
  _end.next = _end;
  _end.prev = _end;
  _size = 0;
}

CCColor* StringToColor( const NSString* name ) {
  if( [name caseInsensitiveCompare:@"black"] == NSOrderedSame ) {
    return [CCColor blackColor];
  } else if( [name caseInsensitiveCompare:@"blue"] == NSOrderedSame ) {
    return [CCColor blueColor];
  } else if( [name caseInsensitiveCompare:@"brown"] == NSOrderedSame ) {
    return [CCColor brownColor];
  } else if( [name caseInsensitiveCompare:@"red"]  == NSOrderedSame ) {
    return [CCColor redColor];
  } else if( [name caseInsensitiveCompare:@"yellow"] == NSOrderedSame ) {
    return [CCColor yellowColor];
  } else if( [name caseInsensitiveCompare:@"green"] == NSOrderedSame ) {
    return [CCColor greenColor];
  } else if( [name caseInsensitiveCompare:@"gray"] == NSOrderedSame ) {
    return [CCColor grayColor];
  } else if( [name caseInsensitiveCompare:@"white"] == NSOrderedSame ) {
    return [CCColor whiteColor];
  } else if( [name caseInsensitiveCompare:@"purple"] == NSOrderedSame ) {
    return [CCColor purpleColor];
  } else if( [name caseInsensitiveCompare:@"orange"] == NSOrderedSame) {
    return [CCColor orangeColor];
  } else {
    // Unknown color
    return [CCColor whiteColor];
  }
}

id CreateObjectByReflection( NSString* object , NSString* factory , GameMapFileObject* par , GameScene* scene )
{
  id clazz = NSClassFromString(object);
  if( clazz == nil ) return nil;
  SEL methodInstance = NSSelectorFromString(factory);
  if( methodInstance == nil ) return nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  return [clazz performSelector:methodInstance withObject:par withObject:scene ];
#pragma clang diagnostic pop
}

@end
