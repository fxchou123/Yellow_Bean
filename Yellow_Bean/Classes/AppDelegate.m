//
//  AppDelegate.m
//  prototype
//
//  Created by Yifan Zhou on 2/17/14.
//  Copyright Yifan Zhou 2014. All rights reserved.
//
// -----------------------------------------------------------------------

#import "AppDelegate.h"
#import "GameMapFile.h"
#import "Misc.h"
#import "SceneManager.h"
#import "chipmunk.h"
#import "MainMenu.h"
#import "Global.h"

@implementation AppDelegate
{
  SceneManager* _scene_mgr;
}
// 
-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// This is the only app delegate method you need to implement when inheriting from CCAppDelegate.
	// This method is a good place to add one time setup code that only runs when your app is first launched.
	
	// Setup Cocos2D with reasonable defaults for everything.
	// There are a number of simple options you can change.
	// If you want more flexibility, you can configure Cocos2D yourself instead of calling setupCocos2dWithOptions:.
	[self setupCocos2dWithOptions:@{
		// Show the FPS and draw call label.
		CCSetupShowDebugStats: @(YES),
		// More examples of options you might want to fiddle with:
		// (See CCAppDelegate.h for more information)
		
		// Use a 16 bit color buffer: 
//		CCSetupPixelFormat: kEAGLColorFormatRGB565,
		// Use a simplified coordinate system that is shared across devices.
//		CCSetupScreenMode: CCScreenModeFixed,
		// Run in portrait mode.
//		CCSetupScreenOrientation: CCScreenOrientationPortrait,
		// Run at a reduced framerate.
//		CCSetupAnimationInterval: @(1.0/30.0),
		// Run the fixed timestep extra fast.
//		CCSetupFixedUpdateInterval: @(1.0/180.0),
		// Make iPad's act like they run at a 2x content scale. (iPad retina 4x)
//		CCSetupTabletScale2X: @(YES),
	}];
    
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults]dictionaryForKey:@"GameStats"];
    [Global sharedInstance].highestScore = [[dic objectForKey:@"HighestScore"]integerValue];
    [Global sharedInstance].coinNumber = [[dic objectForKey:@"CoinNumber"]integerValue];
    [Global sharedInstance].magnetDuration = [[dic objectForKey:@"MagnetDuration"]doubleValue];
    [Global sharedInstance].magnetSize = [[dic objectForKey:@"MagnetSize"]doubleValue];
    [Global sharedInstance].invicibleDuration = [[dic objectForKey:@"InvicibleDuration"]doubleValue];
    [Global sharedInstance].totalDistance = [[dic objectForKey:@"TotalDistance"]integerValue];
    [Global sharedInstance].totalRun = [[dic objectForKey:@"TotalRun"]integerValue];
    
	
	return YES;
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
    Global *global = [Global sharedInstance];
    NSString *highScoreStr = [NSString stringWithFormat:@"%ld", (long)global.highestScore];
    NSString *coinNumStr = [NSString stringWithFormat:@"%ld", (long)global.coinNumber];
    NSString *magnetSizeStr = [NSString stringWithFormat:@"%f", global.magnetSize];
    NSString *magnetDurStr = [NSString stringWithFormat:@"%f", global.magnetDuration];
    NSString *inviDurStr = [NSString stringWithFormat:@"%f", global.invicibleDuration];
    NSString *totalRunStr = [NSString stringWithFormat:@"%ld", (long)global.totalRun];
    NSString *totalDistanceStr = [NSString stringWithFormat:@"%ld", (long)global.totalDistance];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithCapacity:5];
    [dic setObject:highScoreStr forKey:@"HighestScore"];
    [dic setObject:coinNumStr forKey:@"CoinNumber"];
    [dic setObject:magnetDurStr forKey:@"MagnetDuration"];
    [dic setObject:magnetSizeStr forKey:@"MagnetSize"];
    [dic setObject:inviDurStr forKey:@"InvicibleDuration"];
    [dic setObject:totalRunStr forKey:@"TotalRun"];
    [dic setObject:totalDistanceStr forKey:@"TotalDistance"];
    
    [[NSUserDefaults standardUserDefaults]setObject:dic forKey:@"GameStats"];
}


-(CCScene *)startScene
{
    return [MainMenu scene];
}

@end































