//
//  GameMapFile.m
//  prototype
//
//  Created by Yifan Zhou on 2/20/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "GameMapFile.h"


// ---------------------------------------------------------
// Atomic Implementation
// ---------------------------------------------------------
@implementation GameMapFileObjectAtomic
{
  NSString* _string;
  float _number;
}

-(id) init
{
  self.type = GM_ATOMIC_NONE;
  return self;
}

-(void) setNumber:(float)number
{
  switch(self.type) {
    case GM_ATOMIC_NUM:
      _number=number;
      break;
    case GM_ATOMIC_STR:
      _string = nil;
      self.type = GM_ATOMIC_NUM;
      _number = number;
      break;
    case GM_ATOMIC_NONE:
      self.type = GM_ATOMIC_NUM;
      _number = number;
      break;
    default:
      break;
  }
}

-(void) setString:(NSString*)string
{
  switch(self.type) {
    case GM_ATOMIC_NONE:
      _string = string;
      self.type = GM_ATOMIC_STR;
      break;
    case GM_ATOMIC_NUM:
      _string = string;
      self.type = GM_ATOMIC_STR;
      break;
    case GM_ATOMIC_STR:
      _string = string;
      self.type = GM_ATOMIC_STR;
      break;
    default:
      break;
  }
}

-(NSString*) asString
{
  assert(self.type == GM_ATOMIC_STR);
  return _string;
}

-(float) asNumber
{
  assert(self.type == GM_ATOMIC_NUM);
  return _number;
}


@synthesize type;

@end


@implementation GameMapFileObjectProperty
@synthesize key;
@synthesize value;
@end


// --------------------------------------------
// GameMapFileObject implementation
// --------------------------------------------
@implementation GameMapFileObject
{
  NSMutableArray* _collection_or_cmd;
  GameMapFileObjectAtomic* _atomic;
  
}

-(id)init
{
  self.type = GM_OBJECT_NONE;
  self.name = nil;
  self.property = nil;
  _collection_or_cmd = nil;
  _atomic = nil;
  return self;
}

-(void)setCollection:(NSMutableArray *)collection
{
  switch(self.type) {
    case GM_OBJECT_COLLECTION:
    case GM_OBJECT_COMMAND:
    case GM_OBJECT_NONE:
      _collection_or_cmd = collection;
      self.type = GM_OBJECT_COLLECTION;
      break;
    case GM_OBJECT_ATOMIC:
      _atomic = nil;
      _collection_or_cmd = collection;
      self.type = GM_OBJECT_COLLECTION;
      break;
    default:
      break;
  }
}

-(void)setCommand:(NSMutableArray *)command
{
  switch(self.type) {
    case GM_OBJECT_COMMAND:
    case GM_OBJECT_COLLECTION:
    case GM_OBJECT_NONE:
      _collection_or_cmd = command;
      self.type = GM_OBJECT_COMMAND;
      break;
    case GM_OBJECT_ATOMIC:
      _atomic = nil;
      _collection_or_cmd = command;
      break;
    default:
      break;
  }
}


-(void)setAtomic:(GameMapFileObjectAtomic *)atomic
{
  switch(self.type) {
    case GM_OBJECT_COMMAND:
    case GM_OBJECT_COLLECTION:
    case GM_OBJECT_NONE:
      _collection_or_cmd = nil;
      _atomic = atomic;
      self.type = GM_OBJECT_ATOMIC;
      break;
    case GM_OBJECT_ATOMIC:
      _atomic = atomic;
      break;
    default:
      break;
  }
}


-(NSMutableArray*)asCollection
{
  assert(self.type == GM_OBJECT_COLLECTION);
  return _collection_or_cmd;
}

-(NSMutableArray*)asCommand
{
  assert(self.type == GM_OBJECT_COMMAND);
  return _collection_or_cmd;
}

-(GameMapFileObjectAtomic*)asAtomic
{
  assert(self.type == GM_OBJECT_ATOMIC);
  return _atomic;
}

-(GameMapFileObjectProperty*) getPropertyWithKey:(NSString *)key
{
  for( int i = 0 ; i < [self.property count] ; ++i ) {
    GameMapFileObjectProperty* prop = [self.property objectAtIndex:i];
    if( [prop.key isEqual:key] ) {
      return prop;
    }
  }
  return nil;
}

