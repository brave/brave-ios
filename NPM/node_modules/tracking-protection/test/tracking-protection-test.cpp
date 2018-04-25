/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include <string>
#include "./CppUnitLite/TestHarness.h"
#include "./CppUnitLite/Test.h"
#include "../TPParser.h"

TEST(parser, test1) {

    char* data = nullptr;
    for (size_t i = 0; i < 2; i++)
    {
        CTPParser parser;

        if (0 == i) {
            parser.addTracker("facebook.com");
            parser.addTracker("facebook.de");
        }
        else if (nullptr != data) {
            CHECK(nullptr != data);
            CHECK(parser.deserialize(data));
        }

        CHECK(parser.matchesTracker("facebook1.com", "facebook.com"));
        CHECK(parser.matchesTracker("facebook1.com", "facebook.de"));
        CHECK(!parser.matchesTracker("facebook.com", "facebook1.com"));
        CHECK(!parser.matchesTracker("facebook.com", "facebook.com"));
        CHECK(!parser.matchesTracker("www.facebook.com", "facebook.com"));
        CHECK(!parser.matchesTracker("facebook.com", "www.facebook.com"));
        CHECK(!parser.matchesTracker("www.facebook.com", "www.facebook.com"));
        if (0 == i) {
            unsigned int totalSize = 0;
            data = parser.serialize(&totalSize);
            CHECK(nullptr != data);
            CHECK(0 != totalSize);
        }
        else {
            delete []data;
            data = nullptr;
        }
    }

    for (size_t i = 0; i < 2; i++)
    {
        CTPParser parser;

        if (0 == i) {
            parser.addTracker("facebook.com");
            parser.addTracker("facebook.de");
            parser.addTracker("google-analytics.com");
        }
        else if (nullptr != data) {
            CHECK(nullptr != data);
            CHECK(parser.deserialize(data));
        }

        CHECK(parser.matchesTracker("facebook.com", "subdomain.google-analytics.com"));
        CHECK(parser.matchesTracker("facebook.com", "google-analytics.com"));
        CHECK(parser.matchesTracker("facebook1.com", "facebook.com"));
        CHECK(parser.matchesTracker("facebook.com", "facebook.de"));
        CHECK(!parser.matchesTracker("facebook.com", "subdomain.google-analytics1.com"));
        CHECK(!parser.matchesTracker("facebook.com", "facebook.com"));
        if (0 == i) {
            unsigned int totalSize = 0;
            data = parser.serialize(&totalSize);
            CHECK(nullptr != data);
            CHECK(0 != totalSize);
        }
        else {
            delete []data;
            data = nullptr;
        }
    }

    for (size_t i = 0; i < 2; i++)
    {
        CTPParser parser;

        if (0 == i) {
            parser.addTracker("subdomain.google-analytics.com");
            parser.addTracker("facebook.com");
            parser.addTracker("facebook.de");
        }
        else if (nullptr != data) {
            CHECK(nullptr != data);
            CHECK(parser.deserialize(data));
        }

        CHECK(parser.matchesTracker("facebook.com", "subdomain.google-analytics.com"));
        CHECK(parser.matchesTracker("facebook1.com", "facebook.com"));
        CHECK(parser.matchesTracker("facebook.com", "facebook.de"));
        CHECK(!parser.matchesTracker("facebook.com", "google-analytics.com"));
        CHECK(!parser.matchesTracker("facebook.com", "facebook.com"));
        if (0 == i) {
            unsigned int totalSize = 0;
            data = parser.serialize(&totalSize);
            CHECK(nullptr != data);
            CHECK(0 != totalSize);
        }
        else {
            delete []data;
            data = nullptr;
        }
    }

    for (size_t i = 0; i < 2; i++)
    {
        CTPParser parser;

        if (0 == i) {
            parser.addFirstPartyHosts("facebook.com", "facebook.fr,facebook.de");
            parser.addFirstPartyHosts("google.com", "2mdn.net,admeld.com");
            parser.addFirstPartyHosts("subdomain.google.com", "facebook.fr,facebook.de");
        }
        else if (nullptr != data) {
            CHECK(nullptr != data);
            CHECK(parser.deserialize(data));
        }

        char* thirdPartyHostsSubDomain = parser.findFirstPartyHosts("subdomain.google.com");
        CHECK(nullptr != thirdPartyHostsSubDomain);

        char* thirdPartyHosts = parser.findFirstPartyHosts("google.com");
        CHECK(nullptr != thirdPartyHosts);
        if (nullptr != thirdPartyHostsSubDomain && nullptr != thirdPartyHosts) {
            std::string strThirdPartyHostsSubDomain = thirdPartyHostsSubDomain;
            std::string strThirdPartyHosts = thirdPartyHosts;
            CHECK(std::string::npos != strThirdPartyHostsSubDomain.find(strThirdPartyHosts));
        }
        if (nullptr != thirdPartyHosts) {
            delete []thirdPartyHosts;
            thirdPartyHosts = nullptr;
        }
        if (nullptr != thirdPartyHostsSubDomain) {
            delete []thirdPartyHostsSubDomain;
            thirdPartyHostsSubDomain = nullptr;
        }

        thirdPartyHosts = parser.findFirstPartyHosts("facebook.com");
        CHECK(nullptr != thirdPartyHosts);
        if (nullptr != thirdPartyHosts) {
            delete []thirdPartyHosts;
            thirdPartyHosts = nullptr;
        }

        if (0 == i) {
            unsigned int totalSize = 0;
            data = parser.serialize(&totalSize);
            CHECK(nullptr != data);
            CHECK(0 != totalSize);
        }
        else {
            delete []data;
            data = nullptr;
        }
    }
}
