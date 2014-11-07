//
//  GameScene.m
//  prototype
//
//  Created by Yifan Zhou on 3/1/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "GameScene.h"
#import "PhysicalWorld.h"
#import "Misc.h"
#import "CCNodeColor.h"
#import "cocos2d-ui.h"
#import "Player.h"
#import "GameStatistics.h"
#import "Environment.h"
#import "PauseNode.h"
#import "PauseNodeDelegate.h"
#import "SceneManager.h"
#import "CCAction.h"
#import "SoundManager.h"

//
// ----------------------------------------------------
// Add new Level feature support for our scene file.
// GameScene = {
// ...
//   [OffsetX:0]
//   [OffsetY:0]
//   Level = {
//      Name("");
//      LevelFile("");
//   };
//
//   [OffsetX:-25000]
//   [OffsetY:0]
//   Level = {
//      Name("");
//      LevelFile("");
//   }
// ----------------------------------------------------
//


@interface GameLevelObject : NSObject
@property NSString* level_name;
@property NSString* level_file_name;
@property NSMutableArray* actor_list;
@property NSMutableArray* map_list;
@property float offset_x;
@property float offset_y;
@property vec2_t restart_offset;
@property int map_zvalue;
@property int actor_zvalue;
@end

// ------------------------------
// A level object is something like this:
//
// [StartX:232] // Optional
// [StartY:0] // Optional
// Level = {
//  Name("GameLevel1");
//  LevelFile("GameLevel1.lvl");
// };
//
// GameLevel1.lvl
// ------------------------------
// Level = {
//   [Z:Value]
//   Map = {
//      ....
//   };
//   [Z:Value]
//   Actor= {
//      ...
//   };
// };
// -------------------------------

@implementation GameLevelObject
{
@public
  NSString* _level_name;
  NSString* _level_file_name;
  NSMutableArray* _actor_list;
  NSMutableArray* _map_list;
  float _offset_x;
  float _offset_y;
  int _map_z;
  int _actor_z;
  vec2_t _restart_offset;
}

@synthesize level_name = _level_name;
@synthesize actor_list = _actor_list;
@synthesize map_list = _map_list;
@synthesize offset_x = _offset_x;
@synthesize offset_y = _offset_y;
@synthesize map_zvalue = _map_z;
@synthesize actor_zvalue = _actor_z;
@synthesize level_file_name = _level_file_name;
@synthesize restart_offset = _restart_offset;

-(void) load
{
  GameMapFileObject* gm_object;
  BOOL bret;
  GameMapFileParser* parser = [[GameMapFileParser alloc] init];
  GameMapFileErrorCollector* collector = [[GameMapFileErrorCollector alloc] init];
  GameMapFileObject* level_info = [parser parse:_level_file_name withError:collector];
  assert(level_info);
  
  float z;
  gm_object = [self findGameMapObject:level_info withKey:@"Map"];
  assert(gm_object);
  bret = [self tryGetPropertyNumberAsFloat:gm_object withKey:@"Z" withValue:&z];
  assert(bret);
  _map_z = (int)z;
  _map_list = [gm_object asCollection];
  
  gm_object = [self findGameMapObject:level_info withKey:@"Actor"];
  if( gm_object == nil ) {
    _actor_list = [[NSMutableArray alloc]init];
  } else {
    bret = [self tryGetPropertyNumberAsFloat:gm_object withKey:@"Z" withValue:&z];
    _actor_z = (int)z;
    _actor_list = [gm_object asCollection];
  }
}

-(BOOL) tryGetPropertyNumberAsFloat:(GameMapFileObject*)object withKey:(NSString*)key withValue:(float*)val
{
  GameMapFileObjectProperty* prop = [object getPropertyWithKey:key];
  if( prop == nil ) return NO;
  else {
    *val = [prop.value asNumber];
    return YES;
  }
}

-(GameMapFileObject*) findGameMapObject:(GameMapFileObject*)object withKey:(NSString*)key
{
  NSMutableArray* collection = [object asCollection];
  for( int i = 0 ; i < collection.count ; ++i ) {
    GameMapFileObject* object = (GameMapFileObject*)[collection objectAtIndex:i];
    if([object.name isEqual:key]) {
      return object;
    }
  }
  return nil;
}

-(NSString*) queryKeyValueAsString:(GameMapFileObject*)par
{
  NSMutableArray* command = [par asCommand];
  assert(command.count ==1);
  return [[command objectAtIndex:0] asString];
}

