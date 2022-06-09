//
//  GRDCredential.h
//  Guardian
//
//  Created by Kevin Bradley on 3/2/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GuardianConnect/GRDTransportProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDCredential : NSObject

// Properties used by all credentials
@property NSString 	        *name;
@property NSString 	        *identifier;
@property BOOL              mainCredential;
@property TransportProtocol transportProtocol;
@property NSDate 	        *expirationDate;
@property NSString 	        *hostname;
@property NSString 	        *hostnameDisplayValue;

@property NSString          *clientId;
@property NSString          *apiAuthToken;

// IKEv2 related properties
@property NSString 	*username;
@property NSString 	*password;
@property NSData 	*passwordRef;

// WireGuard related properties
@property NSString *devicePublicKey;
@property NSString *devicePrivateKey;
@property NSString *serverPublicKey;
@property NSString *IPv4Address;
@property NSString *IPv6Address;

- (NSString *)prettyHost;
- (NSString *)defaultFileName;
- (id)initWithFullDictionary:(NSDictionary *)credDict validFor:(NSInteger)validForDays isMain:(BOOL)mainCreds;
- (id)initWithTransportProtocol:(TransportProtocol)protocol fullDictionary:(NSDictionary *)credDict validFor:(NSInteger)validForDays isMain:(BOOL)mainCreds;
- (id)initWithDictionary:(NSDictionary *)credDict hostname:(NSString *)hostname expiration:(NSDate *)expirationDate;
- (void)updateWithItem:(GRDCredential *)cred;
- (NSString *)truncatedHost;
- (NSString *)authTokenIdentifier;
- (BOOL)expired;
- (NSInteger)daysLeft; //days until it does expire
- (BOOL)canRevoke; //legacy credentials are missing the API auth token so they cant be revoked.
- (void)revokeCredentialWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;


// Note from CJ 2022-05-03
// Both of these are deprecated and only remain in the codebase
// to leave existing codepaths untouched. They should never be used directly
// nor should they be adopted anywhere else in newly written code since
// all credentials are now saved together as a data blob in the keychain
// and managed by GRDCredentialManager
- (OSStatus)saveToKeychain;
- (BOOL)loadFromKeychain;
- (OSStatus)removeFromKeychain;

@end

NS_ASSUME_NONNULL_END