-(void) dumpWithFileObject:(GameMapFileObject*) object
{
  // ------------------------------
  // 1. Dump the property list here
  // ------------------------------
  NSMutableArray* pr = object.property;
  NSMutableArray* content = nil;
  GameMapFileObjectAtomic* atomic;
  if( pr != nil ) {
    for( int i = 0 ; i < [pr count] ; ++i ) {
      GameMapFileObjectProperty* pro = [property objectAtIndex:i];
      NSLog(@"[%@:",pro.key);
      if( pro.value.type == GM_ATOMIC_STR ) {
        NSLog(@"\"%@\"]",[pro.value asString]);
      } else {
        NSLog(@"%f]",[pro.value asNumber]);
      }
    }
  }
  // ------------------------------
  // 2. Name of the object
  // ------------------------------
  if( object.name != nil ) {
    NSLog(@"%@",object.name);
  }
  // ------------------------------
  // 3. Dump the content
  // ------------------------------
  switch(object.type) {
    case GM_OBJECT_ATOMIC:
      if(object.name != nil)
        NSLog(@"=");
      atomic = [object asAtomic];
      if(atomic.type == GM_ATOMIC_STR)
        NSLog(@"%@\n",[atomic asString]);
      else
        NSLog(@"%f\n",[atomic asNumber]);
      break;
    case GM_OBJECT_COMMAND:
      content = [object asCommand];
      NSLog(@"(");
      assert(content != nil);
      for( int i = 0 ; i < [content count] ; ++i ) {
        atomic = [content objectAtIndex:i];
        if( atomic.type == GM_ATOMIC_STR ) {
          NSLog(@"\"%@\"",[atomic asString]);
        } else {
          NSLog(@"%f",[atomic asNumber]);
        }
        
        if( i != [content count] -1 ) {
          NSLog(@",");
        } else {
          NSLog(@");\n");
        }
      }
      break;
    case GM_OBJECT_COLLECTION:
      NSLog(@"{\n");
      content = [object asCollection];
      for( int i = 0 ; i < [content count] ; ++i ) {
        [self dumpWithFileObject:[content objectAtIndex:i]];
      }
      NSLog(@"\n};\n");
      break;
    default:
      break;
  }
}

-(void) dump
{
  [self dumpWithFileObject:self];
}

@synthesize name;
@synthesize type;
@synthesize property;
@end


static int GetChar( NSString* script , int index ) {
  return [script length] <= index ? 0 : [script characterAtIndex:index];
}


// --------------------------------------------
// Tokenizer info
// --------------------------------------------

@implementation GameMapFileTokenizerInfo

// A string parsing routine. It is used to parse the string to a constant
// string. For example, the input script string is "aabvc\d\e\f\n",this
// routine will parse this string into string as aabvcdef\n .

-(NSString*) asString
{
  assert(self.token == TT_STRING);
  NSMutableString* ret = [[NSMutableString alloc] init];
  for( int i = self.index_start+1 ; i < self.index_end-1 ; ++i ) {
    int cha = GetChar(self.script,i);
    if(cha == '\\') {
      int ncha = GetChar(self.script,i);
      if(ncha == 'n' || ncha == 'b' || ncha == 't' ) {
        [ret appendFormat:@"%c%c",'\\',ncha];
      } else {
        [ret appendFormat:@"%c",ncha];
      }
    } else {
      [ret appendFormat:@"%c",cha];
    }
  }
  return [NSString stringWithString:ret];
}

-(NSString*) asSymbol
{
  assert(self.token == TT_SYMBOL);
  return [self.script substringWithRange:NSMakeRange(self.index_start,self.index_end-self.index_start)];
}

-(float) asNumber
{
  assert(self.token == TT_NUMBER);
  NSString* substr = [self.script substringWithRange:NSMakeRange(self.index_start,self.index_end-self.index_start)];
  return [substr floatValue];
}

@synthesize script;
@synthesize index_start;
@synthesize index_end;
@synthesize token;


@end



@implementation GameMapFileErrorCollector

