//
//  GRDIAPDiscountDetails.h
//  GuardianCore
//
//  Created by Kevin Bradley on 7/5/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDIAPDiscountDetails : NSObject

@property NSString *discountSubType;
@property NSString *discountSubTypePretty;
@property NSString *discountIdentifier;
@property NSString *discountPercentage;
@property BOOL isCancelledSubscription;
@property BOOL valid; //make sure all the necessary data is there

- (instancetype)initWithDictionary:(NSDictionary *)iapDiscountInfo;

@end

NS_ASSUME_NONNULL_END
