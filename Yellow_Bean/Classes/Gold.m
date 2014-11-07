//
//  Score.m
//  Mario
//
//  Created by Yifan Zhou on 3/10/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "Gold.h"
#import "GameMapFile.h"
#import "GameScene.h"
#import "PhysicalWorld.h"
#import "CachedSprite.h"
#import "CCParticleSystem.h"
#import "Player.h"
#import "GameStatistics.h"
#import "SoundManager.h"
#import "RestartParticle.h"

// -------------------------------------------------------------------
// This version of score should support lot of stuff
// 1. Backward Compatible:
// In the old version, the score is looks like this:
// [StartX:650]
// [StartY:355]
// Score(0.0,0.0,20.0,20.0,1,"coin.png","score_effect.plist");
// We still support such calling convention.
// 2. New Version:
// The new version will allow the score to have 1) update feature
// 2) have way point to move the score
// [StartX:650]
// [StartY:355]
// Score = {
//    ScoreInfo(0.0,0.0,20.0,20.0);
//    ScoreType(1);
//    ResourceInfo("Gold.png","","","");
//    HitEffect("");
//    LevelUpEffect("");
// };
// -------------------------------------------------------------------

@implementation Gold_OldCompatible
{
  int _value;
  CachedSprite* _sprite;
  CCParticleSystem* _effect;
  int _state;
  NSString* _sfx_name;
}

-(void) setSpeed:(vec2_t)speed
{
  self.movable_object.speed = speed;
}

-(vec2_t) scene_position
{
  return self.movable_object.position;
}

enum {
  IDLE,
  HIT,
  DEAD
};

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene withSoundName:(NSString*)sfx
{
  self = [super init:par withScene:scene];
  if( self == nil ) return nil;
  NSMutableArray* command = [par asCommand];
  GameMapFileObjectAtomic*atomic = [command objectAtIndex:4];
  _value = [atomic asNumber];
  _sfx_name = sfx;
  // Texture path/Effect path
  atomic = [command objectAtIndex:5];
  NSString* texture_path = [atomic asString];
  
  atomic = [command objectAtIndex:6];
  NSString* effect_path = [atomic asString];
  
  _sprite = [[CachedSprite alloc] initWithImageNamed:texture_path];
  _sprite.scaleX = (self.movable_object.width)/_sprite.textureRect.size.width;
  _sprite.scaleY = (self.movable_object.height)/_sprite.textureRect.size.height;
  _sprite.position = ccp(self.movable_object.position.x,self.movable_object.position.y);
  
  _effect = [[CCParticleSystem alloc] initWithFile:effect_path];
  _state = IDLE;
  
  [self addChild:_sprite];
  
  return self;
}

-(void) forceToDie
{
  [self.game_scene.game_statistics addScore:_value];
  _state = DEAD;
  [self.game_scene removeChild:self];
  [self.game_scene.sound_manager playEffect:_sfx_name];
}

-(void) levelUp
{
  
}

-(void) onChange:(int)value
{
  [self.game_scene.game_statistics addGold:value];
}

-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if(_state != IDLE) return YES;
  // ----------------------------------------
  // Collision happend, refresh the
  // current score value on the screen
  // ----------------------------------------
  if( ([object isKindOfClass:[Player class]] == YES)
     &&([self.game_scene.player isPlayerCollided:shape] == YES) ) {
    [self onChange:_value];
    _state = HIT;
    [self removeChild:_sprite];
    [self addChild:_effect];
    [self.game_scene.sound_manager playEffect:_sfx_name];
    _effect.position = ccp(self.game_scene.player.scene_position.x,
                           self.game_scene.player.scene_position.y);
    return YES;
  }
  return NO;
}

-(BOOL) onOutOfBound
{
  if( _state != DEAD ) {
    [self.game_scene removeChild:self];
  }
  return YES;
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case IDLE:
      _sprite.position = ccp(self.movable_object.position.x,self.movable_object.position.y);
      return;
    case HIT:
      _effect.position = ccp(self.game_scene.player.scene_position.x,
                             self.game_scene.player.scene_position.y);
      if(_effect.active == NO && _effect.particleCount ==0) {
        [self.game_scene removeChild:self];
        _state = DEAD;
      }
      return;
    default:
      return;
  }
}

@end


// ---------------------------------------------
// New Version Of Score Implementation
// This New Version doesn't use BaseItem.
// ---------------------------------------------

@interface Gold_NewVersion : BaseItem<GoldProtocol>
-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene;
-(void) forceToDie;
-(void) levelUp;
-(void) setSpeed:(vec2_t)vel;
// This is used for magnitude
@property (readonly) vec2_t scene_position;
@end