-(void) getFriendlyLocationInfo:(NSString*) script inIndex:(int)index outputLine:(int*)line outputCharPos:(int*)chaPos
{
  if(index == -1 || script == NULL) {
    *line = 0;
    *chaPos=0;
  } else {
    *line = 1;
    *chaPos=1;
    for( int i = 0 ;i < index ; ++i ) {
      int cha = GetChar(script,i);
      assert(cha !=0);
      if(cha == '\n') {
        ++*line;
        *chaPos=1;
      }
      ++*chaPos;
    }
  }
}

-(void) reportError:(NSString *)context withScript:(NSString *)script withIndex:(int)index withMessage:(NSString *)message {
  int line;
  int cha;
  [self getFriendlyLocationInfo:script inIndex:index outputLine:&line outputCharPos:&cha];
  [self.message appendFormat:@"Context:%@\nLineNumber:%d\nCharPosition:%d\nMessage:%@\n",context,line,cha,message];
}

-(id) init
{
  self.message = [[NSMutableString alloc] init];
  return self;
}

@end

@implementation GameMapFileTokenizer
{
  NSString* _script;
  int _cur_index;
}

+(NSString*) getTokenName:(int)tk
{
  switch(tk) {
    case TT_PROPERTY_START: return @"";
    case TT_PROPERTY_END: return @"]";
    case TT_PROPERTY_ASSIGN: return @":";
    case TT_COLLECTION_START: return @"{";
    case TT_COLLECTION_END: return @"}";
    case TT_COMMAND_START: return @"(";
    case TT_COMMAND_END: return @")";
    case TT_ASSIGN: return @"=";
    case TT_SYMBOL: return @"<symbol>";
    case TT_NUMBER: return @"<number";
    case TT_STRING: return @"<string>";
    case TT_COMMA: return @",";
    case TT_END: return @";";
    case TT_EOF: return @"<eof>";
    case TT_SPACE: return @"<space>";
    case TT_COMMENT: return @"<comment>";
    case TT_UNKNOWN: return @"<unknown>";
    default:
      assert(0);
      return nil;
  }
}

#define C(t,o) \
  (info).token = t; \
  (info).index_start = _cur_index; \
  (info).index_end = _cur_index+o; \
  return info;

#define TK_CHECK(Message) \
  do { if(ok == NO) { \
  [err reportError:@"GameMapFileTokenizer" withScript:_script withIndex:_cur_index withMessage:Message]; \
  (info).token = TT_UNKNOWN; \
  (info).index_start = _cur_index; \
  (info).index_end = _cur_index + idx; \
  return info;} }while(0)


-(int) skipNumber:(int)index status:(BOOL*) ok {
  enum {
    DIGIT_SIGN,
    DIGIT_DOT_TERM,
    DIGIT,
    DIGIT_AFTER_DOT,
    DIGIT_TERM,
  };
  
  int state = DIGIT_SIGN;
  while(1) {
    int cha = GetChar(_script,index);
    switch(state) {
      case DIGIT_SIGN:
        if(cha == '+' || cha == '-') {
          state = DIGIT;
        } else if(isdigit(cha)) {
          state = DIGIT_DOT_TERM;
        } else {
          *ok = NO;
          return index;
        }
        break;
      case DIGIT_DOT_TERM:
        if( cha == '.' ) {
          state = DIGIT_AFTER_DOT;
        } else if( !isdigit(cha) ) {
          goto finish;
        }
        break;
      case DIGIT:
        if(isdigit(cha))
          state = DIGIT_DOT_TERM;
        else {
          *ok = NO;
          return index;
        }
        break;
      case DIGIT_AFTER_DOT:
        if(isdigit(cha))
          state = DIGIT_TERM;
        else {
          *ok = NO;
          return index;
        }
        break;
      case DIGIT_TERM:
        if(!isdigit(cha))
          goto finish;
        break;
      default:
        break;
    }
    ++index;
  }
finish:
  *ok = YES;
  return index;
}


