/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef FIRST_PARTY_HOST_H_
#define FIRST_PARTY_HOST_H_

#include "hashFn.h"

static HashFn sFirstPartyHashFn(19);

struct ST_FIRST_PARTY_HOST
{
public:
    ST_FIRST_PARTY_HOST():
        sFirstPartyHost(nullptr),
        sThirdPartyHosts(nullptr) {
    }

    ST_FIRST_PARTY_HOST(const ST_FIRST_PARTY_HOST &other) {
        if (nullptr != other.sFirstPartyHost) {
            sFirstPartyHost = new char[strlen(other.sFirstPartyHost) + 1];
            strcpy(sFirstPartyHost, other.sFirstPartyHost);
        }
        if (nullptr != other.sThirdPartyHosts) {
            sThirdPartyHosts = new char[strlen(other.sThirdPartyHosts) + 1];
            strcpy(sThirdPartyHosts, other.sThirdPartyHosts);
        }
    }

    ~ST_FIRST_PARTY_HOST() {
        if (nullptr != sFirstPartyHost) {
            delete []sFirstPartyHost;
        }
        if (nullptr != sThirdPartyHosts) {
            delete []sThirdPartyHosts;
        }
    }

    uint64_t hash() const {
        // Calculate hash only on first party host as we will search using it only
        if (!sFirstPartyHost) {
            return 0;
        }

        return sFirstPartyHashFn(sFirstPartyHost, static_cast<int>(strlen(sFirstPartyHost)));

    }

    bool operator==(const ST_FIRST_PARTY_HOST &rhs) const {
        int hostLen = static_cast<int>(strlen(sFirstPartyHost));
        int rhsHostLen = static_cast<int>(strlen(rhs.sFirstPartyHost));

        if (hostLen != rhsHostLen || 0 != memcmp(sFirstPartyHost, rhs.sFirstPartyHost, hostLen)) {
            return false;
        }

        return true;
    }

    // Nothing needs to be updated when a host is added multiple times
    void update(const ST_FIRST_PARTY_HOST&) {}

    uint32_t serialize(char* buffer) {
        uint32_t size = 0;
        unsigned int pos = 0;
        char sz[32];
        uint32_t dataLenSize = 1 + snprintf(sz, sizeof(sz), "%x", (unsigned int)strlen(sFirstPartyHost));
        if (buffer) {
            memcpy(buffer + pos, sz, dataLenSize);
        }
        pos += dataLenSize;
        if (buffer) {
            memcpy(buffer + pos, sFirstPartyHost, strlen(sFirstPartyHost));
        }
        pos += strlen(sFirstPartyHost);

        dataLenSize = 1 + snprintf(sz, sizeof(sz), "%x", (unsigned int)strlen(sThirdPartyHosts));
        if (buffer) {
            memcpy(buffer + pos, sz, dataLenSize);
        }
        pos += dataLenSize;
        if (buffer) {
            memcpy(buffer + pos, sThirdPartyHosts, strlen(sThirdPartyHosts));
        }
        size = pos + (unsigned int)strlen(sThirdPartyHosts);

        return size;
    }

    uint32_t deserialize(char *buffer, uint32_t bufferSize) {
        uint32_t size = 0;

        if (!buffer || 0 == bufferSize) {
            return size;
        }

        // Get first party host
        unsigned int firstPartyHostLength = 0;
        sscanf(buffer, "%x", &firstPartyHostLength);
        if (sFirstPartyHost) {
            delete []sFirstPartyHost;
        }
        size = (unsigned int)strlen(buffer) + 1;
        sFirstPartyHost = new char[firstPartyHostLength + 1];
        if (!sFirstPartyHost) {
            return size;
        }
        memcpy(sFirstPartyHost, buffer + size, firstPartyHostLength);
        sFirstPartyHost[firstPartyHostLength] = '\0';
        size += firstPartyHostLength;

        // Get third party hosts
        unsigned int thirdPartyHostLength = 0;
        sscanf(buffer + size, "%x", &thirdPartyHostLength);
        if (sThirdPartyHosts) {
            delete []sThirdPartyHosts;
        }
        size += strlen(buffer + size) + 1;
        sThirdPartyHosts = new char[thirdPartyHostLength + 1];
        if (!sThirdPartyHosts) {
            return size;
        }
        memcpy(sThirdPartyHosts, buffer + size, thirdPartyHostLength);
        sThirdPartyHosts[thirdPartyHostLength] = '\0';
        size += thirdPartyHostLength;

        return size;
    }

    char* sFirstPartyHost;
    // Third party hosts are comma separated
    char* sThirdPartyHosts;
};

#endif  //FIRST_PARTY_HOST_H_
