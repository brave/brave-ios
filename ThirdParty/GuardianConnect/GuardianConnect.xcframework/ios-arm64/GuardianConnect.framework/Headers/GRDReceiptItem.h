//
//  GRDReceiptItem.h
//  GuardianConnect
//
//  Created by Kevin Bradley on 5/23/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDReceiptItem : NSObject

@property NSUInteger quantity; //ex: 1
@property NSDate *expiresDate; //ex: 2021-04-22 21:26:00 Etc/GMT
@property NSString *expiresDatePst; //ex: 2021-04-22 14:26:00 America/Los_Angeles
@property BOOL isInIntroOfferPeriod; //ex: false
@property NSUInteger purchaseDateMs; //ex: 1619123160000
@property NSInteger transactionId; //ex: 1000000804227741
@property BOOL isTrialPeriod; //ex: false
@property NSInteger originalTransactionId; //ex: 1000000718884296
@property NSString *originalPurchaseDatePst; //ex: 2021-04-22 13:26:07 America/Los_Angeles
@property NSString *productId; //ex: grd_pro
@property NSDate *purchaseDate; //ex: 2021-04-22 20:26:00 Etc/GMT
@property NSInteger subscriptionGroupIdentifier; //ex: 20483166
@property NSUInteger originalPurchaseDateMs; //ex: 1619123167000
@property NSInteger webOrderLineItemId; //ex: 1000000061894935
@property NSUInteger expiresDateMs; //ex: 1619126760000
@property NSString *purchaseDatePst; //ex: 2021-04-22 13:26:00 America/Los_Angeles
@property NSDate *originalPurchaseDate; //ex: 2021-04-22 20:26:07 Etc/GMT
@property BOOL isDayPass; //set manually

- (instancetype)initWithDictionary:(NSDictionary *)receiptItem;
- (BOOL)expired; //calculated
- (BOOL)subscriberCredentialExpired; //calculated: whether or not we should expire subscriber credential

@end

NS_ASSUME_NONNULL_END