-(int) skipString:(int)index status:(BOOL*)ok
{
  assert(GetChar(_script,index) == '\"');
  ++index;
  while(1) {
    int cha = GetChar(_script,index);
    if(cha == '\\') {
      ++index;
    } else if( cha == 0 ) {
      // error
      *ok = NO;
      return index;
    } else if( cha == '\"') {
      ++index;
      goto finish;
    }
    ++index;
  }
  
finish:
  *ok = YES;
  return index;
}

-(int) skipSymbol:(int)index status:(BOOL*)ok
{
  ++index;
  while(1) {
    int cha = GetChar(_script,index);
    if( cha == 0 )
      goto finish;
    else if( !isdigit(cha) && !isalpha(cha) && cha != '_' )
      goto finish;
    ++index;
  }
finish:
  *ok = YES;
  return index;
}

-(int) skipComment:(int) index
{
  while(1) {
    int cha = GetChar(_script,index);
    if(cha == 0 || cha == '\n')
      return index;
    ++index;
  }
}

-(int) skipWhiteSpace:(int) index
{
  int cha;
  while(isspace((cha = GetChar(_script,++index))));
  return index;
}


-(GameMapFileTokenizerInfo*) moveCursor:(GameMapFileErrorCollector*) err
{
  GameMapFileTokenizerInfo* info = [[GameMapFileTokenizerInfo alloc] init];
  info.script = _script;
  int cha = GetChar(_script,_cur_index);
  int idx;
  BOOL ok;
  switch(cha) {
    case 0:
      C(TT_EOF,1);
    case '[':
      C(TT_PROPERTY_START,1);
    case ']':
      C(TT_PROPERTY_END,1);
    case '{':
      C(TT_COLLECTION_START,1);
    case '}':
      C(TT_COLLECTION_END,1);
    case '(':
      C(TT_COMMAND_START,1);
    case ')':
      C(TT_COMMAND_END,1);
    case ':':
      C(TT_PROPERTY_ASSIGN,1);
    case '=':
      C(TT_ASSIGN,1);
    case ',':
      C(TT_COMMA,1);
    case ';':
      C(TT_END,1);
    case '/':
      cha = GetChar(_script,_cur_index+1);
      if(cha == '/') {
        idx = [self skipComment:_cur_index+2];
        C(TT_COMMENT,idx-_cur_index);
      } else {
        [err reportError:@"GameMapFileTokenizer" withScript:_script withIndex:_cur_index
             withMessage:@"Unknown token!"];
        C(TT_UNKNOWN,0);
      }
    case'0':case'1':case'2':case'3':case'4':case'5':
    case'6':case'7':case'8':case'9':case'+':case'-':
      idx = [self skipNumber:_cur_index status:&ok];
      TK_CHECK(@"Unknown tokenizer,Parsing number error!");
      C(TT_NUMBER,idx-_cur_index);
    case '\"':
      idx = [self skipString:_cur_index status:&ok];
      TK_CHECK(@"Unknown tokenizer,Parsing constant string error!");
      C(TT_STRING,idx-_cur_index);
    default:
      if( cha == '_' || isalpha(cha) ) {
        idx = [self skipSymbol:_cur_index status:&ok];
        TK_CHECK(@"Unknown tokenizer,Parsing symbol error!");
        C(TT_SYMBOL,idx-_cur_index);
      } else if(isspace(cha)) {
        idx = [self skipWhiteSpace:_cur_index];
        C(TT_SPACE,idx-_cur_index);
      } else {
        [err reportError:@"GameMapFileTokenizer" withScript:_script withIndex:_cur_index withMessage:@"Unknown token!"];
        C(TT_UNKNOWN,0);
      }
  }
}

-(GameMapFileTokenizerInfo*) peek:(GameMapFileErrorCollector*) err
{
  GameMapFileTokenizerInfo* info = [self moveCursor:err];
  do {
    switch(info.token) {
      case TT_COMMENT:
      case TT_SPACE:
        _cur_index = info.index_end;
        break;
      default:
        return info;
    }
    info = [self moveCursor:err];
  } while(1);
}


-(GameMapFileTokenizerInfo*) move:(GameMapFileErrorCollector *)err
{
  GameMapFileTokenizerInfo* info = [self peek:err];
  _cur_index = info.index_end;
  return info;
}

