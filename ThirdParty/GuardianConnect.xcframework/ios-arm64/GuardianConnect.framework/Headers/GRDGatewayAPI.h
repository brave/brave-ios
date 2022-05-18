//
//  GRDGatewayAPI.h
//  Guardian
//
//  Copyright © 2017 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeviceCheck/DeviceCheck.h>

#import <GuardianConnect/GRDKeychain.h>
#import <GuardianConnect/GRDGatewayAPIResponse.h>
#import <GuardianConnect/GRDDebugHelper.h>
#import <GuardianConnect/GRDCredential.h>


NS_ASSUME_NONNULL_BEGIN

@interface GRDGatewayAPI : NSObject

/// can be set to true to make - (void)getEvents return dummy alerts for debgging purposes
@property BOOL dummyDataForDebugging; //obsolete, moved to GRDVPNHelper

/// apiAuthToken is used as a second factor of authentication by the zoe-agent API. zoe-agent expects this value to be sent in the JSON encoded body of the HTTP request for the value 'api-auth-token'
@property (strong, nonatomic, readonly) NSString *apiAuthToken;

/// deviceIdentifier and eapUsername are the same values. eapUsername is stored in the keychain for the value 'eap-username'
@property (strong, nonatomic, readonly) NSString *deviceIdentifier;

/// apiHostname holds the value of the zoe-agent instance the app is currently connected to in memory. A persistent copy of it is stored in NSUserDefaults
@property (strong, nonatomic, readonly) NSString *apiHostname;

/// Load the current VPN node hostname out of NSUserDefaults
- (NSString *)baseHostname;


/// endpoint: /vpnsrv/api/server-status
/// hits the endpoint for the current VPN host to check if a VPN connection can be established
- (void)getServerStatusWithCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion;

/// endpoint: /api/v1.1/register-and-create
/// @param subscriberCredential JWT token obtained from housekeeping
/// @param validFor integer informing the API how long the EAP credentials should be valid for. A value of 30 indicated 30 days starting right now (eg. 30 days * 24 hours worth of service)
/// @param completion completion block indicating success, returning EAP Credentials as well as an API auth token or returning an error message for user consumption
- (void)registerAndCreateWithSubscriberCredential:(NSString *_Nonnull)subscriberCredential validForDays:(NSInteger)validFor completion:(void (^)(NSDictionary * _Nullable credentials, BOOL success, NSString * _Nullable errorMessage))completion;

/// endpoint: /api/v1.1/register-and-create
/// @param hostname The host we are creating the credential for
/// @param subscriberCredential JWT token obtained from housekeeping
/// @param validFor integer informing the API how long the EAP credentials should be valid for. A value of 30 indicated 30 days starting right now (eg. 30 days * 24 hours worth of service)
/// @param completion completion block indicating success, returning EAP Credentials as well as an API auth token or returning an error message for user consumption
- (void)registerAndCreateWithHostname:(NSString *_Nonnull)hostname subscriberCredential:(NSString *_Nonnull)subscriberCredential validForDays:(NSInteger)validFor completion:(void (^)(NSDictionary * _Nullable, BOOL, NSString * _Nullable))completion;

/// endpoint: /api/v1.2/device/<eap-username>/verify-credentials
/// Validates the existence of the current actively used EAP credentials with the VPN server. If a VPN server has been reset or the EAP credentials have been invalided and/or deleted the app needs to migrate to a new host and obtain new EAP credentials
/// A Subscriber Crednetial is required to prevent broad abuse of the endpoint, thought it is not required to provide the same Subscriber Credential which was initially used to generate the EAP credentials in the past. Any valid Subscriber Credential will be accepted
- (void)verifyEAPCredentialsUsername:(NSString * _Nonnull)eapUsername apiToken:(NSString * _Nonnull)apiToken andSubscriberCredential:(NSString * _Nonnull)subscriberCredential forVPNNode:(NSString * _Nonnull)vpnNode completion:(void(^)(BOOL success, BOOL stillValid, NSString * _Nullable errorMessage, BOOL subCredInvalid))completion;

/// endpoint: /api/v1.2/device/<eap-username>/invalidate-credentials
/// @param eapUsername the EAP username to invalidate. Also used as the device ID
/// @param apiToken the API token for the EAP username to invalidate
/// @param completion completion block indicating a successfull API call or returning an error message
- (void)invalidateEAPCredentials:(NSString *_Nonnull)eapUsername andAPIToken:(NSString *_Nonnull)apiToken completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;

