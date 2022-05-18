//
//  GRDServerManager.h
//  Guardian
//
//  Created by will on 6/21/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GuardianConnect/GRDRegion.h>
#import <GuardianConnect/GRDVPNHelper.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDServerManager : NSObject

- (instancetype)initWithServerFeatureEnvironment:(GRDServerFeatureEnvironment)featureEnv betaCapableServers:(BOOL)betaCapable;

/// Used to find and return the VPN server node we will connect to based on the results of a call to 'getGuardianHostsWithCompletion:"
/// @param completion Completion block that will contain the selected host, hostLocation upon success or an error message upon failure.
- (void)selectGuardianHostWithCompletion:(void (^)(NSString * _Nullable guardianHost, NSString * _Nullable guardianHostLocation, NSString * _Nullable errorMessage))completion;

/// Used to get available VPN server nodes based on NSUserDefault settings OR the users time zone. Explained further below.
/// if kGuardianUseFauxTimeZone is true kGuardianFauxTimeZone and kGuardianFauxTimeZonePretty will be used to find our host (this is how region selection works)
/// If kGuardianUseFauxTimeZone is nil or false we will automatically choose the best host based on the users timezone.
/// @param completion Completion block with an NSArray of full server address nodes OR an error message if the call fails.
- (void)getGuardianHostsWithCompletion:(void (^)(NSArray * _Nullable servers, NSString * _Nullable errorMessage))completion;

/// Used to find and connect to a VPN server node in 'regionName' specified & create the connection, handy to use in the region picker view for specified regionName
/// @param regionName NSString The region we want to specify, if null it will defer to 'Automatic' selection.
/// @param completion Completion block with NSString error message if the 'success' BOOL is false. (upon failure)
- (void)selectBestHostFromRegion:(NSString *)regionName completion:(void(^_Nullable)(NSString *errorMessage, BOOL success))completion;

/// Used to find the best VPN server node in a specified region, useful if you want to get VPN server node & its host location without creating a VPN connection.
/// @param regionName NSString. The region we want to find the best available VPN node in.
/// @param completion block. Will return a fully qualified server address, and the display friendly host location upon success, and the error NSString upon failure.
- (void)findBestHostInRegion:(NSString * _Nullable)regionName completion:(void(^_Nullable)(NSString *host, NSString *hostLocation, NSString *error))completion;

/// Used in selectGuardianHostWithCompletion: to get an NSDictionary representation of our 'local' region.
/// @param timezones NSArray of timezones that is from GRDHousekeepingAPI 'requestTimeZonesForRegionsWithTimestamp:' method
/// @return GRDRegion of our local hostname representation. This will be a custom region from 'kGuardianFauxTimeZone' if 'kGuardianUseFauxTimeZone' is true.
+ (GRDRegion *)localRegionFromTimezones:(NSArray *)timezones;

- (void)getRegionsWithCompletion:(void(^)(NSArray <GRDRegion *> *regions))completion;

@end

NS_ASSUME_NONNULL_END
