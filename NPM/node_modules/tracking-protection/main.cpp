/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include <fstream>
#include "./TPParser.h"

using std::cout;
using std::endl;

int main(int argc, char **argv) {
    {
        CTPParser parser;
        parser.addTracker("facebook.com");
        parser.addTracker("facebook.de");

        // Prints matches
        if (parser.matchesTracker("facebook1.com", "facebook.com")) {
            cout << "matches" << endl;
        }
        else {
            cout << "does not match" << endl;
        }
        
        // Prints does not match
        if (parser.matchesTracker("facebook.com", "facebook.com")) {
            cout << "matches" << endl;
        }
        else {
            cout << "does not match" << endl;
        }

        // Prints does not match
        if (parser.matchesTracker("facebook.com", "facebook1.com")) {
            cout << "matches" << endl;
        } else {
            cout << "does not match" << endl;
        }

        // Prints does not match
        if (parser.matchesTracker("facebook.com", "subdomain.google-analytics.com")) {
            cout << "matches" << endl;
        } else {
            cout << "does not match" << endl;
        }

        parser.addFirstPartyHosts("http://www.facebook.com/", "facebook.fr,facebook.de");
        parser.addFirstPartyHosts("http://google.com/", "2mdn.net,admeld.com");
        parser.addFirstPartyHosts("https://twitter.com/", "2mdn.net,admeld.com");
        parser.addFirstPartyHosts("subdomain.google.com", "facebook.fr,facebook.de");

        // Returns combined result of third party hosts for "google.com" and for "subdomain.google.com"
        // "facebook.fr,facebook.de,2mdn.net,admeld.com"
        char* thirdPartyHosts = parser.findFirstPartyHosts("subdomain.google.com");
        if (nullptr != thirdPartyHosts) {
            cout << thirdPartyHosts << endl;
            delete []thirdPartyHosts;
        }

        unsigned int totalSize = 0;
        // Serialize data
        char* data = parser.serialize(&totalSize);

        // Deserialize data
        if (!parser.deserialize(data)) {
            cout << "deserialize failed";
            
            return 0;
        }

        // Prints matches
        if (parser.matchesTracker("facebook1.com", "facebook.com")) {
            cout << "matches" << endl;
        }
        else {
            cout << "does not match" << endl;
        }
        // Prints does not match
        if (parser.matchesTracker("facebook.com", "facebook1.com")) {
            cout << "matches" << endl;
        } else {
            cout << "does not match" << endl;
        }

        // Prints "2mdn.net,admeld.com"
        thirdPartyHosts = parser.findFirstPartyHosts("google.com");
        if (nullptr != thirdPartyHosts) {
            cout << thirdPartyHosts << endl;
        }

        if (data) {
            delete []data;
        }
    }
    for (int i = 0; i < 10000; i++)
    {
        std::ifstream ifs("/Users/serg/Downloads/TrackingProtection.dat", std::ios_base::in);
        if (ifs) {
            std::streampos begin = ifs.tellg();
            ifs.seekg (0, std::ios::end);
            std::streampos end = ifs.tellg();
            ifs.seekg (0, std::ios::beg);
            unsigned int size = end - begin;
            if (0 != size) {
                char* data = new char[size];
                ifs.read(data, size);
                ifs.close();

                CTPParser parser;
                if (!parser.deserialize(data)) {
                    cout << "deserialize failed";
                    
                    return 0;
                }

                // Prints matches
                if (parser.matchesTracker("facebook1.com", "facebook.com")) {
                    cout << "matches" << endl;
                }
                else {
                    cout << "does not match" << endl;
                }
                // Prints does not match
                if (parser.matchesTracker("facebook.com", "facebook1.com")) {
                    cout << "matches" << endl;
                } else {
                    cout << "does not match" << endl;
                }

                // Prints "2mdn.net,admeld.com"
                char* thirdPartyHosts = parser.findFirstPartyHosts("mobile.twitter.com");
                if (nullptr != thirdPartyHosts) {
                    cout << thirdPartyHosts << endl;
                }
                
                if (parser.matchesTracker("cnet.com", "tags.tiqcdn.com")) {
                    cout << "matches cnet.com to tags.tiqcdn.com" << endl;
                }
                else {
                    cout << "does not match cnet.com to tags.tiqcdn.com" << endl;
                }

                delete []data;
            }
        }
        cout << i;
    }

    return 0;
}
