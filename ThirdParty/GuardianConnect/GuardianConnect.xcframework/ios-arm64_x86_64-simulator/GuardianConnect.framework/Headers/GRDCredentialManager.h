//
//  GRDCredentialManager.h
//  Guardian
//
//  Created by Kevin Bradley on 3/2/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//
// Manage EAP credentials

#import <Foundation/Foundation.h>
#import <GuardianConnect/GRDCredential.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDCredentialManager : NSObject

+ (NSArray <GRDCredential *>*)credentials;
+ (NSArray <GRDCredential *>*)filteredCredentials;
+ (GRDCredential *)mainCredentials;
+ (void)clearMainCredentials;
+ (GRDCredential *)credentialWithIdentifier:(NSString *)groupIdentifier;
+ (void)addOrUpdateCredential:(GRDCredential *)credential;
+ (void)removeCredential:(GRDCredential *)credential;

+ (BOOL)migrateKeychainItemsToGRDCredential;

+ (void)createCredentialForRegion:(NSString *)regionString numberOfDays:(NSInteger)numberOfDays main:(BOOL)mainCredential completion:(void(^)(GRDCredential * _Nullable cred, NSString * _Nullable error))completion;

+ (void)createCredentialForRegion:(NSString *)region withTransportProtocol:(TransportProtocol)protocol numberOfDays:(NSInteger)numberOfDays main:(BOOL)mainCredential completion:(void(^)(GRDCredential * _Nullable cred, NSString * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
