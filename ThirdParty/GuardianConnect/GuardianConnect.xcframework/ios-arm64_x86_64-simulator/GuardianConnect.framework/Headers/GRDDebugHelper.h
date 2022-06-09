//
//  GRDDebugHelper.h
//  Guardian
//
//  Created by will on 5/28/20.
//  Copyright © 2020 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
// for mach_absolute_time; per https://developer.apple.com/library/archive/qa/qa1398/_index.html
#include <assert.h>
#include <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDDebugHelper : NSObject

@property (nonatomic, retain) NSString *logTitle;
@property BOOL logTimerSet;
@property uint64_t beginTime;

- (instancetype)initWithTitle:(NSString *)title;
- (void)logTimeWithMessage:(NSString *)messageStr;

@end

NS_ASSUME_NONNULL_END