-(id) init:(GameMapFileObject*)level_object
{
  self = [super init];
  if( self == nil ) return nil;
  // 1. Try to grab the Property Value here
  BOOL bret = [self tryGetPropertyNumberAsFloat:level_object withKey:@"OffsetX" withValue:&_offset_x];
  if(!bret) {
    _offset_x = 0.0f;
  }
  bret = [self tryGetPropertyNumberAsFloat:level_object withKey:@"OffsetY" withValue:&_offset_y];
  if(!bret) {
    _offset_y = 0.0f;
  }
  // 2. Get the Name
  GameMapFileObject* gm_object = [self findGameMapObject:level_object withKey:@"Name"];
  assert(gm_object);
  _level_name = [self queryKeyValueAsString:gm_object];
  // 3. Get the file name and load the file
  gm_object = [self findGameMapObject:level_object withKey:@"LevelFile"];
  assert(gm_object);
  _level_file_name = [self queryKeyValueAsString:gm_object];
  [self load];
  // 4. Get the Restart Offset Information
  gm_object = [self findGameMapObject:level_object withKey:@"RestartOffset"];
  assert(gm_object);
  NSMutableArray* command = [gm_object asCommand];
  assert(command.count ==2);
  GameMapFileObjectAtomic* atomic = [command objectAtIndex:0];
  _restart_offset.x = [atomic asNumber];
  atomic = [command objectAtIndex:1];
  _restart_offset.y = [atomic asNumber];
  return self;
}

@end


@implementation GameScene
{
  PhysicalWorld* _physical_world;
  GameMapFileObject* _physical_world_object;
  
  Player* _player;
  GameMapFileObject* _player_object;
  
  Environment* _environment;
  GameMapFileObject* _environment_object;
  
  GameStatistics* _game_statistics;
  SoundManager* _sound_manager;
  // For shaking the screen
  float _shake_timer;
  float _shake_duration;
  // List of levels goes here
  NSMutableArray* _level_list;
  GameLevelObject* _cur_level;
  int _cur_level_index;
}


-(void) modifyPropertyValue:(GameMapFileObject*)object withKey:(NSString*)key withValue:(float)value
{
  GameMapFileObjectProperty* prop = [object getPropertyWithKey:key];
  assert(prop);
  GameMapFileObjectAtomic* atomic = [[GameMapFileObjectAtomic alloc] init];
  [atomic setNumber:value];
  prop.value = atomic;
}

-(void) spawnObjectByPosition:(NSMutableArray*)array
                        withZ:(int)z
{
  // -------------------------------------------------------------
  // In order to test wheather this object should be put into the
  // scene, we need to calculate its left most x/y value. This job
  // is done by seeing its PositionX/PositionY.
  // -------------------------------------------------------------
  vec2_t absolute_position = _physical_world.absolute_position;
  rect_t viewport = _physical_world.viewport;
  // Checking where we need to iterate
  NSMutableArray* discard = [[NSMutableArray alloc]init];
  int len = (int)[array count];
  for( int i = 0 ; i < len ; ++i ) {
    GameMapFileObject* game_element = (GameMapFileObject*)[array objectAtIndex:i];
    
    float StartX = [self getPropertyNumber:game_element withKey:@"StartX"];
    float StartY = [self getPropertyNumber:game_element withKey:@"StartY"];
    
    float leftMostX = StartX;
    float leftMostY = StartY;
    
    if( leftMostX -absolute_position.x < viewport.x + viewport.width &&
        leftMostY -absolute_position.y < viewport.y + viewport.height ) {
      
      CCNode* node = [self createInstance:game_element.name
                           withFactoryMethod:@"createObject:withScene:"
                           withObject:game_element
                           withScene:self];
      if( node != nil ) {
        [self addChild:node z:z];
      }
      [discard addObject:game_element];
    } else {
      break;
    }
  }
  [array removeObjectsInArray:discard];
}

-(id) createInstance:(NSString*)className withFactoryMethod:(NSString*)factoryMethod
          withObject:(GameMapFileObject*)par withScene:(GameScene*)scene
{
  return CreateObjectByReflection(className, factoryMethod, par, scene);
}

