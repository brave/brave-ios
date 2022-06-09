//
//  GRDSubscriptionManager.h
//  Guardian
//
//  Created by Constantin Jacob on 12.04.19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import <GuardianConnect/GRDVPNHelper.h>
#import <GuardianConnect/GRDReceiptItem.h>
#import <GuardianConnect/GRDIAPDiscountDetails.h>
#import <GuardianConnect/GRDSubscriberCredential.h>

//missing, add properly later
#define kUserNotEligibleForFreeTrial    @"guardianUserNotEligibleForTrial"
#define kNotificationSubscriptionActive @"notifSubscriptionActive"
#define kNotficationPurchaseInAppStore @"notifPurchaseOriginatedAppStore"
#define kNotificationRestoreSubscriptionFinished @"notifRestoreSubFinished"
#define kNotificationRestoreSubscriptionError @"notifRestoreSubError"
#define kNotificationFreeTrialEligibilityChanged @"notifFreeTrialEligibilityChanged"
#define kNotificationSubscriptionInactive @"notifSubscriptionInactive"

NS_ASSUME_NONNULL_BEGIN

@protocol GRDSubscriptionDelegate;

@interface GRDSubscriptionManager : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>
/// Delegate that handles callbacks for receipt validation handling
@property (nonatomic, weak) id <GRDSubscriptionDelegate> delegate;

/// API Secret used to identify the Apple provided shared secret to verify in-app purchase receipts
/// The API Secret is currently still unused
@property NSString *apiSecret;

/// Bundle Id identifying the Guardian partner app to verify in-app purchase receipts
@property NSString *bundleId;

/// Add to this array if you want any product id's exempt from receipt validation (non-app store purchases)
@property NSArray <NSString *> *ignoredProductIds;

/// Keeps track of the response from SKProductRequest
@property NSArray <SKProduct *> *sortedProductOfferings;

/// Keeps track of the locale for the SKProducts
@property NSLocale *subscriptionLocale;


/// Always use the sharedManager singleton when using this class.
+ (instancetype)sharedManager;

/// Used to process & verify receipt data for a valid subscription, plan update or subscription expiration, communicates via GRDSubscriptionDelegate callbacks
- (void)verifyReceipt;

/// Used to process & verify receipt data for a valid subscription, plan update or subscription expiration, communicates via GRDSubscriptionDelegate callbacks
- (void)verifyReceipt:(NSData * _Nullable)receipt filtered:(BOOL)filtered;

/// Used to determine if the current user has an active subscription
+ (BOOL)isPayingUser;

/// Used to set whether our current user is actively a paying customer
/// @param isPaying BOOL value that tracks whether or not the current user is a paying customer.
+ (void)setIsPayingUser:(BOOL)isPaying;

@end


/// Delegate defining the method callback structure once the purchase is initiated via StoreKit
@protocol GRDSubscriptionDelegate <NSObject>

/// Informs the delegate that the paymnet was successfully processed and returns the latest valid receipt line item
- (void)purchasedSuccessfully:(GRDReceiptItem *)receiptItem;

/// Informs the delegate that the receipt is invalid and could not be validated by Apple's servers
- (void)receiptInvalid;

/// Informs the delegate that the payment was marked as deferred for an unknown reason and has not yet been validated
- (void)purchaseDeferred;

/// Informs the delegate that the payment failed to process and returns the error
- (void)purchaseFailedWithError:(NSError *)storeKitError;


@optional
/// Informs the delegate that the receipt is about to be verified to process the payment
/// Useful to update the interface to relay information to the user
- (void)validatingReceipt;

/// Informs the delegate that hte subscription was successfully restored and returns the latest valid receipt line item
- (void)purchaseRestored:(GRDReceiptItem *)receiptItem;


// Deprecated functions

/// Informs the delegate that the paymnet was successfully processed
/// Deprecated, use - purchasedSuccessfully:(GRDReceiptItem *)receiptItem instead
- (void)subscribedSuccessfully;

/// Informs the delegate that the subscription was successfully restored
/// Deprecated, use - purchaseRestored:(GRDReceiptItem *)receiptItem instead
- (void)subscriptionRestored; // deprecated

/// Informs the delegate that the payment failed
/// Deprecated, use - purchaseFailedWithError:(NSError *)storeKitError instead
- (void)subscriptionFailed; // deprecated

@end

NS_ASSUME_NONNULL_END
