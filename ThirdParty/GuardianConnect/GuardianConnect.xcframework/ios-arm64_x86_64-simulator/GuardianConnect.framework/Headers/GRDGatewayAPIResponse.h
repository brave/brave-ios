//
//  GRDGatewayAPIResponse.h
//  Guardian
//
//  Created by will on 4/29/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDGatewayAPIResponse : NSObject

// error / error-type
typedef NS_ENUM(NSInteger, GRDGatewayAPIResponseStatus) {
    GRDGatewayAPISuccess,
    GRDGatewayAPIServerOK,
    GRDGatewayAPIServerNotOK,
    GRDGatewayAPIReceiptNeedsSandboxEnv, // status == 21007
    GRDGatewayAPIReceiptNeedsProductionEnv, // status == 21008
    GRDGatewayAPIReceiptValidateReqError, // 'iap-server-error' / 'iap-post-request-failed' [NOT IMPLIMENTED IN CODE YET]
    GRDGatewayAPIReceiptValidateResponseError, // 'iap-server-error' / prefix: 'bad-http-code-' [NOT IMPLIMENTED IN CODE YET]
    GRDGatewayAPIReceiptJsonInvalid, // 'malformed-data' / 'json-parser-error' [NOT IMPLIMENTED IN CODE YET]
    GRDGatewayAPIReceiptJsonNotStringDict, // 'malformed-data' / 'json-data-not-string-dict' [NOT IMPLIMENTED IN CODE YET]
    GRDGatewayAPIReceiptJsonDataEmpty, // 'malformed-data' / 'json-data-empty' [NOT IMPLIMENTED IN CODE YET]
    GRDGatewayAPIPushTokenMissing, // 'missing-param' / 'push-token'
    GRDGatewayAPIUsernameMissing, // 'missing-param' / 'username'
    GRDGatewayAPIPasswordMissing, // 'missing-param' / 'password'
    GRDGatewayAPIReceiptDataMissing, // 'missing-param' / 'receipt-data'
    GRDGatewayAPIAuthenticationError, // 'auth-error' / 'user-or-device-auth-failure' + 'user-auth-failure'
    GRDGatewayAPIPasswordError, // 'auth-error' / 'invalid-password'
    GRDGatewayAPIProvisioningError,
    GRDGatewayAPIDeviceCheckError,
    GRDGatewayAPIUnknownError,
    GRDGatewayAPINoData,
    GRDGatewayAPINoReceiptData,
	GRDGatewayAPIReceiptExpired,
    GRDGatewayAPIServerInternalError,
    GRDGatewayAPIEndpointNotFound,
    GRDGatewayAPIStatusNone,
    GRDGatewayAPIStatusAPIRequestsDenied,
    GRDGatewayAPITokenMissing
};

@property (nonatomic) GRDGatewayAPIResponseStatus responseStatus;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSDictionary *jsonData;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSString *errorString;
@property (nonatomic, retain) NSString *eapUsername;
@property (nonatomic, retain) NSString *eapPassword;
@property (nonatomic, retain) NSString *apiAuthToken;
@property (nonatomic, retain) NSString *apiDeviceIdentifier;
@property (nonatomic, retain) NSString *vpnHostname;
@property (nonatomic, retain) NSArray *alertsArray;
@property (nonatomic, retain) NSDate *receiptExpirationDate;
@property (nonatomic, retain) NSString *receiptProductID;
@property (nonatomic) BOOL receiptIndicatesFreeTrialUsed;
@property (nonatomic) BOOL receiptHasActiveSubscription;

+ (GRDGatewayAPIResponse *)deniedResponse;
+ (GRDGatewayAPIResponse *)missingTokenResponse;
@end

NS_ASSUME_NONNULL_END
