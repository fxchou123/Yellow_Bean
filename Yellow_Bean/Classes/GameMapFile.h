//
//  GameMapFile.h
//  prototype
//
//  Created by Yifan Zhou on 2/20/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>

// ------------------------------------
// AtomicValue for GameMapFileObject
// ------------------------------------
@interface GameMapFileObjectAtomic : NSObject

-(NSString*) asString;
-(float) asNumber;
-(id)init;
-(void)setNumber:(float)number;
-(void)setString:(NSString*)string;
@property int type;

enum {
  GM_ATOMIC_STR,
  GM_ATOMIC_NUM,
  GM_ATOMIC_NONE
};

@end


@interface GameMapFileObjectProperty: NSObject
@property NSString* key;
@property GameMapFileObjectAtomic* value;
@end



@interface GameMapFileObject:NSObject

-(id)init;
-(NSMutableArray*) asCollection;
-(NSMutableArray*) asCommand;
-(GameMapFileObjectAtomic*) asAtomic;
-(void) setCollection:(NSMutableArray*)collection;
-(void) setCommand:(NSMutableArray*) command;
-(void) setAtomic:(GameMapFileObjectAtomic*)atomic;
-(void) dump;


-(GameMapFileObjectProperty*) getPropertyWithKey:(NSString*)key;

@property NSString* name;
@property int type;
@property NSMutableArray* property;


enum {
  GM_OBJECT_COLLECTION,
  GM_OBJECT_COMMAND,
  GM_OBJECT_ATOMIC,
  GM_OBJECT_NONE
};

@end


@interface GameMapFileTokenizerInfo:NSObject
@property NSString* script;
@property int index_start;
@property int index_end;
@property int token;

-(NSString*) asString;
-(NSString*) asSymbol;
-(float) asNumber;

@end


@interface GameMapFileErrorCollector: NSObject
@property NSMutableString* message;
-(void) reportError:(NSString*) context withScript:(NSString*)script
          withIndex:(int)index withMessage:(NSString*)message;
-(id)init;
@end

@interface GameMapFileTokenizer:NSObject

enum {
  TT_PROPERTY_START,
  TT_PROPERTY_END,
  TT_COLLECTION_START,
  TT_COLLECTION_END,
  TT_COMMAND_START,
  TT_COMMAND_END,
  TT_SYMBOL,
  TT_STRING,
  TT_NUMBER,
  TT_PROPERTY_ASSIGN,
  TT_ASSIGN,
  TT_END,
  TT_COMMA,
  TT_SPACE,
  TT_COMMENT,
  TT_EOF,
  TT_UNKNOWN,
  
  SIZE_OF_TOKENS
};


-(id) initWithScript:(NSString*)script;
+(NSString*) getTokenName:(int)tk;
-(GameMapFileTokenizerInfo*) peek:(GameMapFileErrorCollector*)err;
-(GameMapFileTokenizerInfo*) move:(GameMapFileErrorCollector*)err;
-(BOOL) consume:(GameMapFileTokenizerInfo*) info;

@end


@interface GameMapFileParser:NSObject

-(GameMapFileObject*) parse:(NSString*)fileName withError:(GameMapFileErrorCollector*)err;

@end