@implementation Gold_NewVersion
{
  CachedSprite* _brownze_coin;
  CachedSprite* _silver_coin;
  CachedSprite* _gold_coin;
  CachedSprite* _star_coin;
  CachedSprite* _cur_sprite;
  // Hit Effect / Update Effect
  CCParticleSystem* _hit_effect;
  CCParticleSystem* _update_effect;
  int _coin_type;
  int _value;
  int _state;
}


enum {
  STATE_IDLE,
  STATE_EFFECT,
  STATE_UPDATE,
  STATE_DEAD
};
-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}

-(GameMapFileObject*) findGameMapObject:(GameMapFileObject*)par withKey:(NSString*)key
{
  NSMutableArray* collection = [par asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* gm_object = [collection objectAtIndex:i];
    if( [gm_object.name isEqual:key] )
      return gm_object;
  }
  return nil;
}

-(NSString*) queryKeyValueAsString:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count == 1);
  return [[command objectAtIndex:0] asString];
}

-(int) queryKeyValueAsInt:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count == 1);
  return (int)[[command objectAtIndex:0] asNumber];
}


-(void) initResourceInfo:(GameMapFileObject*)par
                withGold:(NSString**)gold
              withSilver:(NSString**)silver
               withBrownze:(NSString**)brownze
                withStar:(NSString**)star
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==4);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  *brownze = [atomic asString];
  
  atomic = [command objectAtIndex:1];
  *silver= [atomic asString];
  
  atomic = [command objectAtIndex:2];
  *gold= [atomic asString];
  
  atomic = [command objectAtIndex:3];
  *star =[atomic asString];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  GameMapFileObject* gm_object = [self findGameMapObject:par withKey:@"GoldInfo"];
  assert(gm_object);
  float StartX = [self getPropertyNumber:par withKey:@"StartX"];
  float StartY = [self getPropertyNumber:par withKey:@"StartY"];
  self = [super init:gm_object withScene:scene withStartX:StartX withStartY:StartY];
  if(self == nil) return nil;
  // 1. ScoreType
  gm_object = [self findGameMapObject:par withKey:@"GoldType"];
  assert(gm_object);
  _coin_type = [self queryKeyValueAsInt:gm_object];
  
  // 2. ResourceInfo
  gm_object = [self findGameMapObject:par withKey:@"ResourceInfo"];
  assert(gm_object);
  NSString* brownze , *silver , *gold , *star;
  [self initResourceInfo:gm_object
                withGold:&gold
              withSilver:&silver
               withBrownze:&brownze
                withStar:&star];
  
  _brownze_coin = [[CachedSprite alloc] initWithImageNamed:brownze];
  _brownze_coin.scaleX = self.movable_object.bound.width/_brownze_coin.textureRect.size.width;
  _brownze_coin.scaleY = self.movable_object.bound.height/_brownze_coin.textureRect.size.height;
  
  _silver_coin = [[CachedSprite alloc] initWithImageNamed:silver];
  _silver_coin.scaleX = self.movable_object.bound.width/_silver_coin.textureRect.size.width;
  _silver_coin.scaleY = self.movable_object.bound.height/_silver_coin.textureRect.size.height;
  
  _gold_coin = [[CachedSprite alloc] initWithImageNamed:gold];
  _gold_coin.scaleX = self.movable_object.bound.width/_gold_coin.textureRect.size.width;
  _gold_coin.scaleY = self.movable_object.bound.height/_gold_coin.textureRect.size.height;
  
  _star_coin = [[CachedSprite alloc] initWithImageNamed:star];
  _star_coin.scaleX = self.movable_object.bound.width/_star_coin.textureRect.size.width;
  _star_coin.scaleY = self.movable_object.bound.height/_star_coin.textureRect.size.height;
  
  switch(_coin_type) {
    case GOLD_BROWNZE:
      _cur_sprite = _brownze_coin;
      _value = 1;
      break;
    case GOLD_SILVER:
      _cur_sprite = _silver_coin;
      _value = 2;
      break;
    case GOLD_GOLD:
      _cur_sprite = _gold_coin;
      _value = 3;
      break;
    case GOLD_STAR:
      _cur_sprite = _star_coin;
      _value = 4;
      break;
    default:
      assert(0);
      break;
  }
  // 3. HitEffect
  gm_object = [self findGameMapObject:par withKey:@"HitEffect"];
  assert(gm_object);
  NSString* hit_effect_path = [self queryKeyValueAsString:gm_object];
  _hit_effect = [[CCParticleSystem alloc] initWithFile:hit_effect_path];
  // 4. Update Effect
  gm_object = [self findGameMapObject:par withKey:@"LevelUpEffect"];
  assert(gm_object);
  NSString* level_up_effect_path = [self queryKeyValueAsString:gm_object];
  _update_effect = [[CCParticleSystem alloc] initWithFile:level_up_effect_path];
  
  _cur_sprite.position = ccp(self.movable_object.bound.x,
                             self.movable_object.bound.y);
  [self addChild:_cur_sprite];
  return self;
}


