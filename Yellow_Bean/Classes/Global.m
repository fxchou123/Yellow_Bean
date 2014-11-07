//
//  Global.m
//  Mario
//
//  Created by Lifei Wang on 3/22/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "Global.h"

static Global* _global=nil;


@implementation Global

+(Global *)sharedInstance
{
    if (_global==nil){
        _global = [[Global alloc]init];

    }
    return _global;
}

-(id)init
{
    self = [super init];
    if (self){
    }
    return self;
}

@end
