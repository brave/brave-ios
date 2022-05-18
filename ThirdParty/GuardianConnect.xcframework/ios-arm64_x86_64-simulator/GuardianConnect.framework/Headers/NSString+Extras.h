//
//  NSString+Extras.h
//  GuardianConnect
//
//  Created by Kevin Bradley on 5/23/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extras)
- (BOOL)boolValue;
- (NSString *)stringFromBool:(BOOL)boolValue;
@end

NS_ASSUME_NONNULL_END
