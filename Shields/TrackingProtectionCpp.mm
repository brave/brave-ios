/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TrackingProtectionCpp.h"
#import "TPParser.h"

static CTPParser parser;

@interface TrackingProtectionCpp()
@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSMutableDictionary *firstPartyHostsCache;
@end

@implementation TrackingProtectionCpp

-(void)setDataFile:(NSData *)data
{
    @synchronized(self) {
        self.data = data;
        parser.deserialize((char *)self.data.bytes);
    }
}

-(BOOL)hasDataFile
{
    @synchronized(self) {
        return self.data != nil;
    }
}

- (BOOL)checkHostIsBlocked:(NSString *)url
          mainDocumentHost:(NSString *)mainDoc
{
    if (![self hasDataFile]) {
        return NO;
    }

    if (!parser.matchesTracker(mainDoc.UTF8String, url.UTF8String)) {
        return NO;
    }

    const int kMaxCacheSize = 50;
    if (self.firstPartyHostsCache.count > kMaxCacheSize) {
        self.firstPartyHostsCache  = nil;
    }

    if (!self.firstPartyHostsCache) {
        self.firstPartyHostsCache = [NSMutableDictionary dictionary];
    }

    NSArray *safeHosts = self.firstPartyHostsCache[mainDoc];
    if (!safeHosts) {
        char *findFirstPartyHosts = parser.findFirstPartyHosts(mainDoc.UTF8String);
        if (!findFirstPartyHosts)
            return YES;
        safeHosts = [[NSString stringWithUTF8String:findFirstPartyHosts] componentsSeparatedByString:@","];
        self.firstPartyHostsCache[mainDoc] = safeHosts;
    }

    for (NSString *safeHost in safeHosts) {
        if ([safeHost isEqualToString:url] || [url hasSuffix:[@"." stringByAppendingString:safeHost]] ) {
            return NO;
        }
    }

    return YES;
}

@end