-(BOOL) onCollision:(NSObject*)object withShape:(PhysicalShape*)shape
{
  if( _state == STATE_DEAD || _state == STATE_EFFECT )
    return YES;
  if( [object isKindOfClass:[Player class]] && [self.game_scene.player isPlayerCollided:shape] ) {
    _state = STATE_EFFECT;
    [self removeChild:_cur_sprite];
    [self addChild:_hit_effect];
    [self.game_scene.game_statistics addGold:_value];
    _hit_effect.position = ccp(self.game_scene.player.scene_position.x,
                               self.game_scene.player.scene_position.y);
    [self.game_scene.sound_manager playEffect:@"Gold"];
    return YES;
  }
  return NO;
}

-(BOOL) onOutOfBound
{
  if(_state != STATE_DEAD) {
    [self.game_scene removeChild:self];
  }
  return YES;
}

-(void) update:(CCTime)delta
{
  switch(_state) {
    case STATE_IDLE:
      _cur_sprite.position = ccp(self.movable_object.bound.x,
                                 self.movable_object.bound.y);
      break;
    case STATE_EFFECT:
      _hit_effect.position = ccp(self.game_scene.player.scene_position.x,
                                 self.game_scene.player.scene_position.y);
      if(_hit_effect.active == NO && _hit_effect.particleCount == 0) {
        _state = STATE_DEAD;
        [self.game_scene removeChild:self];
        return;
      }
      break;
    case STATE_UPDATE:
      _cur_sprite.position = ccp(self.movable_object.bound.x,
                                 self.movable_object.bound.y);
      _update_effect.position= _cur_sprite.position;
      break;
    default:
      return;
  }
}

-(void) forceToDie
{
  switch(_state) {
    case STATE_EFFECT:
      [_update_effect disable];
      [self removeChild:_update_effect];
    case STATE_IDLE:
      [self removeChild:_cur_sprite];
      [self.game_scene.game_statistics addScore:_value];
      [self addChild:_hit_effect];
      _hit_effect.position = _cur_sprite.position;
      _state = STATE_EFFECT;
      return;
    default:
      return;
  }
}


// TODO :: ----------------------

-(CachedSprite*) updateSprite:(int)type
{
  switch(type) {
    case GOLD_BROWNZE:
      return _silver_coin;
    case GOLD_SILVER:
      return _gold_coin;
    case GOLD_GOLD:
      return _star_coin;
    default:
      return nil;
  }
}

-(void) levelUp
{
  CachedSprite* next_sprite;
  switch(_state) {
    case STATE_IDLE:
    case STATE_UPDATE:
      // --------------------------
      // State idle:
      // --------------------------
      next_sprite = _star_coin;
      if( next_sprite != _cur_sprite ) {
        _value = 4;
        [self removeChild:_cur_sprite];
        [_update_effect enable];
        [self addChild:_update_effect];
        next_sprite.position = _cur_sprite.position;
        _cur_sprite = next_sprite;
        [self addChild:_cur_sprite];
        _coin_type = GOLD_STAR;
      }
      _state = STATE_UPDATE;
      return;
    default:
      return;
  }
}

-(void) setSpeed:(vec2_t)speed
{
  self.movable_object.speed = speed;
}

-(vec2_t) scene_position
{
  return self.movable_object.position;
}

@end


@implementation Gold
{
  CCNode* _gold_imp;
  GameScene* _game_scene;
}

+(id)createObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return [[Gold alloc] init:par withScene:scene];
}

-(id) init:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  self = [super init];
  if(self == nil) return nil;
  if(par.type == GM_OBJECT_COLLECTION) {
    _gold_imp = [[Gold_NewVersion alloc] init:par withScene:scene];
  } else {
    _gold_imp = [[Gold_OldCompatible alloc] init:par withScene:scene withSoundName:@"Gold"];
  }
  [scene addChild:_gold_imp];
  _game_scene = scene;
  return self;
}

-(void) update
{
  [_game_scene removeChild:self];
}

@end




















