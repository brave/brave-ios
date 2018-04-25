[![Build Status](https://travis-ci.org/brave/ad-block.svg?branch=master)](https://travis-ci.org/brave/ad-block)

# Brave Ad Block

Native node module, and C++ library for Adblock Plus filter parsing for lists like EasyList.

It uses a bloom filter and Rabin-Karp algorithm to be super fast.

## To include brave/ad-block in your project:

```
npm install --save ad-block
```

## JS Sample

```javascript

const {AdBlockClient, FilterOptions} = require('ad-block')
const client = new AdBlockClient()
client.parse('/public/ad/*$domain=slashdot.org')
client.parse('/public/ad3/*$script')
var b1 = client.matches('http://www.brianbondy.com/public/ad/some-ad', FilterOptions.script, 'slashdot.org')
var b2 = client.matches('http://www.brianbondy.com/public/ad/some-ad', FilterOptions.script, 'digg.com')
console.log('public/ad/* should match b1.  Actual: ', b1)
console.log('public/ad/* should not match b2.  Actual: ', b2)
```

## C++ Sample

```c++
#include "ad_block_client.h"
#include <algorithm>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iostream>
#include <string>

using namespace std;

string getFileContents(const char *filename)
{
  ifstream in(filename, ios::in);
  if (in) {
    ostringstream contents;
    contents << in.rdbuf();
    in.close();
    return(contents.str());
  }
  throw(errno);
}

void writeFile(const char *filename, const char *buffer, int length)
{
  ofstream outFile(filename, ios::out | ios::binary);
  if (outFile) {
    outFile.write(buffer, length);
    outFile.close();
    return;
  }
  throw(errno);
}


int main(int argc, char**argv) {
  std::string &&easyListTxt = getFileContents("./test/data/easylist.txt");
  const char *urlsToCheck[] = {
    // ||pagead2.googlesyndication.com^$~object-subrequest
    "http://pagead2.googlesyndication.com/pagead/show_ads.js",
    // Should be blocked by: ||googlesyndication.com/safeframe/$third-party
    "http://tpc.googlesyndication.com/safeframe/1-0-2/html/container.html",
    // Should be blocked by: ||googletagservices.com/tag/js/gpt_$third-party
    "http://www.googletagservices.com/tag/js/gpt_mobile.js",
    // Shouldn't be blocked
    "http://www.brianbondy.com"
  };

  // This is the site who's URLs are being checked, not the domain of the URL being checked.
  const char *currentPageDomain = "slashdot.org";

  // Parse easylist
  AdBlockClient client;
  client.parse(easyListTxt.c_str());

  // Do the checks
  std::for_each(urlsToCheck, urlsToCheck + sizeof(urlsToCheck) / sizeof(urlsToCheck[0]), [&client, currentPageDomain](std::string const &urlToCheck) {
    if (client.matches(urlToCheck.c_str(), FONoFilterOption, currentPageDomain)) {
      cout << urlToCheck << ": You should block this URL!" << endl;
    } else {
      cout << urlToCheck << ": You should NOT block this URL!" << endl;
    }
  });

  int size;
  // This buffer is allocate on the heap, you must call delete[] when you're done using it.
  char *buffer = client.serialize(size);
  writeFile("./ABPFilterParserData.dat", buffer, size);

  AdBlockClient client2;
  // Deserialize uses the buffer directly for subsequent matches, do not free until all matches are done.
  client2.deserialize(buffer);
  // Prints the same as client.matches would
  std::for_each(urlsToCheck, urlsToCheck + sizeof(urlsToCheck) / sizeof(urlsToCheck[0]), [&client2, currentPageDomain](std::string const &urlToCheck) {
    if (client2.matches(urlToCheck.c_str(), FONoFilterOption, currentPageDomain)) {
      cout << urlToCheck << ": You should block this URL!" << endl;
    } else {
      cout << urlToCheck << ": You should NOT block this URL!" << endl;
    }
  });
  delete[] buffer;
  return 0;
}
```


## Util for checking URLs

- Basic checking a URL:
  `node scripts/check.js  --host www.cnet.com --location https://s0.2mdn.net/instream/html5/ima3.js`
- Checking a URL with discovery:
  `node scripts/check.js  --host www.cnet.com --location "https://slashdot.org?t=1&ad_box_=2" --discover`
- Checking a URL against a particular adblock list:
  `node scripts/check.js  --uuid 03F91310-9244-40FA-BCF6-DA31B832F34D --host slashdot.org --location https://s.yimg.jp/images/ds/ult/toppage/rapidjp-1.0.0.js`
- Checking a URL from a loaded DAT file:
  `node scripts/check.js --dat ./out/SafeBrowsingData.dat --host excellentmovies.net --location https://excellentmovies.net`
- Checking a list of URLs:
  `node scripts/check.js  --host www.cnet.com --list ./test/data/sitelist.txt`
- Checking a list of URLS with discovery:
  `node scripts/check.js  --host www.cnet.com --list ./test/data/sitelist.txt --discover`


## Developing brave/ad-block

1. Clone the git repository from GitHub:

    `git clone --recursive https://github.com/brave/ad-block`

2. Open the working directory:

    `cd ad-block`

3. Install the Node (v5+) dependencies:

    `npm install`


## Make the node module

```
make
```

## Running sample (which also generates a .dat file for deserializing)

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
