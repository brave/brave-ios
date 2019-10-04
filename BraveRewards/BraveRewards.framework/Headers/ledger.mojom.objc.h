/* Copyright (c) 2019 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif



typedef NS_ENUM(NSInteger, BATExcludeFilter) {
  BATExcludeFilterFilterAll = -1,
  BATExcludeFilterFilterDefault = 0,
  BATExcludeFilterFilterExcluded = 1,
  BATExcludeFilterFilterIncluded = 2,
  BATExcludeFilterFilterAllExceptExcluded = 3,
} NS_SWIFT_NAME(ExcludeFilter);


typedef NS_ENUM(NSInteger, BATContributionRetry) {
  BATContributionRetryStepNo = 0,
  BATContributionRetryStepReconcile = 1,
  BATContributionRetryStepCurrent = 2,
  BATContributionRetryStepPayload = 3,
  BATContributionRetryStepRegister = 4,
  BATContributionRetryStepViewing = 5,
  BATContributionRetryStepWinners = 6,
  BATContributionRetryStepPrepare = 7,
  BATContributionRetryStepProof = 8,
  BATContributionRetryStepVote = 9,
  BATContributionRetryStepFinal = 10,
} NS_SWIFT_NAME(ContributionRetry);


typedef NS_ENUM(NSInteger, BATResult) {
  BATResultLedgerOk = 0,
  BATResultLedgerError = 1,
  BATResultNoPublisherState = 2,
  BATResultNoLedgerState = 3,
  BATResultInvalidPublisherState = 4,
  BATResultInvalidLedgerState = 5,
  BATResultCaptchaFailed = 6,
  BATResultNoPublisherList = 7,
  BATResultTooManyResults = 8,
  BATResultNotFound = 9,
  BATResultRegistrationVerificationFailed = 10,
  BATResultBadRegistrationResponse = 11,
  BATResultWalletCreated = 12,
  BATResultGrantNotFound = 13,
  BATResultAcTableEmpty = 14,
  BATResultNotEnoughFunds = 15,
  BATResultTipError = 16,
  BATResultCorruptedWallet = 17,
  BATResultGrantAlreadyClaimed = 18,
  BATResultContributionAmountTooLow = 19,
  BATResultVerifiedPublisher = 20,
  BATResultPendingPublisherRemoved = 21,
  BATResultPendingNotEnoughFunds = 22,
  BATResultRecurringTableEmpty = 23,
  BATResultExpiredToken = 24,
  BATResultBatNotAllowed = 25,
  BATResultAlreadyExists = 26,
} NS_SWIFT_NAME(Result);


typedef NS_ENUM(NSInteger, BATPublisherStatus) {
  BATPublisherStatusNotVerified = 0,
  BATPublisherStatusConnected = 1,
  BATPublisherStatusVerified = 2,
} NS_SWIFT_NAME(PublisherStatus);


typedef NS_ENUM(NSInteger, BATRewardsCategory) {
  BATRewardsCategoryAutoContribute = 2,
  BATRewardsCategoryOneTimeTip = 8,
  BATRewardsCategoryRecurringTip = 16,
} NS_SWIFT_NAME(RewardsCategory);



@class BATContributionInfo, BATPublisherInfo, BATPublisherBanner, BATPendingContribution, BATPendingContributionInfo, BATVisitData, BATGrant, BATWalletProperties, BATBalance, BATAutoContributeProps, BATMediaEventInfo, BATExternalWallet, BATBalanceReportInfo, BATActivityInfoFilterOrderPair, BATActivityInfoFilter, BATReconcileInfo, BATRewardsInternalsInfo, BATServerPublisherInfo, BATTransferFee;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ContributionInfo)
@interface BATContributionInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * publisher;
@property (nonatomic) double value;
@property (nonatomic) uint64_t date;
@end

NS_SWIFT_NAME(PublisherInfo)
@interface BATPublisherInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * id;
@property (nonatomic) uint64_t duration;
@property (nonatomic) double score;
@property (nonatomic) uint32_t visits;
@property (nonatomic) uint32_t percent;
@property (nonatomic) double weight;
@property (nonatomic) int32_t excluded;
@property (nonatomic) int32_t category;
@property (nonatomic) uint64_t reconcileStamp;
@property (nonatomic) BATPublisherStatus status;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, copy) NSString * provider;
@property (nonatomic, copy) NSString * faviconUrl;
@property (nonatomic, copy) NSArray<BATContributionInfo *> * contributions;
@end

NS_SWIFT_NAME(PublisherBanner)
@interface BATPublisherBanner : NSObject <NSCopying>
@property (nonatomic, copy) NSString * publisherKey;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * desc;
@property (nonatomic, copy) NSString * background;
@property (nonatomic, copy) NSString * logo;
@property (nonatomic, copy) NSArray<NSNumber *> * amounts;
@property (nonatomic, copy) NSString * provider;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> * links;
@property (nonatomic) BATPublisherStatus status;
@end

NS_SWIFT_NAME(PendingContribution)
@interface BATPendingContribution : NSObject <NSCopying>
@property (nonatomic, copy) NSString * publisherKey;
@property (nonatomic) double amount;
@property (nonatomic) uint64_t addedDate;
@property (nonatomic, copy) NSString * viewingId;
@property (nonatomic) BATRewardsCategory category;
@end

NS_SWIFT_NAME(PendingContributionInfo)
@interface BATPendingContributionInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * publisherKey;
@property (nonatomic) BATRewardsCategory category;
@property (nonatomic) BATPublisherStatus status;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, copy) NSString * provider;
@property (nonatomic, copy) NSString * faviconUrl;
@property (nonatomic) double amount;
@property (nonatomic) uint64_t addedDate;
@property (nonatomic, copy) NSString * viewingId;
@property (nonatomic) uint64_t expirationDate;
@end

NS_SWIFT_NAME(VisitData)
@interface BATVisitData : NSObject <NSCopying>
@property (nonatomic, copy) NSString * tld;
@property (nonatomic, copy) NSString * domain;
@property (nonatomic, copy) NSString * path;
@property (nonatomic) uint32_t tabId;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, copy) NSString * provider;
@property (nonatomic, copy) NSString * faviconUrl;
@end

NS_SWIFT_NAME(Grant)
@interface BATGrant : NSObject <NSCopying>
@property (nonatomic, copy) NSString * altcurrency;
@property (nonatomic, copy) NSString * probi;
@property (nonatomic, copy) NSString * promotionId;
@property (nonatomic) uint64_t expiryTime;
@property (nonatomic, copy) NSString * type;
@end

NS_SWIFT_NAME(WalletProperties)
@interface BATWalletProperties : NSObject <NSCopying>
@property (nonatomic) double feeAmount;
@property (nonatomic, copy) NSArray<NSNumber *> * parametersChoices;
@property (nonatomic, copy) NSArray<BATGrant *> * grants;
@end

NS_SWIFT_NAME(Balance)
@interface BATBalance : NSObject <NSCopying>
@property (nonatomic) double total;
@property (nonatomic, copy) NSString * userFunds;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> * rates;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> * wallets;
@end

NS_SWIFT_NAME(AutoContributeProps)
@interface BATAutoContributeProps : NSObject <NSCopying>
@property (nonatomic) bool enabledContribute;
@property (nonatomic) uint64_t contributionMinTime;
@property (nonatomic) int32_t contributionMinVisits;
@property (nonatomic) bool contributionNonVerified;
@property (nonatomic) bool contributionVideos;
@property (nonatomic) uint64_t reconcileStamp;
@end

NS_SWIFT_NAME(MediaEventInfo)
@interface BATMediaEventInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * event;
@property (nonatomic, copy) NSString * time;
@property (nonatomic, copy) NSString * status;
@end

NS_SWIFT_NAME(ExternalWallet)
@interface BATExternalWallet : NSObject <NSCopying>
@property (nonatomic, copy) NSString * token;
@property (nonatomic, copy) NSString * address;
@property (nonatomic) uint32_t status;
@property (nonatomic, copy) NSString * verifyUrl;
@property (nonatomic, copy) NSString * addUrl;
@property (nonatomic, copy) NSString * withdrawUrl;
@property (nonatomic, copy) NSString * oneTimeString;
@property (nonatomic, copy) NSString * userName;
@property (nonatomic, copy) NSString * accountUrl;
@property (nonatomic) bool transferred;
@end

NS_SWIFT_NAME(BalanceReportInfo)
@interface BATBalanceReportInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * openingBalance;
@property (nonatomic, copy) NSString * closingBalance;
@property (nonatomic, copy) NSString * deposits;
@property (nonatomic, copy) NSString * grants;
@property (nonatomic, copy) NSString * earningFromAds;
@property (nonatomic, copy) NSString * autoContribute;
@property (nonatomic, copy) NSString * recurringDonation;
@property (nonatomic, copy) NSString * oneTimeDonation;
@property (nonatomic, copy) NSString * total;
@end

NS_SWIFT_NAME(ActivityInfoFilterOrderPair)
@interface BATActivityInfoFilterOrderPair : NSObject <NSCopying>
@property (nonatomic, copy) NSString * propertyName;
@property (nonatomic) bool ascending;
@end

NS_SWIFT_NAME(ActivityInfoFilter)
@interface BATActivityInfoFilter : NSObject <NSCopying>
@property (nonatomic, copy) NSString * id;
@property (nonatomic) BATExcludeFilter excluded;
@property (nonatomic) uint32_t percent;
@property (nonatomic, copy) NSArray<BATActivityInfoFilterOrderPair *> * orderBy;
@property (nonatomic) uint64_t minDuration;
@property (nonatomic) uint64_t reconcileStamp;
@property (nonatomic) bool nonVerified;
@property (nonatomic) uint32_t minVisits;
@end

NS_SWIFT_NAME(ReconcileInfo)
@interface BATReconcileInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * viewingId;
@property (nonatomic, copy) NSString * amount;
@property (nonatomic) BATContributionRetry retryStep;
@property (nonatomic) int32_t retryLevel;
@end

NS_SWIFT_NAME(RewardsInternalsInfo)
@interface BATRewardsInternalsInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * paymentId;
@property (nonatomic) bool isKeyInfoSeedValid;
@property (nonatomic, copy) NSString * personaId;
@property (nonatomic, copy) NSString * userId;
@property (nonatomic) uint64_t bootStamp;
@property (nonatomic, copy) NSDictionary<NSString *, BATReconcileInfo *> * currentReconciles;
@end

NS_SWIFT_NAME(ServerPublisherInfo)
@interface BATServerPublisherInfo : NSObject <NSCopying>
@property (nonatomic, copy) NSString * publisherKey;
@property (nonatomic) BATPublisherStatus status;
@property (nonatomic) bool excluded;
@property (nonatomic, copy) NSString * address;
@property (nonatomic, copy, nullable) BATPublisherBanner * banner;
@end

NS_SWIFT_NAME(TransferFee)
@interface BATTransferFee : NSObject <NSCopying>
@property (nonatomic, copy) NSString * id;
@property (nonatomic) double amount;
@property (nonatomic) uint64_t executionTimestamp;
@property (nonatomic) uint32_t executionId;
@end

NS_ASSUME_NONNULL_END