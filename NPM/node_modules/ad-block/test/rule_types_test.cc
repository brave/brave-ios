/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <string.h>
#include <fstream>
#include <sstream>
#include <string>
#include <cerrno>
#include <algorithm>
#include <iostream>
#include <set>
#include "./CppUnitLite/TestHarness.h"
#include "./ad_block_client.h"
#include "./util.h"

using std::set;
using std::string;

bool testComment(const char *rawFilter) {
  Filter filter;
  parseFilter(rawFilter, &filter);
  return filter.filterType == FTComment;
}

TEST(ruleTypes, commentRules) {
  set<string> commentRules {
    "[Adblock Plus 2.0]",
    "! Checksum: nVIXktYXKU6M+cu+Txkhuw",
    "!/cb.php?sub$script,third-party",
    "!@@/cb.php?sub",
    "!###ADSLOT_SKYSCRAPER",
    "! *** easylist:easylist/easylist_whitelist_general_hide.txt ***",
    "   !###ADSLOT_SKYSCRAPER",
  };

  std::for_each(commentRules.begin(), commentRules.end(),
      [this, &result_](string const &s) {
    CHECK(testComment(s.c_str()));
  });
}

bool testElementHidingRule(const char *rawFilter, bool exception) {
  Filter filter;
  parseFilter(rawFilter, &filter);
  if (exception) {
    return filter.filterType == FTElementHidingException;
  }
  return filter.filterType == FTElementHiding;
}

TEST(ruleTypes, elementHidingRules) {
  set<string> elementHidingRules {
    "@@###ADSLOT_SKYSCRAPER",
    "   ###ADSLOT_SKYSCRAPER",
    "###ADSLOT_SKYSCRAPER",
    "##.adsBox",
    "##a[href^=\"http://affiliate.sometracker.com/\"]",
  };

  std::for_each(elementHidingRules.begin(), elementHidingRules.end(),
      [this, &result_](string const &s) {
    CHECK(testElementHidingRule(s.c_str(), false));
  });
}

TEST(ruleTypes, elementHidingExceptionRules) {
  set<string> elementHidingExceptionRules {
    "eee.se#@##adspace_top",
    "domain1.com,domain2.com#@##adwrapper",
    "edgesuitedomain.net#@##ad-unit",
    "mydomain.com#@#.ad-unit",
  };

  std::for_each(elementHidingExceptionRules.begin(),
      elementHidingExceptionRules.end(), [this, &result_](string const &s) {
    CHECK(testElementHidingRule(s.c_str(), true));
  });
}
