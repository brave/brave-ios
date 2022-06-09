//
//  GRDKeychain.h
//  Guardian
//
//  Copyright © 2017 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kKeychainStr_EapUsername 			= @"eap-username";
static NSString * const kKeychainStr_EapPassword 			= @"eap-password";
static NSString * const kKeychainStr_AuthToken				= @"auth-token";
static NSString * const kKeychainStr_APIAuthToken 			= @"api-auth-token";
static NSString * const kKeychainStr_SubscriberCredential 	= @"subscriber-credential";
static NSString * const kKeychainStr_PEToken 				= @"pe-token";
static NSString * const kKeychainStr_WireGuardConfig 		= @"kGuardianWireGuardConfig";
static NSString * const kKeychainStr_DayPassAccountingToken = @"kGuardianDayPassAccountingToken";
static NSString * const kGuardianCredentialsList 			= @"kGuardianCredentialsList";

@interface GRDKeychain : NSObject

+ (OSStatus)storePassword:(NSString *)passwordStr forAccount:(NSString *)accountKeyStr;
+ (OSStatus)storeData:(NSData *)data forAccount:(NSString *)accountKeyString;

+ (NSString *)getPasswordStringForAccount:(NSString *)accountKeyStr;
+ (NSData *)getPasswordRefForAccount:(NSString *)accountKeyStr;
+ (NSData *)getDataForAccount:(NSString *)accountKeyString;
+ (OSStatus)removeKeychanItemForAccount:(NSString *)accountKeyStr;
+ (OSStatus)removeSubscriberCredentialWithRetries:(NSInteger)retryCount;

+ (void)removeAllKeychainItems;
+ (void)removeGuardianKeychainItems;

@end
