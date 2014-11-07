//
//  PauseNode.m
//  Mario
//
//  Created by Lifei Wang on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "PauseNode.h"
#import "cocos2d-ui.h"

@implementation PauseNode
+(PauseNode *)node
{
    return [[PauseNode alloc]init];
}

-(id)init
{
    self = [super init];
    if (self){
        CCNodeColor *background = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f]];
        
        CCButton *stopButton = [CCButton buttonWithTitle:@"RESUME" fontName:@"Arial" fontSize:18.0f];
        stopButton.positionType = CCPositionTypeNormalized;
        //Q1: ccp
        stopButton.position = ccp(0.5f, 0.4f);
        [stopButton setTarget:self selector:@selector(resumeButtonClicked:)];
        [background addChild:stopButton];
        
        CCButton *retryButton = [CCButton buttonWithTitle:@"RETRY" fontName:@"Arial" fontSize:18.0f];
        retryButton.positionType = CCPositionTypeNormalized;
        //Q1: ccp
        retryButton.position = ccp(0.5f, 0.6f);
        [retryButton setTarget:self selector:@selector(retryButtonClicked:)];
        [background addChild:retryButton];
        
        [self addChild:background];
    }
    return self;
}

-(void)resumeButtonClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(resignPauseMenu)]) {
        [self.delegate resignPauseMenu];
    }
    [self.parent removeChild:self];
}

-(void)retryButtonClicked:(id)sender
{
    [self.parent removeChild:self];
    if (self.delegate && [self.delegate respondsToSelector:@selector(restartGame)]){
        [self.delegate restartCurrentGame];
    }
    
}

@end
