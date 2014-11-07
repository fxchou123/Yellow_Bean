//
//  Global.h
//  Mario
//
//  Created by Lifei Wang on 3/22/14.
//  Copyright (c) 2014 Dian Peng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Global : NSObject
+(Global *)sharedInstance;
@property (assign) NSInteger highestScore;
@property (assign) NSInteger totalDistance;
@property (assign) NSInteger totalRun;


@property (assign) NSInteger coinNumber;

@property (assign) CGFloat magnetDuration;
@property (assign) CGFloat invicibleDuration;
@property (assign) CGFloat magnetSize;


@end