-(BOOL) consume:(GameMapFileTokenizerInfo *)info
{
  if( _cur_index == info.index_start )
    _cur_index = info.index_end;
  else
    return NO;
  return YES;
}

-(id) initWithScript:(NSString *)script
{
  _script = script;
  _cur_index = 0;
  return self;
}

@end
#undef C
#undef TK_CHECK

#define VERIFY(x) \
  do { \
  bool ret = (x); \
  assert(ret==YES); }while(0)


#define EXPECT(tk) \
  do { \
  if(token.token !=tk) { \
  [err reportError:@"GameMapFileParser" withScript:_script withIndex:token.index_start \
  withMessage:[NSString stringWithFormat:@"Unexpecting token:%@.Expecting:%@",[GameMapFileTokenizer getTokenName:token.token] \
  ,[GameMapFileTokenizer getTokenName:tk]]]; \
  return NO;}}while(0)


static BOOL IsAtomicToken( GameMapFileTokenizerInfo* info ) {
  return info.token == TT_NUMBER || info.token == TT_STRING;
}

@implementation GameMapFileParser
{
  GameMapFileTokenizer* _tokenizer;
  NSString* _script;
}

-(BOOL) parseAtomic:(GameMapFileObjectAtomic*) atomic withError:(GameMapFileErrorCollector*)err
{
  GameMapFileTokenizerInfo* token = [_tokenizer move:err];
  if(IsAtomicToken(token) == YES) {
    if(token.token == TT_NUMBER) {
      [atomic setNumber:[token asNumber]];
    } else {
      [atomic setString:[token asString]];
    }
    return YES;
  } else {
    [err reportError:@"GameMapFileParser" withScript:_script
           withIndex:token.index_start withMessage:
     [NSString stringWithFormat:@"Expecting atomic value here but with:%@",
      [GameMapFileTokenizer getTokenName:token.token]]];
    return NO;
  }
}

-(BOOL) parseProperty:(GameMapFileObjectProperty*) property withError:(GameMapFileErrorCollector*)err
{
  GameMapFileTokenizerInfo* token = [_tokenizer move:err];
  EXPECT(TT_SYMBOL);
  property.key = [token asSymbol];
  token = [_tokenizer move:err];
  EXPECT(TT_PROPERTY_ASSIGN);
  property.value = [[GameMapFileObjectAtomic alloc] init];
  return [self parseAtomic:property.value withError:err];
}

-(BOOL) parsePropertyList:(NSMutableArray*)properties withError:(GameMapFileErrorCollector*)err
{
  GameMapFileTokenizerInfo* token;
  do {
    token = [_tokenizer peek:err];
    if(token.token != TT_PROPERTY_START) {
      return YES;
    } else {
      VERIFY([_tokenizer consume:token]);
      GameMapFileObjectProperty* property = [[GameMapFileObjectProperty alloc] init];
      if([self parseProperty:property withError:err] == NO ) {
        return NO;
      } else {
        [properties addObject:property];
      }
      token = [_tokenizer move:err];
      EXPECT(TT_PROPERTY_END);
    }
  } while(1);
}


-(BOOL) parseCommandList:(NSMutableArray*) command withError:(GameMapFileErrorCollector*)err
{
  GameMapFileTokenizerInfo* token;
  token = [_tokenizer move:err];
  EXPECT(TT_COMMAND_START);
  // -----------------------------
  // A quick check for empty command list
  // -----------------------------
  token = [_tokenizer peek:err];
  if( token.token == TT_COMMAND_END ) {
    VERIFY([_tokenizer consume:token]);
    return YES;
  }
  do {
    GameMapFileObjectAtomic* atomic = [[GameMapFileObjectAtomic alloc] init];
    if([self parseAtomic:atomic withError:err] == NO) {
      return NO;
    }
    [command addObject:atomic];
    token = [_tokenizer peek:err];
    if( token.token == TT_COMMAND_END ) {
      VERIFY([_tokenizer consume:token]);
      break;
    } else if( token.token == TT_COMMA ) {
      VERIFY([_tokenizer consume:token]);
      continue;
    } else {
      [err reportError:@"GameMapFileTokenizer" withScript:_script withIndex:token.index_start
           withMessage:[NSString stringWithFormat:@"Unexpected token:%@ when parsing command line.",
                        [GameMapFileTokenizer getTokenName:token.token]]];
      return NO;
    }
  }while(1);
  return YES;
}