-(void)showGameOverNode
{
    GameOverNode *node=[[GameOverNode alloc]
                        initWithScore:_game_statistics.current_score
                                 Gold:_game_statistics.current_gold];
    node.positionType=CCPositionTypeNormalized;
    node.position=ccp(0.5f,0.5f);
    node.delegate=self;
    [self addChild:node z:30];
    
}

-(void) tickMapObject
{
  assert(_cur_level);
  [self spawnObjectByPosition:_cur_level.map_list
                        withZ:_cur_level.map_zvalue];
}

-(void) tickActorObject
{
  assert(_cur_level);
  [self spawnObjectByPosition:_cur_level.actor_list
                        withZ:_cur_level.actor_zvalue];
}

-(void) tickLevel
{
  if( _cur_level == nil ) return;
  if( _cur_level.map_list.count == 0 && _cur_level.actor_list.count == 0 ) {
    ++_cur_level_index;
    if(_level_list.count > _cur_level_index) {
      _cur_level = [_level_list
                    objectAtIndex:_cur_level_index];
    }
  }
  [self tickMapObject];
  [self tickActorObject];
}

-(void) tickPhysicalWorld:(float)delta
{
  [_physical_world tickWorld:delta];
}

-(void) update:(CCTime)delta
{
  [self tickLevel];
  [self tickPhysicalWorld:(float)delta];
  
  // Shaking
  if(_shake_timer == 0.0f) return;
  _shake_timer -= delta;
  if(_shake_timer < 0.0f) {
    _shake_timer = 0.0f;
    self.position = ccp(0,0);
    return;
  } else {
    // Shaking goes here
    float x = arc4random() % 40;
    float y = arc4random() % 40;
    x = x - 20.0f;
    y = y - 20.0f;
    self.position = ccp(x,y);
  }
}

-(float) getPropertyNumber:(GameMapFileObject*)object withKey:(NSString*)key
{
  GameMapFileObjectProperty* property = [object getPropertyWithKey:key];
  assert(property);
  GameMapFileObjectAtomic* atomic = property.value;
  return [atomic asNumber];
}


-(void)initPhysicalWorld:(GameMapFileObject*)object withAbsolutePosition:(vec2_t)abs
{
  PhysicalWorldSettings settings;
  settings.gravity=[self getPropertyNumber:object withKey:@"Gravity"];
  settings.move_speed.x = [self getPropertyNumber:object withKey:@"MoveSpeedX"];
  settings.move_speed.y = [self getPropertyNumber:object withKey:@"MoveSpeedY"];
  settings.absolute_position = abs;
  _physical_world = [[PhysicalWorld alloc] initWithConfig:&settings];
}

-(void)initPlayer:(GameMapFileObject*)object
{
  // Grab the z value here
  float floatZ =[self getPropertyNumber:object withKey:@"Z"];
  
  CCNode* player = [self createInstance:@"Player"
                    withFactoryMethod:@"createObject:withScene:"
                    withObject:object withScene:self];
  assert(player);
  _player = (Player*)player;
  [self addChild:player z:(int)floatZ];
}

-(void)initEnvironment:(GameMapFileObject*)object
{
  float floatZ =[self getPropertyNumber:object withKey:@"Z"];
  CCNode* env = [self createInstance:@"Environment"
                   withFactoryMethod:@"createObject:withScene:"
                          withObject:object withScene:self];
  assert(env);
  [self addChild:env z:(int)floatZ];
  _environment = (Environment*)env;
}

-(void)initGameStatistics:(GameMapFileObject*)object
{
  float floatZ =[self getPropertyNumber:object withKey:@"Z"];
  _game_statistics = [self createInstance:@"GameStatistics"
                       withFactoryMethod:@"createObject:withScene:"
                       withObject:object withScene:self];
  assert(_game_statistics);
  [self addChild:_game_statistics z:(int)floatZ];
}


-(void) initLevel:(GameMapFileObject*)object
{
  [_level_list addObject:[[GameLevelObject alloc]init:object]];
}

-(void) initSoundManager:(GameMapFileObject*)object
{
  _sound_manager = [self createInstance:object.name
                      withFactoryMethod:@"createObject:withScene:"
                      withObject:object withScene:self];
  assert(_sound_manager);
}

