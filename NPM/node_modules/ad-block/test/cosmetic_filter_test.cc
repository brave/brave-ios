/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <fstream>
#include <sstream>
#include <cerrno>
#include <algorithm>
#include <iostream>
#include <set>
#include "./CppUnitLite/TestHarness.h"
#include "./CppUnitLite/Test.h"
#include "./ad_block_client.h"
#include "./util.h"

using std::cout;
using std::endl;

bool testCosmeticFilter(const char *rawFilter, FilterType expectedFilterType,
    const char *expectedData, const char *domainList = nullptr) {
  Filter filter;
  parseFilter(rawFilter, &filter);

  if (filter.filterType != expectedFilterType) {
    cout << "Actual filter type: " << filter.filterType
      << endl << "Expected: " << expectedFilterType << endl;
    return false;
  }

  if (strcmp(filter.data, expectedData)) {
    cout << "Actual filter data: " << filter.data
      << endl << "Expected: " << expectedData << endl;
    return false;
  }

  if (domainList && !filter.domainList) {
    cout << "Expected domains but none were parsed" << endl;
  } else if (!domainList && filter.domainList) {
    cout << "Domains found but expected none" << endl;
  } else if (domainList && filter.domainList
      && strcmp(domainList, filter.domainList)) {
    cout << "Actual domains: " << filter.domainList
      << endl << "Expected: " << domainList << endl;
  }

  return true;
}

TEST(parser, parseCosmeticFilters) {
  CHECK(testCosmeticFilter("###A9AdsMiddleBoxTop",
        FTElementHiding, "#A9AdsMiddleBoxTop"));
  CHECK(testCosmeticFilter("#@#A9AdsMiddleBoxTop",
        FTElementHidingException, "#A9AdsMiddleBoxTop"));
  CHECK(testCosmeticFilter("domain1.com,domain2.com###A9AdsMiddleBoxTop",
        FTElementHiding, "#A9AdsMiddleBoxTop", "domain1.com,domain2.com"));
  CHECK(testCosmeticFilter("domain1.com,domain2.com#@#A9AdsMiddleBoxTop",
        FTElementHidingException,
        "#A9AdsMiddleBoxTop", "domain1.com,domain2.com"));
}
