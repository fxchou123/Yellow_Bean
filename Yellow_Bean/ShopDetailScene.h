//
//  ShopDetailScene.h
//  GameMenus
//
//  Created by Yifan Zhou on 3/21/14.
//  Copyright (c) 2014 Yifan Zhou. All rights reserved.
//

#import "CCScene.h"

@class CCLabelTTF;

@interface ShopDetailScene : CCScene
{
    NSInteger coinsNum;
}

@property (nonatomic, retain) CCLabelTTF *coinLabel;

-(id)initWithTitle:(NSString *)title Coins:(NSInteger)coins;

@end
