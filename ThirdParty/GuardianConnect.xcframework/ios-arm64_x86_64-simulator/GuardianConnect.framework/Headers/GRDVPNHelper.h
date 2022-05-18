//
//  GRDVPNHelper.h
//  Guardian
//
//  Created by will on 4/28/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

#import <GuardianConnect/Shared.h>
#import <GuardianConnect/GRDKeychain.h>
#import <GuardianConnect/GRDGatewayAPI.h>
#import <GuardianConnect/GRDTunnelManager.h>

#import <GuardianConnect/GRDTransportProtocol.h>
#import <GuardianConnect/GRDSubscriptionManager.h>
#import <GuardianConnect/GRDSubscriberCredential.h>
#import <GuardianConnect/GRDWireGuardConfiguration.h>

// Note from CJ 2022-02-02
// Using @class here for GRDRegion to prevent circular imports since
// we need GRDServerFeatureEnvironment in GRDRegion.h for a correct
// function signature
@class GRDRegion;

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#endif
#import <GuardianConnect/GRDCredentialManager.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GRDServerFeatureEnvironment) {
	ServerFeatureEnvironmentProduction = 1,
	ServerFeatureEnvironmentInternal,
	ServerFeatureEnvironmentDevelopment,
	ServerFeatureEnvironmentDualStack,
	ServerFeatureEnvironmentUnstable
};

@interface GRDVPNHelper : NSObject {
	BOOL _preferBetaCapableServers;
	GRDServerFeatureEnvironment _featureEnvironment;
}

@property (readonly) BOOL preferBetaCapableServers;

@property (readonly) GRDServerFeatureEnvironment featureEnvironment;

/// GuardianConnect app key used to authenticate API actions alongside the registered bundle id
@property (nonatomic, strong) NSString *_Nullable appKey;

/// GuardianConnect app bundle id used to authenticate API actions alongside the app key
@property (nonatomic, strong) NSString *_Nullable appBundleId;

/// can be set to true to make - (void)getEvents return dummy alerts for debugging purposes
@property BOOL dummyDataForDebugging;

/// don't set this value manually, it is set upon the region selection code working successfully
@property (nullable) GRDRegion *selectedRegion;

/// Indicates whether load from preferences was successfull upon init
@property BOOL vpnLoaded;

/// If vpnLoaded == NO this will contain the error message return from NEVPNManager
@property (nullable) NSString *lastErrorMessage;

@property (nullable) NEProxySettings *proxySettings;

/// a separate reference is kept of the mainCredential because the credential manager instance needs to be fetched from preferences & the keychain every time its called.
@property (nullable) GRDCredential *mainCredential;

@property (readwrite, assign) BOOL onDemand; //defaults to yes

/// This string will be used as the localized description of the NEVPNManager
/// configuration. The string will be visible in the network preferences on macOS
/// or in the VPN settings on iOS/iPadOS
///
/// Please note that this value is different than the grdTunnelProviderManagerLocalizedDescription
/// and it is not recommended to set the same values for both tunnels to avoid customers confusion
@property NSString *tunnelLocalizedDescription;


/// Indicate whether or not GRDVPNHelper should append a formatted server
/// location string at the end of the localized tunnel description string
///
/// Eg. "Guardian Firewall" -> "Guardian Firewall: Frankfurt, Germany"
@property BOOL appendServerRegionToTunnelLocalizedDescription;

/// Tunnel provider manager wrapper class to help with
/// starting and stopping a WireGuard VPN tunnel or a local tunnel.
@property GRDTunnelManager *tunnelManager;

/// Bundle Identifier string of the PacketTunnelProvider bundled with the main app.
/// May be omitted if WireGuard as the Transport Protocol or a local tunnel is not used.
/// It is recommended to set this up as early as possible
@property NSString *tunnelProviderBundleIdentifier;

/// This string will be used as the localized description of the NETunnelProviderManager
/// configuration. The string will be visible in the network preferences on macOS
/// or in the VPN settings on iOS/iPadOS
///
/// Please note that this value is different than the tunnelLocalizedDescription
/// and it is not recommended to set the same values for both tunnels to avoid customers confusion
@property NSString *grdTunnelProviderManagerLocalizedDescription;

