/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "TPParser.h"

CTPParser::CTPParser():
    mTrackers(2196),
    mFirstPartyHosts(1016) {
}

CTPParser::~CTPParser() {
}

void CTPParser::addTracker(const char *inputHost) {
    if (nullptr == inputHost) {
        return;
    }
    ST_TRACKER_DATA trackerData;
    trackerData.sHost = new char[strlen(inputHost) + 1];
    strcpy(trackerData.sHost, inputHost);

    if (nullptr == trackerData.sHost) {
        return;
    }

    mTrackers.add(trackerData);
}

void CTPParser::addFirstPartyHosts(const char *inputHost, const char *thirdPartyHosts) {
    if (nullptr == inputHost || nullptr == thirdPartyHosts) {
        return;
    }

    ST_FIRST_PARTY_HOST firstPartyHost;
    firstPartyHost.sFirstPartyHost = new char[strlen(inputHost) + 1];
    firstPartyHost.sThirdPartyHosts = new char[strlen(thirdPartyHosts) + 1];

    if (nullptr == firstPartyHost.sFirstPartyHost || nullptr == firstPartyHost.sThirdPartyHosts) {
        return;
    }
    strcpy(firstPartyHost.sThirdPartyHosts, thirdPartyHosts);

    bool bCopied = false;
    if (0 == strncmp(inputHost, "http://", 7) && strlen(inputHost) > 7) {
        strcpy(firstPartyHost.sFirstPartyHost, inputHost + 7);
        bCopied = true;
    }
    else if (0 == strncmp(inputHost, "https://", 8) && strlen(inputHost) > 8) {
        strcpy(firstPartyHost.sFirstPartyHost, inputHost + 8);
        bCopied = true;
    }
    if (0 == strncmp(firstPartyHost.sFirstPartyHost, "www.", 4) && strlen(firstPartyHost.sFirstPartyHost) > 4) {
        char* newFirstPartyHost = new char[strlen(firstPartyHost.sFirstPartyHost)];
        if (nullptr == newFirstPartyHost) {
            delete []firstPartyHost.sFirstPartyHost;
            delete []firstPartyHost.sThirdPartyHosts;
            
            return;
        }
        strcpy(newFirstPartyHost, firstPartyHost.sFirstPartyHost + 4);
        strcpy(firstPartyHost.sFirstPartyHost, newFirstPartyHost);
        bCopied = true;
        delete []newFirstPartyHost;
    }
    if (!bCopied) {
        strcpy(firstPartyHost.sFirstPartyHost, inputHost);
    }
    if (0 != strlen(firstPartyHost.sFirstPartyHost) &&
        '/' == firstPartyHost.sFirstPartyHost[strlen(firstPartyHost.sFirstPartyHost) - 1]) {
        firstPartyHost.sFirstPartyHost[strlen(firstPartyHost.sFirstPartyHost) - 1] = '\0';
    }

    mFirstPartyHosts.add(firstPartyHost);
}

bool CTPParser::trackerExist(const char *inputHost) {
    ST_TRACKER_DATA trackerData;
    trackerData.sHost = new char[strlen(inputHost) + 1];
    if (nullptr == trackerData.sHost) {
        return false;
    }
    strcpy(trackerData.sHost, inputHost);

    return mTrackers.exists(trackerData);
}

bool CTPParser::matchesTracker(const char *firstPartyHost, const char *inputHost) {
    if (nullptr == inputHost || nullptr == firstPartyHost) {
        return false;
    }
    char* firstPartyHostToChek = (char*)firstPartyHost;
    char* inputHostToCheck = (char*)inputHost;
    size_t countToCompare = strlen("www.");
    if (0 == strncmp(firstPartyHostToChek, "www.", countToCompare)) {
        firstPartyHostToChek = firstPartyHostToChek + countToCompare;
    }
    if (0 == strncmp(inputHostToCheck, "www.", countToCompare)) {
        inputHostToCheck = inputHostToCheck + countToCompare;
    }
    if (0 == strcmp(firstPartyHostToChek, inputHostToCheck)) {
        return false;
    }

    bool exist = trackerExist(inputHost);
    if (!exist) {
        unsigned int len = (unsigned int)strlen(inputHost);
        unsigned positionToStart = 0;
        do {
            unsigned int firstDotPos = positionToStart;
            while (firstDotPos < len) {
                if ('.' == inputHost[firstDotPos]) {
                    break;
                }
                firstDotPos++;
            }
            if (firstDotPos >= len || '.' != inputHost[firstDotPos]) {
                break;
            }
            unsigned int secondDotPos = firstDotPos + 1;
            while (secondDotPos < len) {
                if ('.' == inputHost[secondDotPos]) {
                    break;
                }
                secondDotPos++;
            }
            if (secondDotPos >= len || '.' != inputHost[secondDotPos]) {
                break;
            }
            exist = trackerExist(inputHost + firstDotPos + 1);
            if (exist) {
                break;
            }
            positionToStart = firstDotPos + 1;
        } while (true);
    }

    return exist;
}

