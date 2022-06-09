//
//  Shared.h
//  Guardian
//
//  Created by Kevin Bradley on 10/13/20.
//  Copyright © 2020 Sudo Security Group Inc. All rights reserved.
//

#ifndef Shared_h
#define Shared_h

typedef void (^StandardBlock)(BOOL success, NSString * _Nullable errorMessage);
typedef void (^ResponseBlock)(NSDictionary * _Nullable response, NSString * _Nullable errorMessage, BOOL success);

// Define below to 0 to make guardian specific code inactive
#define GUARDIAN_INTERNAL 1

#pragma mark - Misc

NS_ASSUME_NONNULL_BEGIN
static NSString * const kAppNeedsSelfRepair                             = @"guardianNeedsSelfRepair";

#pragma mark - Housekeeping / Region / Timezone

static NSString * const kGuardianNetworkHealthStatusNotification        = @"networkHealthStatusNotification";
static NSString * const kGuardianSuccessfulSubscription                 = @"successfullySubscribedToGuardian";

static NSString * const kGRDDefaultGatewayUUID                          = @"kGRDDefaultGatewayUUID";

static NSString * const kVPNHadNetworkHealthDisconnect                  = @"vpnHadNetworkHealthDisconnect";
static NSString * const kGRDHostnameOverride                            = @"APIHostname-Override";
static NSString * const kGRDEAPSharedHostname                           = @"SharedAPIHostname";
static NSString * const kGRDVPNHostLocation                             = @"kGRDVPNHostLocation";
static NSString * const kGRDIncludesAllNetworks                         = @"kGRDIncludesAllNetworks";
static NSString * const kGRDExcludeLocalNetworks                        = @"kGRDExcludeLocalNetworks";
static NSString * const kGRDWifiAssistEnableFallback                    = @"kGRDWifiAssistEnableFallback";
static NSString * const kGRDRefreshProxySettings                        = @"kGRDRefreshProxySettings";
static NSString * const kGRDTunnelEnabled                               = @"kGRDTunnelEnabled";
static NSString * const kGuardianTransportProtocol						= @"kGuardianTransportProtocol";

static NSString * const kGRDWGDevicePublicKey                           = @"wg-device-public-key";
static NSString * const kGRDWGDevicePrivateKey							= @"wg-device-private-key";
static NSString * const kGRDWGServerPublicKey                           = @"server-public-key";
static NSString * const kGRDWGIPv4Address                               = @"mapped-ipv4-address";
static NSString * const kGRDWGIPv6Address                               = @"mapped-ipv6-address";
static NSString * const kGRDClientId                               		= @"client-id";

static NSString * const kGuardianFauxTimeZone                           = @"faux-timezone";
static NSString * const kGuardianFauxTimeZonePretty                     = @"faux-timezone-pretty";
static NSString * const kGuardianUseFauxTimeZone                        = @"use-faux-timezone";
static NSString * const kKnownHousekeepingTimeZonesForRegions           = @"kKnownHousekeepingTimeZonesForRegions";
static NSString * const housekeepingTimezonesTimestamp                  = @"housekeepingTimezonesTimestamp";
static NSString * const kGuardianAllRegions                             = @"kGRDAllRegions";
static NSString * const kGuardianAllRegionsTimeStamp                    = @"kGRDAllRegionsTimeStamp";
static NSString * const kKnownGuardianHosts                             = @"kKnownGuardianHosts";
static NSString * const kGuardianSubscriptionExpiresDate                = @"subscriptionExpiresDate";


#pragma mark - Subscription types + related
static NSString * const kGuardianSubscriptionTypeEssentials             = @"grd_type_essentials";
static NSString * const kGuardianSubscriptionDayPass                    = @"grd_day_pass";
static NSString * const kGuardianSubscriptionDayPassAlt                 = @"grd_day_pass_alt";
static NSString * const kGuardianSubscriptionGiftedDayPass              = @"grd_gifted_day_pass";
static NSString * const kGuardianSubscriptionCustomDayPass              = @"custom_day_pass";
static NSString * const kGuardianSubscriptionMonthly                    = @"grd_monthly";
static NSString * const kGuardianSubscriptionThreeMonths                = @"grd_three_months";
static NSString * const kGuardianSubscriptionAnnual                     = @"grd_annual";
static NSString * const kGuardianSubscriptionTypeProfessionalIAP        = @"grd_pro";
static NSString * const kGuardianSubscriptionTypeCustomDayPass          = @"grd_custom_day_pass";
static NSString * const kGuardianSubscriptionTypeIntroductory           = @"grd_day_pass_introductory";
// "grd_teams" is an umbrealla description. Should never be used in production since it does not accurately describe the subscription length etc.
static NSString * const kGuardianSubscriptionTypeTeams 					= @"grd_teams";
static NSString * const kGuardianSubscriptionTypeTeamsAnnual			= @"grd_teams_annual";

static NSString * const kGuardianFreeTrial3Days                         = @"grd_trial_3_days";
static NSString * const kGuardianExtendedTrial30Days                    = @"grd_extended_trial_30_days";
static NSString * const kGuardianTrialBalanceDayPasses                  = @"grd_trial_balance_day_passes";
static NSString * const kGuardianSubscriptionFreeTrial                  = @"free_trial";

static NSString * const kGuardianSubscriptionTypeVisionary              = @"grd_visionary";
static NSString * const kGuardianSubscriptionTypeProfessionalMonthly    = @"grd_pro_monthly";
static NSString * const kGuardianSubscriptionTypeProfessionalYearly     = @"grd_pro_yearly";
static NSString * const kGuardianSubscriptionTypeProfessionalBrave      = @"bravevpn.yearly-pro";

static NSString * const kGuardianFreeTrialPeTokenSet                    = @"kGRDFreeTrialPETokenSet";
static NSString * const kGuardianDayPassExpirationDate                  = @"GuardianDayPassExpirationDate";
static NSString * const kGuardianPETokenExpirationDate                  = @"kGuardianPETokenExpirationDate";

static NSString * const kGuardianSubscriptionProductIds                 = @"kGuardianSubscriptionProductIds";

// Used to hard to code IAP receipts and create Subscriber Credentials
static NSString * const kGuardianEncodedAppStoreReceipt = @"kGuardianEncodedAppStoreReceipt";

//moved to make framework friendly
static NSString * const kIsPremiumUser                                  = @"userHasPaidSubscription";
static NSString * const kSubscriptionPlanTypeStr                        = @"subscriptionPlanType";

typedef NS_ENUM(NSInteger, GRDPlanDetailType) {
    GRDPlanDetailTypeFree = 0,
    GRDPlanDetailTypeEssentials,
    GRDPlanDetailTypeProfessional
};

#define kGRDServerUpdatedNotification @"GRDServerUpdatedNotification"
#define kGRDLocationUpdatedNotification @"GRDLocationUpdatedNotification"
#define kGRDSubscriptionUpdatedNotification @"GRDSubscriptionUpdatedNotification"

static NSString * const kGRDTrialExpirationInterval =          @"kGRDTrialExpirationInterval";
static NSString * const kGRDFreeTrialExpired =                 @"kGRDFreeTrialExpired";

NS_ASSUME_NONNULL_END
#endif /* Shared_h */
