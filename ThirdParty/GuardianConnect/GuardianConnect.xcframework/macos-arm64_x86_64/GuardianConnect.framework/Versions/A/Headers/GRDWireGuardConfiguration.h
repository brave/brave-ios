//
//  GRDWireGuardConfiguration.h
//  GuardianConnect
//
//  Created by Constantin Jacob on 17.03.22.
//  Copyright © 2022 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GuardianConnect/GRDCredential.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDWireGuardConfiguration : NSObject

/// Retrieve a formatted, wg-quick(8) compatible string for a given GRDCredential
/// Will return nil if the transportProtocol property is not TransportWireGuard
/// @param credential the given credential out which the formatted wg-quick compatible should be generated
+ (NSString *)wireguardQuickConfigForCredential:(GRDCredential *)credential dnsServers:(NSString *_Nullable)dnsServers;


@end

NS_ASSUME_NONNULL_END