-(id) init:(GameMapFileObject *)object
{
  self = [super init];
  if( self == nil ) return nil;
  self.userInteractionEnabled = YES;
  _level_list = [[NSMutableArray alloc] init];
  // Find out the physical world object
  NSMutableArray* collection = [object asCollection];
  for( int i = 0 ; i < [collection count] ; ++i ) {
    GameMapFileObject* object = [collection objectAtIndex:i];
    if( [object.name isEqual:@"PhysicalWorld"] ) {
      [self initPhysicalWorld:object withAbsolutePosition:MakeVector(0.0f, 0.0f)];
      _physical_world_object = object;
    } else if( [object.name isEqual:@"Level"] ) {
      [self initLevel:object];
    } else if( [object.name isEqual:@"Player"] ) {
      [self initPlayer:object];
      _player_object = object;
    } else if( [object.name isEqual:@"Environment"]) {
      [self initEnvironment:object];
      _environment_object= object;
    } else if( [object.name isEqual:@"GameStatistics"]) {
      [self initGameStatistics:object];
    } else if( [object.name isEqual:@"SoundManager"] ) {
      [self initSoundManager:object];
    } else {
      continue;
    }
  }

  CCButton *pauseButton = [CCButton buttonWithTitle:@"PAUSE" fontName:@"Arial" fontSize:18.0f];
  pauseButton.positionType = CCPositionTypeNormalized;
  pauseButton.position = ccp(0.9f, 0.9f);
  [pauseButton setTarget:self selector:@selector(pauseButtonClicked:)];

  _shake_timer = 0.0f;
  _shake_duration = 0.0f;
  [_sound_manager playBackgroundMusic];

  if(_level_list.count !=0) {
    _cur_level_index = 0;
    _cur_level = [_level_list objectAtIndex:0];
    self.physical_world.absolute_position = MakeVector(_cur_level.offset_x, _cur_level.offset_y);
  }
  return self;
}



-(void)pauseButtonClicked:(id)sender
{
    PauseNode *menu=[PauseNode node];
    menu.delegate=self;
    [self.scene addChild:menu z:5];
    self.paused=true;
}

-(void)resignPauseMenu
{
    self.paused=false;
}

-(void)restartCurrentGame
{
  // Restart the current game REALLY
  self.paused=false;
  if(_cur_level == nil) return;
  [_cur_level load];
  [self removeAllChildren];
  // Add game statistics into the children list
  [self addChild:_game_statistics];
  // We cannot really stop the whole physical world
  // since I don't implement this, what we can do is
  // recreate new physical world and also player .
  [self.game_statistics clear];
  [self initEnvironment:_environment_object];
  [self initPhysicalWorld:_physical_world_object withAbsolutePosition:_cur_level.restart_offset];
  [self initPlayer:_player_object];
  [self.sound_manager playBackgroundMusic];
}

-(void)restartGame
{
  [self restartCurrentGame];
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
  CGPoint location = [touch locationInView: [touch view]];
  // put your touch handling code here
  if( location.x <  ([CCDirector sharedDirector].viewSize.width / 2.0f)) {
    [_player leftButtonCall];
  } else {
    [_player rightButtonCall];
  }
}


-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
  CGPoint location = [touch locationInView: [touch view]];
  // put your touch handling code here
  if( location.x <  ([CCDirector sharedDirector].viewSize.width / 2.0f)) {
    [_player leftButtonRelease];
  } else {
    [_player rightButtonRelease];
  }
}

// -----------------------------------------------------------------------
#pragma mark - Enter & Exit
// -----------------------------------------------------------------------

- (void)onEnter
{
  // always call super onEnter first
  [super onEnter];
  
  // In pre-v3, touch enable and scheduleUpdate was called here
  // In v3, touch is enabled by setting userInterActionEnabled for the individual nodes
  // Pr frame update is automatically enabled, if update is overridden
  
}

// -----------------------------------------------------------------------

- (void)onExit
{
  // always call super onExit last
  [super onExit];
}

-(void) gameOver
{
  [_game_statistics gameOver];
  [_sound_manager playGameOverMusic];
  [_physical_world stop];
  [_environment stop];
  // Last call MUST
  [self showGameOverNode];
}


-(void) shakeScene:(float)duration
{
  _shake_duration = duration;
  _shake_timer = _shake_duration;
}

@synthesize physical_world = _physical_world;
@synthesize player = _player;
@synthesize game_statistics = _game_statistics;
@synthesize background = _background;
@synthesize sound_manager = _sound_manager;

-(NSString*) current_level_name
{
  return _cur_level == nil ? nil : _cur_level.level_name;
}

@end
