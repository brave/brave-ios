//
//  NSObject+Dictionary.h
//  GuardianConnect
//
//  Created by Kevin Bradley on 7/9/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (String)
- (NSString *)JSONRepresentation;
@end

@interface NSObject (Dictionary)
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationExcludingProperties:(NSArray *)excluding;
@end

NS_ASSUME_NONNULL_END
