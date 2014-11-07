//
//  ShopScene.m
//  GameMenus
//
//  Created by Yifan Zhou on 3/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "ShopScene.h"
#import "cocos2d-ui.h"
#import "ShopDetailScene.h"
#import "MainMenu.h"
#import "Global.h"

@implementation ShopScene

+(ShopScene *) scene{
    return [[ShopScene alloc]init];
}

-(id)init{
    self=[super init];
    if (self){
        CCNodeColor *bgcolor=[[CCNodeColor alloc]initWithColor:[CCColor grayColor]];
        [self addChild:bgcolor];
        CCSprite *bgimage=[CCSprite spriteWithImageNamed:@"bg.png"];
        bgimage.scaleX=self.contentSize.width/bgimage.contentSize.width;
        bgimage.scaleY=self.contentSize.height/bgimage.contentSize.height;
        bgimage.anchorPoint=ccp(0.f,0.f);
        [bgimage setContentSize:self.contentSize];
        [self addChild:bgimage];
        
        CCButton *exitButton=[CCButton buttonWithTitle:@" " spriteFrame:[CCSpriteFrame frameWithImageNamed:@"exitButton.png"]];
        exitButton.scale=0.2;
        [exitButton setTarget:self selector:@selector(exitButtonClicked:)];
        exitButton.positionType=CCPositionTypeNormalized;
        [exitButton setPosition:ccp(0.9f,0.9f)];
        [self addChild:exitButton];
        
        CCSprite *coinbg=[CCSprite spriteWithImageNamed:@"sum.png"];
        coinbg.positionType=CCPositionTypeNormalized;
        coinbg.position=ccp(0.5f, 0.15f);
        coinbg.scale=0.6;
        [self addChild:coinbg];
        
//        CCLabelTTF *shopLabel = [CCLabelTTF labelWithString:@"Shop" fontName:@"HelveticaNeue-Bold" fontSize:18];
//        shopLabel.color=[CCColor blueColor];
//        shopLabel.positionType = CCPositionTypeNormalized;
//        shopLabel.position = ccp(0.5f, 0.9f);
//        [self addChild:shopLabel];
        
        self.coinLabel = [CCLabelTTF labelWithString:@"0" fontName:@"HelveticaNeue-Bold" fontSize:38];
        self.coinLabel.color=[CCColor blueColor];
        self.coinLabel.positionType = CCPositionTypeNormalized;
        self.coinLabel.position = ccp(0.45f, 0.5f);
        [coinbg addChild:self.coinLabel];
        
        CCButton *item1 = [CCButton buttonWithTitle:@"item1" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"magnet.png"]];
        item1.positionType=CCPositionTypeNormalized;
        item1.position=ccp(0.25f, 0.7f);
        item1.scale=0.7;
        [item1 setTarget:self selector:@selector(item1Clicked:)];
        [self addChild:item1];
        
        CCButton *item2 = [CCButton buttonWithTitle:@"item2" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"star.png"]];
        item2.positionType=CCPositionTypeNormalized;
        item2.position=ccp(0.75f, 0.7f);
        item2.scale=0.7;
        [item2 setTarget:self selector:@selector(item2Clicked:)];
        [self addChild:item2];
        
        CCButton *item3 = [CCButton buttonWithTitle:@"item3" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"up.png"]];
        item3.positionType=CCPositionTypeNormalized;
        item3.position=ccp(0.25f, 0.3f);
        item3.scale=0.7;
        [item3 setTarget:self selector:@selector(item3Clicked:)];
        [self addChild:item3];
        
        CCButton *item4 = [CCButton buttonWithTitle:@"item4" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"gift.jpg"]];
        item4.positionType=CCPositionTypeNormalized;
        item4.position=ccp(0.75f, 0.3f);
        item4.scale=1;
        [item4 setTarget:self selector:@selector(item4Clicked:)];
//        [self addChild:item4];
        
        coinsNum = 0;
        
    }
    return self;
}

-(void)onEnter{
    coinsNum = [Global sharedInstance].coinNumber;
    [self updateCoins];
}

-(void)updateCoins{
    [self.coinLabel setString:[NSString stringWithFormat:@"%ld", (long)coinsNum]];
}

-(void)exitButtonClicked:(id)sender{
    [[CCDirector sharedDirector]replaceScene:[MainMenu scene]];
}

-(void)item1Clicked:(id)sender{
    ShopDetailScene *newScene=[[ShopDetailScene alloc]initWithTitle:@"ITME 1" Coins:coinsNum];
    [[CCDirector sharedDirector]pushScene:newScene];
}
-(void)item2Clicked:(id)sender{
    ShopDetailScene *newScene=[[ShopDetailScene alloc]initWithTitle:@"ITEM 2" Coins:coinsNum];
    [[CCDirector sharedDirector]pushScene:newScene];
}
-(void)item3Clicked:(id)sender{
    ShopDetailScene *newScene=[[ShopDetailScene alloc]initWithTitle:@"ITEM 3" Coins:coinsNum];
    [[CCDirector sharedDirector]pushScene:newScene];
}
-(void)item4Clicked:(id)sender{
    ShopDetailScene *newScene=[[ShopDetailScene alloc]initWithTitle:@"ITEM 4" Coins:coinsNum];
    [[CCDirector sharedDirector]pushScene:newScene];
}

@end