/// endpoint: /api/v1.2/device/<eap-username>/invalidate-credentials
/// @param credentials GRDCredentials to invalidate
/// @param completion completion block indicating a successfull API call or returning an error message
- (void)invalidateEAPCredentials:(GRDCredential *_Nonnull)credentials completion:(void (^)(BOOL, NSString * _Nullable))completion;


/// Used to register a new device for a given transport protocol
/// @param transportProtocol Specified what kind of VPN credentials will be returned
/// @param hostname The hostname of the VPN node
/// @param subscriberCredential The Subscriber Credential which should be used to authenticate
/// @param validFor The amount of days the VPN credentials should be valid for
/// @param options Optional non-standard values which should be passed to the VPN node via the JSON body of the request
/// @param completion The completion handler called once the task is compeleted
- (void)registerDeviceForTransportProtocol:(NSString * _Nonnull)transportProtocol hostname:(NSString * _Nonnull)hostname subscriberCredential:(NSString * _Nonnull)subscriberCredential validForDays:(NSInteger)validFor transportOptions:(NSDictionary * _Nullable)options completion:(void (^)(NSDictionary * _Nullable credentialDetails, BOOL success, NSString * _Nullable errorMessage))completion;

/// Used to verify that the local credentials are still valid and can be used to establish the VPN connection again
/// @param clientId The client id assosicated with the VPN credentials
/// @param apiToken The API token to authenticate the request
/// @param hostname The hostname of the VPN node
/// @param subCred The Subscriber Credential to authenticate the request and prevent connection spoofing
/// @param completion The completion handler called once the task is completed
- (void)verifyCredentialsForClientId:(NSString *)clientId withAPIToken:(NSString *)apiToken hostname:(NSString * _Nonnull)hostname subscriberCredential:(NSString * _Nonnull)subCred completion:(void (^)(BOOL success, BOOL credentialsValid, NSString * _Nullable errorMessage))completion;

/// Used to invalidate a set of VPN credentials which renders them completely broken server side. They can't be used to establish a VPN connection anymore nor can the client download alerts for this client id once this API is called
/// @param clientId The client id assosicated with the VPN credentials
/// @param apiToken The API token to authenticate the request
/// @param hostname The hostname of the VPN node
/// @param subCred The Subscriber Credential to authenticate the request and prevent connection spoofing
/// @param completion The completion handler called once the task is completed
- (void)invalidateCredentialsForClientId:(NSString *)clientId apiToken:(NSString *)apiToken hostname:(NSString *)hostname subscriberCredential:(NSString *)subCred completion:(void (^)(BOOL, NSString * _Nullable))completion;

/// endpoint: /api/v1.1/device/<eap-username>/alerts
/// @param completion De-Serialized JSON from the server containing an array with all alerts
- (void)getEvents:(void (^)(NSDictionary *response, BOOL success, NSString *_Nullable error))completion;

/// endpoint: /api/v1.2/device/<eap-username>/set-alerts-download-timestamp
/// @param completion completion block indicating a successful API request or an error message with detailed information
- (void)setAlertsDownloadTimestampWithCompletion:(void(^)(BOOL success, NSString * _Nullable errorMessage))completion;

/// endpoint: /api/v1.2/device/<eap-username>/alert-totals
/// @param completion completion block indicating a successful API request, if successful a dictionary with the alert totals per alert category or an error message
- (void)getAlertTotals:(void (^)(NSDictionary * _Nullable alertTotals, BOOL success, NSString * _Nullable errorMessage))completion;


/// endpoint: /api/v1.1/<device_token>/set-push-token
/// @param pushToken APNS push token sent to VPN server
/// @param dataTrackers indicator whether or not to send push notifications for data trackers
/// @param locationTrackers indicator whether or not to send push notifications for location trackers
/// @param pageHijackers indicator whether or not to send push notifications for page hijackers
/// @param mailTrackers indicator whether or not to send push notifications for mail trackers
/// @param completion completion block indicating success, and an error message with information for the user
- (void)setPushToken:(NSString *_Nonnull)pushToken andDataTrackersEnabled:(BOOL)dataTrackers locationTrackersEnabled:(BOOL)locationTrackers pageHijackersEnabled:(BOOL)pageHijackers mailTrackersEnabled:(BOOL)mailTrackers completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;

/// endpoint: /api/v1.1/device/<device_token>/remove-push-token
/// @param completion completion block indicating success, and an error message with information for the user
- (void)removePushTokenWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;

@end

NS_ASSUME_NONNULL_END

