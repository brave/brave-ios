/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <time.h>
#include <cerrno>
#include <algorithm>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iterator>
#include "./ad_block_client.h"
#include "./bad_fingerprint.h"

using std::string;
using std::cout;
using std::endl;

string getFileContents(const char *filename) {
  std::ifstream in(filename, std::ios::in);
  if (in) {
    std::ostringstream contents;
    contents << in.rdbuf();
    in.close();
    return(contents.str());
  }
  throw(errno);
}

void doSiteList(AdBlockClient *pClient, bool outputPerf) {
  AdBlockClient &client = *pClient;
  std::string && siteList = getFileContents("./test/data/sitelist.txt");
  std::stringstream ss(siteList);
  std::istream_iterator<std::string> begin(ss);
  std::istream_iterator<std::string> end;
  std::vector<std::string> sites(begin, end);

  // This is the site who's URLs are being checked, not the domain of
  // the URL being checked.
  const char *currentPageDomain = "brianbondy.com";

  int numBlocks = 0;
  int numSkips = 0;
  const clock_t beginTime = clock();
  std::for_each(sites.begin(), sites.end(), [&client, currentPageDomain,
      &numBlocks, &numSkips](std::string const &urlToCheck) {
    if (client.matches(urlToCheck.c_str(), FONoFilterOption,
          currentPageDomain)) {
      ++numBlocks;
    } else {
      ++numSkips;
    }
  });
  if (outputPerf) {
    cout << "Time: " << float(clock() - beginTime)
      / CLOCKS_PER_SEC << "s" << endl;
    cout << "num blocks: " << numBlocks << ", num skips: " << numSkips << endl;
    cout << "False Positives: " << client.numFalsePositives
      << ", exception false positives: "
      << client.numExceptionFalsePositives << endl;
    cout << "Bloom filter saves: " << client.numBloomFilterSaves
      << ", exception bloom filter saves: "
      << client.numExceptionBloomFilterSaves << endl;
  }
}

int main(int argc, char**argv) {
  std::string && easyListTxt =
    getFileContents("./test/data/easylist.txt");
  std::string && braveUnblockTxt =
    getFileContents("./test/data/brave-unbreak.txt");
  std::string && ublockUnblockTxt =
    getFileContents("./test/data/ublock-unbreak.txt");
  std::string && spam404MainBlacklistTxt =
    getFileContents("./test/data/spam404-main-blacklist.txt");
  std::string && disconnectSimpleMalwareTxt =
    getFileContents("./test/data/disconnect-simple-malware.txt");

  cout << endl
    << "-------------\n"
    << "  AD BLOCK   \n"
    << "-------------\n"
    << endl;

  AdBlockClient adBlockClient;
  adBlockClient.parse(easyListTxt.c_str());
  adBlockClient.parse(ublockUnblockTxt.c_str());
  adBlockClient.parse(braveUnblockTxt.c_str());
  doSiteList(&adBlockClient, true);

  cout << endl
    << "-------------\n"
    << "SAFE BROWSING\n"
    << "-------------\n"
    << endl;

  AdBlockClient safeBrowsingClient;
  safeBrowsingClient.parse(spam404MainBlacklistTxt.c_str());
  safeBrowsingClient.parse(disconnectSimpleMalwareTxt.c_str());
  doSiteList(&safeBrowsingClient, true);

  cout << endl
    << "-------------\n"
    << "generating bad fingerprints list"
    << endl;

  AdBlockClient allClient;
  allClient.enableBadFingerprintDetection();
  allClient.parse(easyListTxt.c_str());
  allClient.parse(ublockUnblockTxt.c_str());
  allClient.parse(braveUnblockTxt.c_str());
  allClient.parse(spam404MainBlacklistTxt.c_str());
  allClient.parse(disconnectSimpleMalwareTxt.c_str());
  doSiteList(&allClient, false);
  allClient.badFingerprintsHashSet->generateHeader("bad_fingerprints.h");

  return 0;
}