-(BOOL) parseCollection:(NSMutableArray*)collection withError:(GameMapFileErrorCollector*) err
{
  GameMapFileTokenizerInfo* token = [_tokenizer move:err];
  assert(token.token == TT_COLLECTION_START);
  while(1) {
    token = [_tokenizer peek:err];
    if( token.token != TT_COLLECTION_END ) {
      GameMapFileObject* object = [[GameMapFileObject alloc] init];
      if([self parseFileObject:object withError:err] == NO ) {
        return NO;
      }
      [collection addObject:object];
    } else {
      VERIFY([_tokenizer consume:token]);
      break;
    }
  }
  return YES;
}

-(BOOL) parseRightHandValue:(GameMapFileObject*)object withError:(GameMapFileErrorCollector*)err
{
  GameMapFileTokenizerInfo* token = [_tokenizer peek:err];
  if(token.token == TT_COLLECTION_START) {
    NSMutableArray* collection = [[NSMutableArray alloc] init];
    if( [self parseCollection:collection withError:err] == YES ) {
      [object setCollection:collection];
      return YES;
    } else {
      return NO;
    }
  } else if( IsAtomicToken(token) == YES ) {
    // Atomic token
    GameMapFileObjectAtomic* atomic = [[GameMapFileObjectAtomic alloc] init];
    [object setAtomic:atomic];
    return YES;
  } else {
    // Unexpected token
    [err reportError:@"GameMapFileTokenizer" withScript:_script withIndex:token.index_start
         withMessage:[NSString stringWithFormat:@"Unexpected token:%@ when parsing right hand value.",
                      [GameMapFileTokenizer getTokenName:token.token]]];
    return NO;
  }
}


-(BOOL) parseFileObject:(GameMapFileObject*)object withError:(GameMapFileErrorCollector*)err {
  // 1. Parse optional properties
  // ------------------------------
  object.property = [[NSMutableArray alloc] init];
  if([self parsePropertyList:object.property withError:err] == NO)
    return NO;
  // 2. Check the type of the object
  // -------------------------------
  GameMapFileTokenizerInfo* token = [_tokenizer peek:err];
  if( token.token == TT_SYMBOL ) {
    object.name = [token asSymbol];
    VERIFY([_tokenizer consume:token]);
    token = [_tokenizer peek:err];
  }
  if(token.token == TT_COMMAND_START) {
    NSMutableArray* command = [[NSMutableArray alloc] init];
    [object setCommand:command];
    if( [self parseCommandList:command withError:err] == NO )
      return NO;
  } else if( token.token == TT_ASSIGN ) {
    VERIFY([_tokenizer consume:token]);
    if( [self parseRightHandValue:object withError:err] == NO )
      return NO;
  } else {
    if( [self parseRightHandValue:object withError:err] == NO )
      return NO;
  }
  // 3. Consume the last end indicator
  // ---------------------------------
  token = [_tokenizer move:err];
  EXPECT(TT_END);
  return YES;
}

-(GameMapFileObject*) parse:(NSString *)fileName withError:(GameMapFileErrorCollector *)err
{
  NSError* error = nil;
  NSMutableString* str = [[NSMutableString alloc]init];
  [str appendString:fileName];
  _script= [[NSString alloc] initWithContentsOfFile:[NSString stringWithString:str] encoding:NSASCIIStringEncoding error:&error];
  if( _script == nil ) {
    // Try bundle file
    _script = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@""]
               encoding:NSASCIIStringEncoding error:&error];
    if(_script == nil) {
      [err reportError:@"GameFileParser" withScript:nil withIndex:-1 withMessage:[error localizedDescription]];
      return nil;
    }
  }
  _tokenizer = [[GameMapFileTokenizer alloc] initWithScript:_script];
  GameMapFileObject* object = [[GameMapFileObject alloc] init];
  if( [self parseFileObject:object withError:err] == YES )
    return object;
  else {
    return nil;
  }
}


@end
