/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TPPARSER_H_
#define TPPARSER_H_

#include "HashSet.h"
#include "TrackerData.h"
#include "FirstPartyHost.h"


class CTPParser {
public:
    CTPParser();
    ~CTPParser();

    void addTracker(const char *inputHost);
    // thirdPartyHosts comma separated list
    void addFirstPartyHosts(const char *inputHost, const char *thirdPartyHosts);
    bool matchesTracker(const char *firstPartyHost, const char *inputHost);
    // Returns third party hosts as comma separated list
    // The returned buffer should be deleted.
    char* findFirstPartyHosts(const char *inputHost);

    // Serializes the parsed data into a single buffer.
    // The returned buffer should be deleted.
    char* serialize(unsigned int* totalSize);
    // Deserializes the buffer, a size is not needed since a serialized
    // buffer is self described
    bool deserialize(char *buffer);

private:
    bool trackerExist(const char *inputHost);
    char* firstPartyHosts(const char *inputHost);

    HashSet<ST_TRACKER_DATA> mTrackers;
    HashSet<ST_FIRST_PARTY_HOST> mFirstPartyHosts;
};

#endif  //TPPARSER_H_
