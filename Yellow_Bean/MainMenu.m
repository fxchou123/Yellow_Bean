//
//  MainMenu.m
//  GameMenus
//
//  Created by Yifan Zhou on 3/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "MainMenu.h"
#import "cocos2d-ui.h"
#import "cocos2d.h"
#import "GameOverNode.h"
#import "UpgradeScene.h"
#import "SceneManager.h"

@implementation MainMenu
+ (MainMenu *) scene{
    return [[MainMenu alloc]init];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        CGSize winSize = self.contentSize;
        CCSprite *background = [CCSprite spriteWithImageNamed:@"main.png"];
        background.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:background];
        
        CCButton *playButton=[CCButton buttonWithTitle:@""
                                           spriteFrame:[CCSpriteFrame frameWithImageNamed:@"start.png"]];
//        CCButton *playButton=[CCButton buttonWithTitle:@"PLAY"
//                                           spriteFrame:[CCSpriteFrame frameWithImageNamed:@"play.png"]
//                                highlightedSpriteFrame:nil
//                                   disabledSpriteFrame:nil];
        playButton.positionType=CCPositionTypeNormalized;
        playButton.position=ccp(0.75f, 0.67f);
        [playButton setScale:1];
        [playButton setTarget:self selector:@selector(playButtonClicked:)];
        [self addChild:playButton];
        
        CCButton *shopButton=[CCButton buttonWithTitle:@""
                                           spriteFrame:[CCSpriteFrame frameWithImageNamed:@"shop.png"]];
        shopButton.positionType=CCPositionTypeNormalized;
        shopButton.position=ccp(0.75f, 0.47f);
        [shopButton setScale:1];
        [shopButton setTarget:self selector:@selector(shopButtonClicked:)];
        [self addChild:shopButton];
        
        CCButton *leaderBoardButton=[CCButton buttonWithTitle:@""
                                           spriteFrame:[CCSpriteFrame frameWithImageNamed:@"highscore.png"]];
        leaderBoardButton.positionType=CCPositionTypeNormalized;
        leaderBoardButton.position=ccp(0.75f, 0.27f);
        [leaderBoardButton setScale:1];
        [leaderBoardButton setTarget:self selector:@selector(leaderBoardButtonClicked:)];
        [self addChild:leaderBoardButton];

    }
    return self;
}

- (void)playButtonClicked:(id)sender
{
    NSLog(@"on play");    
	// This method should return the very first scene to be run when your app starts.
	[[CCDirector sharedDirector]replaceScene:[[SceneManager sharedManager ] loadScene:@"TheGame"]];

}

- (void)leaderBoardButtonClicked:(id)sender
{
    NSLog(@"high score");
}

//-(void)showGameOverNode{
//    GameOverNode *node=[[GameOverNode alloc]initWithScore:12345];
//    node.positionType=CCPositionTypeNormalized;
//    node.position=ccp(0.5f,0.5f);
//    node.delegate=self;
//    [self addChild:node z:3];
//}
//
//-(void)restartGame{
//    NSLog(@"restart");
//}

- (void)shopButtonClicked:(id)sender
{
    UpgradeScene *newScene=[UpgradeScene scene];
    [[CCDirector sharedDirector]replaceScene:newScene withTransition: [CCTransition transitionFadeWithDuration:0.3]];
}

@end
