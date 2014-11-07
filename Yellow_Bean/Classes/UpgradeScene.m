//
//  UpgradeScene.m
//  GameMenus
//
//  Created by Lifei Wang on 4/5/14.
//  Copyright (c) 2014 Lifei Wang. All rights reserved.
//

#import "UpgradeScene.h"
#import "MainMenu.h"
#import "Global.h"
#import "cocos2d-ui.h"

@implementation UpgradeScene
{
    CCSprite *spriteMagDur;
    CCSprite *spriteMagSize;
    CCSprite *spriteInviDur;
    CCLabelTTF *coinLabel;
}

+(UpgradeScene *)scene{
    return [[UpgradeScene alloc]init];
}

-(id)init{
    self = [super init];
    if (self){
        
        self.coinNumber = [Global sharedInstance].coinNumber;
        
        CGSize winSize = self.contentSize;
        CCSprite *background = [CCSprite spriteWithImageNamed:@"shopBackground.png"];
        background.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:background];
        
        CCButton *backButton = [CCButton buttonWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"exitButton.png"]];
        backButton.positionType = CCPositionTypeNormalized;
        backButton.scale=0.2f;
        backButton.position = ccp(0.83f, 0.85f);
        [backButton setTarget:self selector:@selector(backButtonClicked:)];
        [self addChild:backButton];
        
        NSString *coinStr = [NSString stringWithFormat:@"%ld",(long)[Global sharedInstance].coinNumber];
        coinLabel = [CCLabelTTF labelWithString:coinStr fontName:@"Arial" fontSize:22];
        [coinLabel setColor:[CCColor blueColor]];
        coinLabel.positionType = CCPositionTypeNormalized;
        coinLabel.position = ccp(0.22f, 0.29f);
        [self addChild:coinLabel];
        
        spriteMagDur = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"hp.png"]];
        spriteMagDur.position=ccp(0.50*winSize.width, 0.52*winSize.height);
        spriteMagDur.anchorPoint=CGPointMake(0, 0);
        spriteMagDur.scaleX = [Global sharedInstance].magnetDuration+0.1;
        [self addChild:spriteMagDur];
        
        spriteMagSize = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"hp.png"]];
        spriteMagSize.position=ccp(512, 0.37*winSize.height);
        spriteMagSize.anchorPoint=CGPointMake(0, 0);
        NSLog(@"%f",[Global sharedInstance].magnetSize);
        spriteMagSize.scaleX = [Global sharedInstance].magnetSize+0.1;
        [self addChild:spriteMagSize];
        
        spriteInviDur = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"hp.png"]];
        spriteInviDur.position=ccp(0.50*winSize.width, 0.23*winSize.height);
        spriteInviDur.anchorPoint=CGPointMake(0, 0);
        spriteInviDur.scaleX = [Global sharedInstance].invicibleDuration+0.1;
        [self addChild:spriteInviDur];
        
