//
//  PauseNodeDelegate.h
//  Mario
//
//  Created by Lifei Wang on 3/10/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PauseNodeDelegate <NSObject>
-(void)resignPauseMenu;
@optional
-(void)restartCurrentGame;
-(void)restartGameWithFile:(NSString *)fileName;
@end
