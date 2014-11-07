//
//  PauseNode.h
//  Mario
//
//  Created by Lifei Wang on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import "CCNode.h"
#import "PauseNodeDelegate.h"

/**
 once called, create a PauseNode node, add it to the scene.
 self.paused=true;
 set pauseNode.delegate=self;
 
 Then implement resignPauseMenu methon
 (void)resignPauseMenu{
    self.paused=false;
 }
 **/

@interface PauseNode : CCNode

@property (weak) id<PauseNodeDelegate> delegate;
+(PauseNode *)node;

@end