//        CCSprite *label1 = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"magnetDuration.png"]];
//        label1.position=ccp(0.35*winSize.width, 0.50*winSize.height);
//        label1.anchorPoint=CGPointMake(0, 0);
//        [self addChild:label1];
//        
//        CCSprite *label2 = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"magnetSize.png"]];
//        label2.position=ccp(0.35*winSize.width, 0.35*winSize.height);
//        label2.anchorPoint=CGPointMake(0, 0);
//        [self addChild:label2];
//        
//        CCSprite *label3 = [CCSprite spriteWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"invisible.png"]];
//        label3.position=ccp(0.35*winSize.width, 0.2*winSize.height);
//        label3.anchorPoint=CGPointMake(0, 0);
//        label3.scale = 0.2f;
//        [self addChild:label3];
        
        CCButton *upButton1=[CCButton buttonWithTitle:@""
                                           spriteFrame:[CCSpriteFrame frameWithImageNamed:@"money.png"]];
        upButton1.positionType=CCPositionTypeNormalized;
        upButton1.position=ccp(0.78f, 0.53f);
        upButton1.anchorPoint=CGPointMake(0, 0);
        [upButton1 setTarget:self selector:@selector(upButton1Clicked:)];
        [self addChild:upButton1];
        
        CCButton *upButton2=[CCButton buttonWithTitle:@""
                                          spriteFrame:[CCSpriteFrame frameWithImageNamed:@"money.png"]];
        upButton2.positionType=CCPositionTypeNormalized;
        upButton2.position=ccp(0.78f, 0.38f);
        upButton2.anchorPoint=CGPointMake(0, 0);
        [upButton2 setTarget:self selector:@selector(upButton2Clicked:)];
        [self addChild:upButton2];
        
        CCButton *upButton3=[CCButton buttonWithTitle:@""
                                          spriteFrame:[CCSpriteFrame frameWithImageNamed:@"money.png"]];
        upButton3.positionType=CCPositionTypeNormalized;
        upButton3.position=ccp(0.78f, 0.24f);
        upButton3.anchorPoint=CGPointMake(0, 0);
        [upButton3 setTarget:self selector:@selector(upButton3Clicked:)];
        [self addChild:upButton3];
    }
    return self;
}

-(void)backButtonClicked:(id)sender{
    [[CCDirector sharedDirector]replaceScene:[MainMenu scene]];
}

-(void)upButton1Clicked:(id)sender{
    if (self.coinNumber < 1000){
        [self showNotEnoughCoinsAlert];
        return;
    }
    CGFloat curx = spriteMagDur.scaleX;
    if (curx >=1){
        return;
    }
    
    if (curx<0.81){
        [spriteMagDur runAction:[CCActionScaleTo actionWithDuration:0.5 scaleX:curx+0.15 scaleY:1]];
        [Global sharedInstance].magnetDuration = curx + 0.05f;
    }
    else{
        [spriteMagDur runAction:[CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1]];
        [Global sharedInstance].magnetDuration = 0.9f;
    }
    self.coinNumber -= 1000;
    [Global sharedInstance].coinNumber -= 1000;
    
    [self reloadCoinLabel];
}

-(void)upButton2Clicked:(id)sender{
    if (self.coinNumber < 1000){
        [self showNotEnoughCoinsAlert];
        return;
    }
    CGFloat curx = spriteMagSize.scaleX;
    if (curx >=1){
        return;
    }
    if (curx<0.86){
        [spriteMagSize runAction:[CCActionScaleTo actionWithDuration:0.5 scaleX:curx+0.1 scaleY:1]];
        [Global sharedInstance].magnetSize = curx;
    }
    else{
        [spriteMagSize runAction:[CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1]];
        [Global sharedInstance].magnetSize = 0.9f;
    }
    self.coinNumber -= 1000;
    [Global sharedInstance].coinNumber -= 1000;
    
    [self reloadCoinLabel];
}

-(void)upButton3Clicked:(id)sender{
    if (self.coinNumber < 1000){
        [self showNotEnoughCoinsAlert];
        return;
    }
    CGFloat curx = spriteInviDur.scaleX;
    if (curx >=1){
        return;
    }
    if (curx<0.86){
        [spriteInviDur runAction:[CCActionScaleTo actionWithDuration:0.5 scaleX:curx+0.13 scaleY:1]];
        [Global sharedInstance].invicibleDuration = curx + 0.03f;
    }
    else{
        [spriteInviDur runAction:[CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1]];
        [Global sharedInstance].invicibleDuration = 0.9;
    }
    self.coinNumber -= 1000;
    [Global sharedInstance].coinNumber -= 1000;
    
    [self reloadCoinLabel];
}

-(void)reloadCoinLabel
{
    NSString *coinstr = [NSString stringWithFormat:@"%ld",(long)self.coinNumber];
    coinLabel.string = coinstr;
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

@end
