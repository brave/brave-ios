//
//  NSDate+Extras.h
//  Guardian
//
//  Created by Kevin Bradley on 10/1/20.
//  Copyright © 2020 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define D_HOUR        3600

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (Extras)
- (NSDate *)dateBySubtractingDays:(NSInteger)dDays;
- (NSDate *)dateBySubtractingHours:(NSInteger)dHours;
- (NSDate *)dateByAddingDays:(NSInteger)days;
- (NSUInteger)daysUntil;
- (NSUInteger)daysUntilAgainstMidnight;
@end

NS_ASSUME_NONNULL_END