/// Preferred DNS Server set here currently only apply to WireGuard VPN connections
///
/// Default: (Cloudflare) 1.1.1.1, 1.0.0.1
@property NSString *preferredDNSServers;

/// Indicate whether or not GRDVPNHelper should append a formatted server
/// location string at the end of the localized tunnel provider manager description string
///
/// Eg. "Guardian Firewall" -> "Guardian Firewall: Frankfurt, Germany"
@property BOOL appendServerRegionToGRDTunnelProviderManagerLocalizedDescription;

/// Constant used to make the WireGuard config in the local keychain
/// available to both the main app as well as the included Packet Tunnel Provider
/// app extension. Only used for WireGuard connections on iOS
@property NSString *appGroupIdentifier;

#if !TARGET_OS_OSX
@property UIBackgroundTaskIdentifier bgTask;
#endif

typedef NS_ENUM(NSInteger, GRDVPNHelperStatusCode) {
    GRDVPNHelperSuccess,
    GRDVPNHelperFail,
    GRDVPNHelperDoesNeedMigration,
    GRDVPNHelperMigrating,
    GRDVPNHelperNetworkConnectionError, // add other network errors
    GRDVPNHelperCoudNotReachAPIError,
    GRDVPNHelperApp_VpnPrefsLoadError,
    GRDVPNHelperApp_VpnPrefsSaveError,
    GRDVPNHelperAPI_AuthenticationError,
    GRDVPNHelperAPI_ProvisioningError
};

/// Always use the sharedInstance of this class, call it as early as possible in your application lifecycle to initialize the VPN preferences and load the credentials and VPN node connection information from the keychain.
+ (instancetype)sharedInstance;

/// Helper function to quickly determine if a VPN tunnel of any kind
/// with any transport protocol is established
- (BOOL)isConnected;

/// Helper function to quickly determine if a VPN tunnel of any kind
/// with any transport protocol is trying to establish the connection
- (BOOL)isConnecting;

/// retrieves values out of the system keychain and stores them in the sharedInstance singleton object in memory for other functions to use in the future
- (void)_loadCredentialsFromKeychain;

/// Used to determine if an active connection is possible, do we have all the necessary credentials (EAPUsername, Password, Host, etc)
+ (BOOL)activeConnectionPossible;

/// Used to clear all of our current VPN configuration details from user defaults and the keychain
+ (void)clearVpnConfiguration;

/// Sets our kGRDHostnameOverride variable in NSUserDefaults
+ (void)saveAllInOneBoxHostname:(NSString *)host;

/// Send out two notifications to make any listener
/// aware that the hostname and hostname location values
/// should be updated in the interface
+ (void)sendServerUpdateNotifications;

/// Used to create a new VPN connection if an active subscription exists. This is the main function to call when no EAP credentials or subscriber credentials exist yet and you want to establish a new connection on a server that is chosen automatically for you.
/// @param mid block This is a block you can assign for when this process has approached a mid point (a server is selected, subscriber & eap credentials are generated). optional.
/// @param completion block This is a block that will return upon completion of the process, if success is TRUE and errorMessage is nil then we will be successfully connected to a VPN node.
- (void)configureFirstTimeUserPostCredential:(void(^__nullable)(void))mid completion:(StandardBlock)completion;

/// Used to create a new VPN connection if an active subscription exists. This is the main function to call when no VPN credentials or a Subscriber Credential exist yet and a new connection should be established to a server chosen automatically.
/// @param protocol The desired transport protocol to use to establish the connection. IKEv2 (builtin) as well as WireGuard via a PacketTunnelProvider are supported
/// @param mid block This is a block you can assign for when this process has approached a mid point (a server is selected, subscriber & eap credentials are generated). optional.
/// @param completion block This is a block that will return upon completion of the process, if success is TRUE and errorMessage is nil then we will be successfully connected to a VPN node.
- (void)configureFirstTimeUserForTransportProtocol:(TransportProtocol)protocol postCredential:(void(^__nullable)(void))mid completion:(StandardBlock)completion;