char* CTPParser::firstPartyHosts(const char *inputHost)
{
    ST_FIRST_PARTY_HOST firstPartyHost;
    firstPartyHost.sFirstPartyHost = new char[strlen(inputHost) + 1];
    firstPartyHost.sThirdPartyHosts = new char[1];

    if (nullptr == firstPartyHost.sFirstPartyHost || nullptr == firstPartyHost.sThirdPartyHosts) {
        return nullptr;
    }
    strcpy(firstPartyHost.sFirstPartyHost, inputHost);
    strcpy(firstPartyHost.sThirdPartyHosts, "");


    ST_FIRST_PARTY_HOST* foundFirstPartyHost = mFirstPartyHosts.find(firstPartyHost);

    if (nullptr == foundFirstPartyHost) {
        return nullptr;
    }

    return foundFirstPartyHost->sThirdPartyHosts;
}

char* CTPParser::findFirstPartyHosts(const char *inputHost) {
    if (nullptr == inputHost) {
        return nullptr;
    }

    char* result = nullptr;
    char* hosts = firstPartyHosts(inputHost);
    if (hosts) {
        result = new char[strlen(hosts) + 1];
        if (!result) {
            return nullptr;
        }
        strcpy(result, hosts);
    }

    unsigned int len = (unsigned int)strlen(inputHost);
    unsigned positionToStart = 0;
    do {
        unsigned int firstDotPos = positionToStart;
        while (firstDotPos < len) {
            if ('.' == inputHost[firstDotPos]) {
                break;
            }
            firstDotPos++;
        }
        if (firstDotPos >= len || '.' != inputHost[firstDotPos]) {
            break;
        }
        unsigned int secondDotPos = firstDotPos + 1;
        while (secondDotPos < len) {
            if ('.' == inputHost[secondDotPos]) {
                break;
            }
            secondDotPos++;
        }
        if (secondDotPos >= len || '.' != inputHost[secondDotPos]) {
            break;
        }
        hosts = firstPartyHosts(inputHost + firstDotPos + 1);
        if (hosts) {
            unsigned int tempLen = (unsigned int)strlen(hosts) + 1;
            if (result) {
                tempLen += strlen(result) + 1;
            }
            char* tempResult = new char[tempLen];
            if (!tempResult) {
                return nullptr;
            }
            tempResult[0] = '\0';
            if (result) {
                strcat(tempResult, result);
                strcat(tempResult, ",");
                delete []result;
            }
            strcat(tempResult, hosts);
            result = tempResult;
        }
        positionToStart = firstDotPos + 1;
    } while (true);

    return result;
}

// Returns a newly allocated buffer, caller must manually delete[] the buffer
char* CTPParser::serialize(unsigned int* totalSize) {
    *totalSize = 0;

    uint32_t trackersSize = 0;
    uint32_t firstPartiesSize = 0;
    char* trackers = mTrackers.serialize(&trackersSize);
    char* firstParties = mFirstPartyHosts.serialize(&firstPartiesSize);

    if (!trackers || !firstParties) {
        if (trackers) {
            delete []trackers;
        }
        if (firstParties) {
            delete []firstParties;
        }

        return nullptr;
    }

    *totalSize = sizeof(trackersSize) + trackersSize + sizeof(firstPartiesSize) + firstPartiesSize + 2;

    unsigned int pos = 0;
    char* result = new char[*totalSize];
    if (!result) {
        delete []trackers;
        delete []firstParties;

        return nullptr;
    }
    memset(result, 0, *totalSize);

    char sz[32];
    uint32_t dataLenSize = 1 + snprintf(sz, sizeof(sz), "%x", trackersSize);
    memcpy(result + pos, sz, dataLenSize);
    pos += dataLenSize;

    memcpy(result + pos, trackers, trackersSize);
    pos += trackersSize;

    dataLenSize = 1 + snprintf(sz, sizeof(sz), "%x", firstPartiesSize);
    memcpy(result + pos, sz, dataLenSize);
    pos += dataLenSize;
    memcpy(result + pos, firstParties, firstPartiesSize);

    delete []trackers;
    delete []firstParties;

    return result;
}

bool CTPParser::deserialize(char *buffer) {
    if (!buffer) {
        return false;
    }

    uint32_t trackersSize = 0;
    unsigned int pos = 0;
    sscanf(buffer, "%x", &trackersSize);
    pos += strlen(buffer) + 1;

    if (!mTrackers.deserialize(buffer + pos, trackersSize)) {
        return false;
    }
    pos += trackersSize;

    uint32_t firstPartiesSize = 0;
    sscanf(buffer + pos, "%x", &firstPartiesSize);
    pos += strlen(buffer + pos) + 1;
    if (!mFirstPartyHosts.deserialize(buffer + pos, firstPartiesSize)) {
        return false;
    }
    
    return true;
}
