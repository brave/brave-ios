//
//  GRDTransportProtocol.h
//  GuardianConnect
//
//  Created by Constantin Jacob on 05.01.22.
//  Copyright © 2022 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, TransportProtocol) {
	TransportUnknown = 0,
	TransportIKEv2,
	TransportWireGuard
};

@interface GRDTransportProtocol : NSObject

/// Returns a nicely formatted string representation for the given transport protocol
/// which can either be used for debug purposes or as JSON keys in API requests
/// @param protocol the transport protocol to translate into a string representation
+ (NSString *)transportProtocolStringFor:(TransportProtocol)protocol;

/// Returns the same strings as + (NSString *)transportProtocolStringFor:(TransportProtocol)protocol
/// with the only difference being that these are upper and lowercase formatted
/// to be used in the user interface
+ (NSString *)prettyTransportProtocolStringFor:(TransportProtocol)protocol;

/// Convenience function to persistently store the user preferred transport protocol on device
/// which potentially returns an error message as a string
/// @param protocol the user preferred transport protocol
+ (NSString *)setUserPreferredTransportProtocol:(TransportProtocol)protocol;

/// Convenience function to fetch the user preferred transport protocol.
/// If no user preferred transport protocol has been set yet it will return TransportIKEv2
+ (TransportProtocol)getUserPreferredTransportProtocol;

/// Convenience function to convert a (non-pretty) transport protocol string
/// into a TransportProtocol object
+ (TransportProtocol)transportProtocolFromString:(NSString *)protocolString;

@end

NS_ASSUME_NONNULL_END
