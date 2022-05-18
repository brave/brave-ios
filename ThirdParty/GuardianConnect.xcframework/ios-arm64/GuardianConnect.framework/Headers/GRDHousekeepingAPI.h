//
//  GRDHousekeepingAPI.h
//  Guardian
//
//  Created by Constantin Jacob on 18.11.19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeviceCheck/DeviceCheck.h>
#import <GuardianConnect/GRDVPNHelper.h>
#import <GuardianConnect/GRDReceiptItem.h>

#define kHousekeepingAPIBase @"https://connect-api.guardianapp.com"

NS_ASSUME_NONNULL_BEGIN

@interface GRDHousekeepingAPI : NSObject

/// Validation Method used to obtain a signed JWT from housekeeping
typedef NS_ENUM(NSInteger, GRDHousekeepingValidationMethod) {
    ValidationMethodInvalid = -1,
    ValidationMethodAppStoreReceipt,
    ValidationmethodPEToken
};

/// ValidationMethod to use for the request to housekeeping
/// Currently not used for anything since the validation method is passed to the method directly as a parameter
@property GRDHousekeepingValidationMethod validationMethod;

/// Digital App Store Receipt used to obtain a signed JWT from housekeeping
/// Currently not used since the App Store Receipt is encoded and sent to housekeeping directly from the method itself. Meant as debugging/manual override option in the future
@property NSString *appStoreReceipt;

/// PET or PE Token == Password Equivalent Token
/// Currently only used by Guardian for subscriptions & purchases conducted via the web
@property NSString *peToken;

/// GuardianConnect app key used to authenticate API actions alongside the registered bundle id
@property (nonatomic, strong) NSString *_Nullable appKey;

/// GuardianConnect app bundle id used to authenticate API actions alongside the app key
@property (nonatomic, strong) NSString *_Nullable appBundleId;

- (instancetype)initWithAppKey:(NSString *_Nonnull)appKey andAppBundleId:(NSString *_Nonnull)appBundleId;

/// endpoint: /api/v1/users/info-for-pe-token
/// @param token password equivalent token for which to request information for
/// @param completion completion block returning NSDictionary with information for the requested token, an error message and a bool indicating success of the request
- (void)requestPETokenInformationForToken:(NSString *)token completion:(void (^)(NSDictionary * _Nullable peTokenInfo, NSString * _Nullable errorMessage, BOOL success))completion;

/// endpoint: /api/v1.2/verify-receipt
/// Used to verify the current subscription status of a user if they subscribed through an in-app purchase. Returns an array containing only valid subscriptions / purchases
/// @param encodedReceipt Base64 encoded AppStore receipt. If the value is NULL, [NSBundle mainBundle] appStoreReceiptURL] will be used to grab the system App Store receipt
/// @param bundleId The apps bundle id used to identify the shared secret server side to decrypt the receipt data
/// @param completion completion block returning array only containing valid subscriptions / purchases, success indicator and a error message containing actionable information for the user if the request failed
- (void)verifyReceipt:(NSString * _Nullable)encodedReceipt bundleId:(NSString * _Nonnull)bundleId completion:(void (^)(NSArray <GRDReceiptItem *>* _Nullable validLineItems, BOOL success, NSString * _Nullable errorMessage))completion;

/// endpoint: /api/v1/subscriber-credential/create
/// Used to obtain a signed JWT from housekeeping for later authentication with zoe-agent
/// @param validationMethod set to determine how to authenticate with housekeeping
/// @param completion completion block returning a signed JWT, indicating request success and a user actionable error message if the request failed
- (void)createSubscriberCredentialForBundleId:(NSString *)bundleId withValidationMethod:(GRDHousekeepingValidationMethod)validationMethod completion:(void (^)(NSString * _Nullable subscriberCredential, BOOL success, NSString * _Nullable errorMessage))completion;

/// endpoint: /api/v1/servers/timezones-for-regions
/// Used to obtain all known timezones
/// @param completion completion block returning an array with all timezones, indicating request success, and the response status code
- (void)requestTimeZonesForRegionsWithCompletion:(void (^)(NSArray  * _Nullable timeZones, BOOL success, NSUInteger responseStatusCode))completion;

/// endpoint: /api/v1/servers/hostnames-for-region
/// @param region the selected region for which hostnames should be returned
/// @param completion completion block returning an array of servers and indicating request success
- (void)requestServersForRegion:(NSString *)region paidServers:(BOOL)paidServers featureEnvironment:(GRDServerFeatureEnvironment)featureEnvironment betaCapableServers:(BOOL)betaCapable completion:(void (^)(NSArray *servers, BOOL success))completion;

/// endpint: /api/v1/servers/all-hostnames
/// @param completion completion block returning an array of all hostnames and indicating request success
- (void)requestAllHostnamesWithCompletion:(void (^)(NSArray * _Nullable allServers, BOOL success))completion;

/// endpoint: /api/v1/servers/all-server-regions
/// Used to retrieve all available Server Regions from housekeeping to allow users to override the selected Server Region
/// @param completion completion block returning an array contain a dictionary for each server region and a BOOL indicating a successful API call
- (void)requestAllServerRegions:(void (^)(NSArray <NSDictionary *> * _Nullable items, BOOL success))completion;


- (void)generateSignupTokenForIAPPro:(void (^)(NSDictionary * _Nullable userInfo, BOOL success, NSString * _Nullable errorMessage))completion;

- (void)getDeviceToken:(void (^)(id  _Nullable token, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
