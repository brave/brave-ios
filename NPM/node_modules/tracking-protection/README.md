#tracking-protection

C++ tracking protection filter parser for lists like
https://github.com/disconnectme/disconnect-tracking-protection/blob/master/services.json

## Setup

```
npm install --save tracking-protection
```

## Installation

1. Clone the git repository from GitHub:

        git clone https://github.com/SergeyZhukovsky/tracking-protection

2. Open the working directory:

        cd tracking-protection

3. Install the Node (v5+) dependencies:

        npm install

## Sample

```c++
#include <iostream>
#include "./TPParser.h"

using std::cout;
using std::endl;

int main(int argc, char **argv) {
    CTPParser parser;
    parser.addTracker("facebook.com");
    parser.addTracker("facebook.de");

    // Prints matches
    if (parser.matchesTracker("facebook.com")) {
        cout << "matches" << endl;
    }
    else {
        cout << "does not match" << endl;
    }

    // Prints does not match
    if (parser.matchesTracker("facebook1.com")) {
        cout << "matches" << endl;
    } else {
        cout << "does not match" << endl;
    }

    // Prints does not match
    if (parser.matchesTracker("subdomain.google-analytics.com.")) {
        cout << "matches" << endl;
    } else {
        cout << "does not match" << endl;
    }

    parser.addFirstPartyHosts("facebook.com", "facebook.fr,facebook.de");
    parser.addFirstPartyHosts("google.com", "2mdn.net,admeld.com");
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
    parser.deserialize(data);

    // Prints matches
    if (parser.matchesTracker("facebook.com")) {
        cout << "matches" << endl;
    }
    else {
        cout << "does not match" << endl;
    }
    // Prints does not match
    if (parser.matchesTracker("facebook1.com")) {
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

    return 0;
}
```

## Build everything in release

```
make
```

## Build everything in debug

```
make build-debug
```

## Running sample

```
make sample
```

## Running tests

```
make test
```

## Clearing build files
```
make clean
```
