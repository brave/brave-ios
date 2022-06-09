//
//  GRDRegion.h
//  Guardian
//
//  Created by Kevin Bradley on 4/25/21.
//  Copyright © 2021 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GuardianConnect/GRDVPNHelper.h>

NS_ASSUME_NONNULL_BEGIN

@interface GRDRegion : NSObject

@property NSString *continent; //continent
@property NSString *regionName; //name
@property NSString *displayName; //name-pretty
@property NSString *bestHost; //defaults to nil, is populated upon get server detail completion
@property NSString *bestHostLocation; //defaults to nil, is populated upon get server detail completion
@property BOOL isAutomatic; //experimental

- (instancetype)initWithDictionary:(NSDictionary *)regionDict;
- (void)findBestServerWithCompletion:(void(^)(NSString *server, NSString *serverLocation, BOOL success))completion;
- (void)findBestServerWithServerFeatureEnvironment:(GRDServerFeatureEnvironment)feautreEnv betaCapableServers:(BOOL)betaCapable completion:(void(^)(NSString *server, NSString *serverLocation, BOOL success))completion;

+ (GRDRegion *)automaticRegion;

/// Convenience method to convert timezones from the server into more useful GRDRegion instances, handy for region picker views
+ (NSArray <GRDRegion*> *)regionsFromTimezones:(NSArray *_Nullable)timezones;

@end

NS_ASSUME_NONNULL_END
