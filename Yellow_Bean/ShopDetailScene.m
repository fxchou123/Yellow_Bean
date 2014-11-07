//
//  ShopDetailScene.m
//  GameMenus
//
//  Created by Yifan Zhou on 3/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "ShopDetailScene.h"
#import "cocos2d-ui.h"
#import "Global.h"
#import "MainMenu.h"

@implementation ShopDetailScene
-(id)initWithTitle:(NSString *)title Coins:(NSInteger)coins{
    self = [super init];
    if (self){
        CCSprite *bgimage=[CCSprite spriteWithImageNamed:@"bg.png"];
        bgimage.scaleX=self.contentSize.width/bgimage.contentSize.width;
        bgimage.scaleY=self.contentSize.height/bgimage.contentSize.height;
        bgimage.anchorPoint=ccp(0.f,0.f);
        [bgimage setContentSize:self.contentSize];
        [self addChild:bgimage z:0];
        
        CCButton *exitButton=[CCButton buttonWithTitle:@" " spriteFrame:[CCSpriteFrame frameWithImageNamed:@"exitButton.png"]];
        exitButton.scale=0.2;
        [exitButton setTarget:self selector:@selector(exitButtonClicked:)];
        exitButton.positionType=CCPositionTypeNormalized;
        [exitButton setPosition:ccp(0.9f,0.9f)];
        [self addChild:exitButton z:1];
        
        CCButton *backButton=[CCButton buttonWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"backButton.jpeg"]];
        [backButton setTarget:self selector:@selector(backButtonClicked:)];
        backButton.positionType=CCPositionTypeNormalized;
        backButton.position=ccp(0.2f, 0.9f);
        backButton.scale=0.5f;
        [self addChild:backButton];
        
        CCLabelTTF *shopLabel = [CCLabelTTF labelWithString:title fontName:@"HelveticaNeue-Bold" fontSize:18];
        shopLabel.color=[CCColor blueColor];
        shopLabel.positionType = CCPositionTypeNormalized;
        shopLabel.position = ccp(0.5f, 0.9f);
        [self addChild:shopLabel];
        
        CCSprite *coinbg=[CCSprite spriteWithImageNamed:@"sum.png"];
        coinbg.positionType=CCPositionTypeNormalized;
        coinbg.position=ccp(0.5f, 0.15f);
        coinbg.scale=0.6;
        [self addChild:coinbg];
        
        coinsNum=coins;
        NSString *coinString=[NSString stringWithFormat:@"%ld", (long)coins];
        self.coinLabel = [CCLabelTTF labelWithString:coinString fontName:@"HelveticaNeue-Bold" fontSize:38];
        self.coinLabel.color=[CCColor blueColor];
        self.coinLabel.positionType = CCPositionTypeNormalized;
        self.coinLabel.position = ccp(0.45f, 0.5f);
        [coinbg addChild:self.coinLabel];
        
        CCButton *item1 = [CCButton buttonWithTitle:@"1000" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"gift.jpg"]];
        item1.positionType=CCPositionTypeNormalized;
        item1.position=ccp(0.5f, 0.5f);
        item1.scale=0.15;
        [item1 setTarget:self selector:@selector(item1Clicked:)];
        [self addChild:item1];
    }
    return self;
}

-(void)item1Clicked:(CCButton *)sender
{
    NSInteger price = [sender.title integerValue];
    if (coinsNum<price){
        [self showNotEnoughCoinsAlert];
    }
    else{
        coinsNum-=price;
        [self updateCoins];
    }
}

-(void)updateCoins{
    [Global sharedInstance].coinNumber=coinsNum;
    [self.coinLabel setString:[NSString stringWithFormat:@"%ld", (long)coinsNum]];
}

-(void)showNotEnoughCoinsAlert
{
    UIAlertView* alert= [[UIAlertView alloc] initWithTitle: @"Not Enough Coins"
                                                   message: nil
                                                  delegate: self
                                         cancelButtonTitle: @"OK"
                                         otherButtonTitles: NULL];
    [alert show];
}

-(void)exitButtonClicked:(id)sender{
    [[CCDirector sharedDirector]replaceScene:[MainMenu scene]];
}

-(void)backButtonClicked:(id)sender{
    [[CCDirector sharedDirector]popScene];
}

@end
