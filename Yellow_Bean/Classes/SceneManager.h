//
//  SceneManager.h
//  prototype
//
//  Created by Dian Peng on 2/21/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCScene.h"

@interface SceneManager: NSObject

// ----------------------------------
// Call this function to get a workable
// customized scene object and than
// you can pass it to COCOS2D specific
// framework .
// ----------------------------------

+(SceneManager *)sharedManager;
-(CCScene*) loadScene:(NSString*)sceneFileName;

@end