/// Used to create a new VPN connection if an active subscription exists. This method will allow you to specify a host, a host location, a postCredential block and a completion block.
/// @param region GRDRegion, the region to create fresh VPN connection to, upon nil it will revert to automatic selection based upon the users current time zone.
/// @param completion block This is a block that will return upon completion of the process, if success is TRUE and errorMessage is nil then we will be successfully connected to a VPN node.
- (void)configureFirstTimeUserWithRegion:(GRDRegion * _Nullable)region completion:(StandardBlock)completion;

/// Used to create a new VPN connection if an active subscription exists. This method will allow you to specify a host, a host location, a postCredential block and a completion block.
/// @param protocol The desired transport protocol to use to establish the connection. IKEv2 (builtin) as well as WireGuard via a PacketTunnelProvider are supported
/// @param region GRDRegion, the region to create fresh VPN connection to, upon nil it will revert to automatic selection based upon the users current time zone.
/// @param completion block This is a block that will return upon completion of the process, if success is TRUE and errorMessage is nil then we will be successfully connected to a VPN node.
- (void)configureFirstTimeUserForTransportProtocol:(TransportProtocol)protocol withRegion:(GRDRegion * _Nullable)region completion:(StandardBlock)completion;

/// Used to create a new VPN connection if an active subscription exists. This method will allow you to specify a host, a host location, a postCredential block and a completion block.
/// @param host NSString specific host you want to connect to ie saopaulo-ipsec-4.sudosecuritygroup.com
/// @param hostLocation NSString the display version of the location of the host you are connecting to ie: Sao, Paulo, Brazil
/// @param mid block This is a block you can assign for when this process has approached a mid point (a server is selected, subscriber & eap credentials are generated). optional.
/// @param completion block This is a block that will return upon completion of the process, if success is TRUE and errorMessage is nil then we will be successfully connected to a VPN node.
- (void)configureFirstTimeUserForHostname:(NSString * _Nonnull)host andHostLocation:(NSString * _Nonnull)hostLocation postCredential:(void(^__nullable)(void))mid completion:(StandardBlock)completion;

/// Used to create a new VPN connection if an active subscription exists. This method will allow you to specify a transport protocol, host, a host location, a postCredential callback block and a completion block.
/// @param protocol The desired transport protocol to use to establish the connection. IKEv2 (builtin) as well as WireGuard via a PacketTunnelProvider are supported
/// @param host NSString specific host you want to connect to ie saopaulo-ipsec-4.sudosecuritygroup.com
/// @param hostLocation NSString the display version of the location of the host you are connecting to ie: Sao, Paulo, Brazil
/// @param mid block This is a block you can assign for when this process has approached a mid point (a server is selected, subscriber & eap credentials are generated). optional.
/// @param completion block This is a block that will return upon completion of the process, if success is TRUE and errorMessage is nil then we will be successfully connected to a VPN node.
- (void)configureFirstTimeUserForTransportProtocol:(TransportProtocol)protocol hostname:(NSString * _Nonnull)host andHostLocation:(NSString * _Nonnull)hostLocation postCredential:(void(^__nullable)(void))mid completion:(StandardBlock)completion;

/// Used subsequently after the first time connection has been successfully made to re-connect to the current host VPN node with mainCredentials
/// @param completion block This completion block will return a message to display to the user and a status code, if the connection is successful, the message will be empty.
- (void)configureAndConnectVPNWithCompletion:(void (^_Nullable)(NSString * _Nullable error, GRDVPNHelperStatusCode status))completion;

/// Used to disconnect from the current VPN node.
- (void)disconnectVPN;

/// Safely disconnect from the current VPN node if applicable. This is best to call upon doing disconnections upon app launches. For instance, if a subscription expiration has been detected on launch, disconnect the active VPN connection. This will make certain not to disconnect the VPN if a valid state isnt detected.
- (void)forceDisconnectVPNIfNecessary;


/// There should be no need to call this directly, this is for internal use only.
- (void)getValidSubscriberCredentialWithCompletion:(void(^)(GRDSubscriberCredential * _Nullable subscriberCredential, NSString * _Nullable error))completion;

