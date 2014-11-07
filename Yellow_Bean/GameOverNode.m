//
//  GameOverNode.m
//  Mario
//
//  Created by Yifan Zhou on 3/10/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "GameOverNode.h"
#import "cocos2d-ui.h"
#import "MainMenu.h"
#import "Global.h"



@implementation GameOverNode
-(id)initWithScore:(NSInteger)score Gold:(NSInteger)gold
{
    self = [super init];
    if (self){
        CCSprite *background = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"gameover.png"]];
        
        NSInteger highScore = [Global sharedInstance].highestScore;
        NSString *scoreString=nil;
        if (score<=highScore){
        
            scoreString = [NSString stringWithFormat:@"Score: %ld",(long)score];
        }
        else{
            highScore=score;
            [Global sharedInstance].highestScore=score;
            scoreString = [NSString stringWithFormat:@"New High Score: %ld",(long)score];
        }
        CCLabelTTF *scoreLabel = [CCLabelTTF labelWithString:scoreString fontName:@"Arial" fontSize:30];
        scoreLabel.positionType=CCPositionTypeNormalized;
        scoreLabel.position=ccp(0.5f, 0.7f);
        [background addChild:scoreLabel];
        
        NSString *highString = [NSString stringWithFormat:@"Gold Collected: %ld",(long)gold];
        CCLabelTTF *highScoreLabel=[CCLabelTTF labelWithString:highString fontName:@"Arial" fontSize:27];
        highScoreLabel.positionType=CCPositionTypeNormalized;
        highScoreLabel.position=ccp(0.5f, 0.6f);
        [background addChild:highScoreLabel];
        
        
        CCButton *retryButton = [CCButton buttonWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"retry.png"]];
        retryButton.positionType = CCPositionTypeNormalized;
        retryButton.position = ccp(0.55f, 0.3f);
        [retryButton setTarget:self selector:@selector(retryButtonClicked:)];
        [background addChild:retryButton];
        
        CCButton *backButton = [CCButton buttonWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"mainmenu.png"]];
        backButton.positionType = CCPositionTypeNormalized;
        backButton.position = ccp(0.53f, 0.45f);
        [backButton setTarget:self selector:@selector(backButtonClicked:)];
        [background addChild:backButton];
        [self addChild:background];
    }
    return self;
}

-(void)retryButtonClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(restartGame)]) {
        [self.delegate restartGame];
    }
    [self.parent removeChild:self];
}

-(void)backButtonClicked:(id)sender
{
    [[CCDirector sharedDirector]replaceScene:[MainMenu scene]
                              withTransition:[CCTransition transitionMoveInWithDirection:CCTransitionDirectionUp duration:0.5]];
}

@end