/// Used to create standalone eap-username & eap-password on an automatically chosen host that is valid for a certain number of days. Good for exporting VPN credentials for use on other devices.
/// @param validForDays NSInteger number of days these credentials will be valid for
/// @param completion block Completion block that will contain an NSDictionary of credentials upon success
- (void)createStandaloneCredentialsForDays:(NSInteger)validForDays completion:(void(^)(NSDictionary *creds, NSString *errorMessage))completion;

/// Used to create standalone eap-username & eap-password on a specified host that is valid for a certain number of days. Good for exporting VPN credentials for use on other devices.
/// @param validForDays NSInteger number of days these credentials will be valid for
/// @param hostname NSString hostname to connect to ie: saopaulo-ipsec-4.sudosecuritygroup.com
/// @param completion block Completion block that will contain an NSDictionary of credentials upon success
- (void)createStandaloneCredentialsForDays:(NSInteger)validForDays hostname:(NSString *)hostname completion:(void (^)(NSDictionary * _Nonnull, NSString * _Nonnull))completion;

/// Used to create standalone VPN credentials on an automatically chosen host that is valid for a certain number of days. Good for exporting VPN credentials for use on other devices.
/// @param protocol The desired transport protocol to use to establish the connection. IKEv2 (builtin) as well as WireGuard via a PacketTunnelProvider are supported
/// @param validForDays NSInteger number of days these credentials will be valid for
/// @param completion block Completion block that will contain an NSDictionary of credentials upon success
- (void)createStandaloneCredentialsForTransportProtocol:(TransportProtocol)protocol days:(NSInteger)validForDays completion:(void(^)(NSDictionary *creds, NSString *errorMessage))completion;

/// Used to create standalone VPN credentials on a specified host that is valid for a certain number of days. Good for exporting VPN credentials for use on other devices.
/// @param protocol The desired transport protocol to use to establish the connection. IKEv2 (builtin) as well as WireGuard via a PacketTunnelProvider are supported
/// @param days NSInteger number of days these credentials will be valid for
/// @param hostname NSString hostname to connect to ie: saopaulo-ipsec-4.sudosecuritygroup.com
/// @param completion block Completion block that will contain an NSDictionary of credentials upon success
- (void)createStandaloneCredentialsForTransportProtocol:(TransportProtocol)protocol validForDays:(NSInteger)days hostname:(NSString *)hostname completion:(void (^)(NSDictionary * credentials, NSString * errorMessage))completion;


/// Verify that current EAP credentials are valid if applicable. A valid Subscriber Credential is automatically obtained and provided to the VPN node alongside the credential details. If the device is currently connected and the server indicates that the VPN credentials are no longer valid the device is automatically migrated to a new server within the same region
- (void)verifyMainEAPCredentialsWithCompletion:(void(^)(BOOL valid, NSString *errorMessage))completion;

/// Verify that the current main VPN credentials are valid if applicable. A valid Subscriber Credential is automatically obtained and provided to the VPN node alongside the credential details. If the device is currently connected and the server indicates that the VPN credentials are no longer valid the device is automatically migrated to a new server within the same region
- (void)verifyMainCredentialsWithCompletion:(void(^)(BOOL valid, NSString * _Nullable errorMessage))completion;

/// Call this to properly assign a GRDRegion to all GRDServerManager instances
/// @param region the region to select a server from. Pass nil to reset to Automatic region selection mode
- (void)selectRegion:(GRDRegion * _Nullable)region;

/// Migrate the user to a new server. A new server will be selected, new credentials will be generated and finally the VPN tunnel will be established with the new credentials on the new server.
- (void)migrateUserWithCompletion:(void (^_Nullable)(BOOL success, NSString *error))completion;

/// Migrate the user to a new server for the user preferred transport protocol. A new server will be selected, new credentials will be generated and finally the VPN tunnel will be established with the new credentials on the new server.
- (void)migrateUserForTransportProtocol:(TransportProtocol)protocol withCompletion:(void (^_Nullable)(BOOL success, NSString *error))completion;


/// Clear all on device cache related to cached Guardian hosts & keychain items including the Subscriber Credential
- (void)clearLocalCache;

@end

NS_ASSUME_NONNULL_END
