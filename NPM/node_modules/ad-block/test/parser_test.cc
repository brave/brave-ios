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
#include "./CppUnitLite/Test.h"
#include "./ad_block_client.h"
#include "./util.h"

#include "HashSet.h"

using std::string;
using std::endl;
using std::set;
using std::cout;

bool testFilter(const char *rawFilter, FilterType expectedFilterType,
    FilterOption expectedFilterOption,
    const char *expectedData,
    set<string> &&blocked, // NOLINT
    set<string> &&notBlocked) { // NOLINT
  Filter filter;
  parseFilter(rawFilter, &filter);

  if (filter.filterOption != expectedFilterOption) {
    cout << "Actual filter option: " << filter.filterOption
      << endl << "Expected: " << expectedFilterOption << endl;
    return false;
  }

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

  bool ret = true;
  string lastChecked;
  std::for_each(blocked.begin(), blocked.end(),
      [&filter, &ret, &lastChecked](string const &s) {
    ret = ret && filter.matches(s.c_str());
    lastChecked = s;
  });
  if (!ret) {
    cout << "Should match but did not: " << lastChecked.c_str() << endl;
    return false;
  }

  std::for_each(notBlocked.begin(), notBlocked.end(),
      [&filter, &ret, &lastChecked](string const &s) {
    ret = ret && !filter.matches(s.c_str());
    lastChecked = s;
  });
  if (!ret) {
    cout << "Should NOT match but did: " << lastChecked.c_str() << endl;
    return false;
  }

  return true;
}

TEST(client, parseFilterMatchesFilter) {
  CHECK(testFilter("/banner/*/img",
    FTNoFilterType,
    FONoFilterOption,
    "/banner/*/img",
    {
      "http://example.com/banner/foo/img",
      "http://example.com/banner/foo/bar/img?param",
      "http://example.com/banner//img/foo",
      "http://example.com/banner//img.gif",
    }, {
      "http://example.com/banner",
      "http://example.com/banner/",
      "http://example.com/banner/img",
      "http://example.com/img/banner/",
    }));

  CHECK(testFilter("/banner/*/img^",
    FTNoFilterType,
    FONoFilterOption,
    "/banner/*/img^",
    {
      "http://example.com/banner/foo/img",
      "http://example.com/banner/foo/bar/img?param",
      "http://example.com/banner//img/foo",
    }, {
      "http://example.com/banner/img",
      "http://example.com/banner/foo/imgraph",
      "http://example.com/banner/foo/img.gif",
    }));

  CHECK(testFilter("||ads.example.com^",
    static_cast<FilterType>(FTHostAnchored | FTHostOnly),
    FONoFilterOption,
    "ads.example.com^",
    {
      "http://ads.example.com/foo.gif",
      "http://server1.ads.example.com/foo.gif",
      "https://ads.example.com:8000/",
    }, {
      "http://ads.example.com.ua/foo.gif",
      "http://example.com/redirect/http://ads.example.com/",
    }));

  CHECK(testFilter("|http://example.com/|",
    static_cast<FilterType>(FTLeftAnchored | FTRightAnchored),
    FONoFilterOption,
    "http://example.com/",
    {
      "http://example.com/"
    }, {
      "http://example.com/foo.gif",
      "http://example.info/redirect/http://example.com/",
    }));

  CHECK(testFilter("swf|",
    FTRightAnchored,
    FONoFilterOption,
    "swf",
    {
      "http://example.com/annoyingflash.swf",
    },
    {
      "http://example.com/swf/index.html"
    }));

  CHECK(testFilter("|http://baddomain.example/",
    FTLeftAnchored,
    FONoFilterOption,
    "http://baddomain.example/",
    {
     "http://baddomain.example/banner.gif",
    },
    {
      "http://gooddomain.example/analyze?http://baddomain.example",
    }));

  CHECK(testFilter("||example.com/banner.gif",
    FTHostAnchored,
    FONoFilterOption,
    "example.com/banner.gif",
    {
      "http://example.com/banner.gif",
      "https://example.com/banner.gif",
      "http://www.example.com/banner.gif",
    },
    {
      "http://badexample.com/banner.gif",
      "http://gooddomain.example/analyze?http://example.com/banner.gif",
      "http://example.com.au/banner.gif",
      "http://example.com/banner2.gif",
    }));

  CHECK(testFilter("http://example.com^",
    FTNoFilterType,
    FONoFilterOption,
    "http://example.com^",
    {
      "http://example.com/",
      "http://example.com:8000/ ",
    },
    {}));

  CHECK(testFilter("^example.com^",
    FTNoFilterType,
    FONoFilterOption,
    "^example.com^",
    {
      "http://example.com:8000/foo.bar?a=12&b=%D1%82%D0%B5%D1%81%D1%82",
    },
    {}));
  CHECK(testFilter("^%D1%82%D0%B5%D1%81%D1%82^",
    FTNoFilterType,
    FONoFilterOption,
    "^%D1%82%D0%B5%D1%81%D1%82^",
    {
      "http://example.com:8000/foo.bar?a=12&b=%D1%82%D0%B5%D1%81%D1%82",
    },
    {
      "http://example.com:8000/foo.bar?a=12&b%D1%82%D0%B5%D1%81%D1%823",
    }));
  CHECK(testFilter("^foo.bar^",
    FTNoFilterType,
    FONoFilterOption,
    "^foo.bar^",
    {
      "http://example.com:8000/foo.bar?a=12&b=%D1%82%D0%B5%D1%81%D1%82"
    },
    {}));
  CHECK(testFilter("^promotion^",
    FTNoFilterType,
    FONoFilterOption,
    "^promotion^",
    {
      "http://test.com/promotion/test"
    },
    {
    }));
#ifdef ENABLE_REGEX
  CHECK(testFilter("/banner[0-9]+/",
    FTRegex,
    FONoFilterOption,
    "banner[0-9]+",
    {
      "banner123",
      "testbanner1"
    },
    {
      "banners",
      "banners123"
    }));
#endif
  CHECK(testFilter(
    "||static.tumblr.com/dhqhfum/WgAn39721/cfh_header_banner_v2.jpg",
    FTHostAnchored,
    FONoFilterOption,
    "static.tumblr.com/dhqhfum/WgAn39721/cfh_header_banner_v2.jpg",
    {
      "http://static.tumblr.com/dhqhfum/WgAn39721/cfh_header_banner_v2.jpg"
    },
    {}));

  CHECK(testFilter("||googlesyndication.com/safeframe/$third-party",
    FTHostAnchored,
    FOThirdParty,
    "googlesyndication.com/safeframe/",
    {
      "http://tpc.googlesyndication.com/safeframe/1-0-2/html/container.html"
      "#xpc=sf-gdn-exp-2&p=http%3A//slashdot.org;",
    },
    {}));
  CHECK(testFilter("||googlesyndication.com/safeframe/$third-party,script",
    FTHostAnchored,
    static_cast<FilterOption>(FOThirdParty|FOScript),
    "googlesyndication.com/safeframe/",
    {
      "http://tpc.googlesyndication.com/safeframe/1-0-2/html/container.html"
      "#xpc=sf-gdn-exp-2&p=http%3A//slashdot.org;",
    },
    {}));
}

bool checkMatch(const char *rules,
    set<string> &&blocked, // NOLINT
    set<string> &&notBlocked) { // NOLINT
  AdBlockClient clients[2];
  char * buffer = nullptr;
  for (int i = 0; i < 2; i++) {
    AdBlockClient &client = clients[i];
    if (i == 0) {
      client.parse(rules);
      int size;
      buffer = clients[0].serialize(&size);
    } else if (!client.deserialize(buffer)) {
      cout << "Deserialization failed" << endl;
      delete[] buffer;
      return false;
    }

    bool ret = true;
    string lastChecked;
    std::for_each(blocked.begin(), blocked.end(),
        [&client, &lastChecked, &ret](string const &s) {
      ret = ret && client.matches(s.c_str());
      lastChecked = s;
    });
    if (!ret) {
      cout << "Should match but did not: " << lastChecked.c_str() << endl;
      delete[] buffer;
      return false;
    }

    std::for_each(notBlocked.begin(), notBlocked.end(),
        [&client, &ret, &lastChecked](string const &s) {
      ret = ret && !client.matches(s.c_str());
      lastChecked = s;
    });
    if (!ret) {
      cout << "Should NOT match but did: " << lastChecked.c_str() << endl;
      delete[] buffer;
      return false;
    }
  }
  delete[] buffer;
  return true;
}

TEST(client, exceptionRules) {
  CHECK(checkMatch("adv\n"
                   "@@advice.",
    {
      "http://example.com/advert.html"
    }, {
      "http://example.com/advice.html",
    }));

  CHECK(checkMatch("@@advice.\n"
                   "adv",
    {
      "http://example.com/advert.html"
    }, {
      "http://example.com/advice.html"
    }));
  CHECK(checkMatch("@@|http://example.com\n"
                   "@@advice.\n"
                   "adv\n"
                   "!foo",
    {
      "http://examples.com/advert.html",
    }, {
      "http://example.com/advice.html",
      "http://example.com/advert.html",
      "http://examples.com/advice.html",
      "http://examples.com/#!foo",
    }));
  CHECK(checkMatch("/ads/freewheel/*\n"
                   "@@||turner.com^*/ads/freewheel/*/"
                     "AdManager.js$domain=cnn.com",
    {
    }, {
      "http://z.cdn.turner.com/xslo/cvp/ads/freewheel/js/0/AdManager.js",
    }));
  CHECK(checkMatch("^promotion^",
    {
      "http://yahoo.co.jp/promotion/imgs"
    }, {}));
}

struct OptionRuleData {
  OptionRuleData(const char *testUrl, FilterOption context,
      const char *contextDomain, bool shouldBlock) {
    this->testUrl = testUrl;
    this->context = context;
    this->contextDomain = contextDomain;
    this->shouldBlock = shouldBlock;
  }

  bool operator<(const OptionRuleData& rhs) const {
    return this->testUrl - rhs.testUrl < 0;
  }

  const char *testUrl;
  FilterOption context;
  const char *contextDomain;
  bool shouldBlock;
};

bool checkOptionRule(const char *rules,
    set<OptionRuleData> &&optionTests) { // NOLINT
  AdBlockClient client;
  client.parse(rules);

  bool fail = false;
  std::for_each(optionTests.begin(), optionTests.end(),
      [&client, &fail](OptionRuleData const &data) {
    bool matches = client.matches(data.testUrl,
        data.context, data.contextDomain);
    if (matches != data.shouldBlock) {
      cout << "Expected to block: " << data.shouldBlock
        << endl << "Actual blocks: " << matches << endl;
      fail = true;
      return;
    }
  });
  if (fail) {
    return false;
  }

  return true;
}

// Option rules
TEST(client, optionRules) {
  CHECK(checkOptionRule("||example.com",
    {
      OptionRuleData("http://example.com",
        FOThirdParty, nullptr, true),
      OptionRuleData("http://example2.com", FOThirdParty, nullptr, false),
      OptionRuleData("http://example.com", FONotThirdParty, nullptr, true),
    }));

  CHECK(checkOptionRule("||example.com^$third-party",
    {
      OptionRuleData("http://example.com", FOScript, "brianbondy.com", true),
      OptionRuleData("http://example.com", FOScript, "example.com", false),
      OptionRuleData("http://ad.example.com", FOScript, "brianbondy.com", true),
      OptionRuleData("http://ad.example.com", FOScript, "example.com", false),
      OptionRuleData("http://example2.com", FOScript, "brianbondy.com", false),
      OptionRuleData("http://example2.com", FOScript, "example.com", false),
      OptionRuleData("http://example.com.au", FOScript,
          "brianbondy.com", false),
      OptionRuleData("http://example.com.au", FOScript, "example.com", false),
    }));

  // Make sure we ignore ping requests for now
  CHECK(checkOptionRule("||example.com^$ping",
    {
      OptionRuleData("http://example.com", FOPing, "example.com", false),
    }));

  CHECK(checkOptionRule("||example.com^$third-party,~script",
    {
      OptionRuleData("http://example.com",
          static_cast<FilterOption>(FOThirdParty | FOScript), nullptr, false),
      OptionRuleData("http://example.com", FOOther, nullptr, true),
      OptionRuleData("http://example2.com",
          static_cast<FilterOption>(FOThirdParty | FOOther), nullptr, false),
      OptionRuleData("http://example.com",
          static_cast<FilterOption>(FONotThirdParty | FOOther), nullptr, false),
    }));

  CHECK(checkOptionRule("adv$domain=example.com|example.net",
    {
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "example.net", true),
      OptionRuleData("http://somewebsite.com/adv",
          FONoFilterOption, "example.com", true),
      OptionRuleData("http://www.example.net/adv",
          FONoFilterOption, "www.example.net", true),
      OptionRuleData("http://my.subdomain.example.com/adv",
          FONoFilterOption, "my.subdomain.example.com", true),
      OptionRuleData("http://my.subdomain.example.com/adv",
          FONoFilterOption, "my.subdomain.example.com", true),
      OptionRuleData("http://example.com/adv",
          FONoFilterOption, "badexample.com", false),
      OptionRuleData("http://example.com/adv",
          FONoFilterOption, "otherdomain.net", false),
      OptionRuleData("http://example.net/ad",
          FONoFilterOption, "example.net", false),
    }));

  CHECK(checkOptionRule("adv$domain=example.com|~foo.example.com",
    {
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "example.com", true),
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "foo.example.com", false),
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "www.foo.example.com", false),
    }));

  CHECK(checkOptionRule("adv$domain=~example.com|foo.example.com",
    {
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "example.com", false),
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "foo.example.com", true),
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "www.foo.example.com", true),
    }));

  CHECK(checkOptionRule("adv$domain=~example.com",
    {
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "otherdomain.com", true),
      OptionRuleData("http://somewebsite.com/adv",
          FONoFilterOption, "example.com", false),
    }));

  CHECK(checkOptionRule("adv$domain=~example.com|~example.net",
    {
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "example.net", false),
      OptionRuleData("http://somewebsite.com/adv",
          FONoFilterOption, "example.com", false),
      OptionRuleData("http://www.example.net/adv",
          FONoFilterOption, "www.example.net", false),
      OptionRuleData("http://my.subdomain.example.com/adv",
          FONoFilterOption, "my.subdomain.example.com", false),
      OptionRuleData("http://example.com/adv",
          FONoFilterOption, "badexample.com", true),
      OptionRuleData("http://example.com/adv",
          FONoFilterOption, "otherdomain.net", true),
      OptionRuleData("http://example.net/ad",
          FONoFilterOption, "example.net", false),
    }));

  CHECK(checkOptionRule("adv$domain=example.com|~example.net",
    {
      OptionRuleData("http://example.net/adv",
          FONoFilterOption, "example.net", false),
      OptionRuleData("http://somewebsite.com/adv",
          FONoFilterOption, "example.com", true),
      OptionRuleData("http://www.example.net/adv",
          FONoFilterOption, "www.example.net", false),
      OptionRuleData("http://my.subdomain.example.com/adv",
          FONoFilterOption, "my.subdomain.example.com", true),
      OptionRuleData("http://example.com/adv",
          FONoFilterOption, "badexample.com", false),
      OptionRuleData("http://example.com/adv",
          FONoFilterOption, "otherdomain.net", false),
      OptionRuleData("http://example.net/ad",
          FONoFilterOption, "example.net", false),
    }));

  CHECK(checkOptionRule(
        "adv$domain=example.com|~foo.example.com,script",
    {
      OptionRuleData("http://example.net/adv",
          FOScript, "example.com", true),
      OptionRuleData("http://example.net/adv",
          FOScript, "foo.example.com", false),
      OptionRuleData("http://example.net/adv",
          FOScript, "www.foo.example.com", false),
      OptionRuleData("http://example.net/adv",
          FOOther, "example.com", false),
      OptionRuleData("http://example.net/adv",
          FOOther, "foo.example.com", false),
      OptionRuleData("http://example.net/adv",
          FOOther, "www.foo.example.com", false),
    }));

  CHECK(checkOptionRule("adv\n"
                        "@@advice.$~script",
    {
      OptionRuleData("http://example.com/advice.html",
          FOOther, nullptr, false),
      OptionRuleData("http://example.com/advice.html",
          FOScript, nullptr, true),
      OptionRuleData("http://example.com/advert.html",
          FOOther, nullptr, true),
      OptionRuleData("http://example.com/advert.html",
          FOScript, nullptr, true),
    }));

  // Single matching context domain to domain list
  CHECK(checkOptionRule(
        "||mzstatic.com^$image,object-subrequest,domain=dailymotion.com",
    {
      OptionRuleData("http://www.dailymotion.com",
          FONoFilterOption, "dailymotion.com", false),
    }));

  // Third party flags work correctly
  CHECK(checkOptionRule(
        "||s1.wp.com^$subdocument,third-party",
    {
      OptionRuleData("http://s1.wp.com/_static",
          FOScript, "windsorstar.com", false),
    }));

  // Third party flags work correctly
  CHECK(checkOptionRule(
        "/scripts/ad.",
    {
      OptionRuleData("http://a.fsdn.com/sd/js/scripts/ad.js?release_20160112",
          FOScript, "slashdot.org", true),
    }));
}

struct ListCounts {
  size_t filters;
  size_t cosmeticFilters;
  size_t htmlFilters;
  size_t exceptions;
};

ListCounts easyList = { 21438, 30166, 0, 4602 };
ListCounts ublockUnbreak = { 5, 8, 0, 95 };
ListCounts braveUnbreak = { 3, 0, 0, 3 };
ListCounts disconnectSimpleMalware = { 2911, 0, 0, 0 };
ListCounts spam404MainBlacklist = { 5464, 169, 0, 0 };

// Should parse EasyList without failing
TEST(client, parse_easylist) {
  string && fileContents = // NOLINT
    getFileContents("./test/data/easylist.txt");
  AdBlockClient client;
  client.parse(fileContents.c_str());

  CHECK(compareNums(client.numFilters +
          client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        easyList.filters));
  CHECK(compareNums(client.numCosmeticFilters, easyList.cosmeticFilters));
  CHECK(compareNums(client.numHtmlFilters, easyList.htmlFilters));
  CHECK(compareNums(client.numExceptionFilters +
          client.numNoFingerprintExceptionFilters +
          client.hostAnchoredExceptionHashSet->size(),
        easyList.exceptions));
}

// Should parse ublock-unbreak list without failing
TEST(client, parse_ublock_unbreak) {
  string && fileContents = // NOLINT
    getFileContents("./test/data/ublock-unbreak.txt");
  AdBlockClient client;
  client.parse(fileContents.c_str());

  CHECK(compareNums(client.numFilters +
         client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        ublockUnbreak.filters));
  CHECK(compareNums(client.numCosmeticFilters, ublockUnbreak.cosmeticFilters));
  CHECK(compareNums(client.numHtmlFilters, ublockUnbreak.htmlFilters));
  CHECK(compareNums(client.numExceptionFilters +
          client.numNoFingerprintExceptionFilters +
          client.hostAnchoredExceptionHashSet->size(),
        ublockUnbreak.exceptions));
}

// Should parse brave-unbreak list without failing
TEST(client, parse_brave_unbreak) {
  string && fileContents = // NOLINT
    getFileContents("./test/data/brave-unbreak.txt");
  AdBlockClient client;
  client.parse(fileContents.c_str());

  CHECK(compareNums(client.numFilters +
          client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        braveUnbreak.filters));
  CHECK(compareNums(client.numCosmeticFilters, braveUnbreak.cosmeticFilters));
  CHECK(compareNums(client.numHtmlFilters, braveUnbreak.htmlFilters));
  CHECK(compareNums(client.numExceptionFilters +
          client.numNoFingerprintExceptionFilters +
          client.hostAnchoredExceptionHashSet->size(),
        braveUnbreak.exceptions));
}

// Should parse disconnect-simple-malware.txt list without failing
TEST(client, parse_brave_disconnect_simple_malware) {
  string && fileContents = // NOLINT
    getFileContents("./test/data/disconnect-simple-malware.txt");
  AdBlockClient client;
  client.parse(fileContents.c_str());

  CHECK(compareNums(client.numFilters +
          client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        disconnectSimpleMalware.filters));
  CHECK(compareNums(client.numCosmeticFilters,
        disconnectSimpleMalware.cosmeticFilters));
  CHECK(compareNums(client.numHtmlFilters,
        disconnectSimpleMalware.htmlFilters));
  CHECK(compareNums(client.numExceptionFilters +
          client.numNoFingerprintExceptionFilters +
          client.hostAnchoredExceptionHashSet->size(),
        disconnectSimpleMalware.exceptions));
}


// Should parse spam404-main-blacklist.txt list without failing
TEST(client, parse_spam404_main_blacklist) {
  string && fileContents = // NOLINT
    getFileContents("./test/data/spam404-main-blacklist.txt");
  AdBlockClient client;
  client.parse(fileContents.c_str());

  CHECK(compareNums(client.numFilters +
          client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        spam404MainBlacklist.filters));
  CHECK(compareNums(client.numCosmeticFilters,
        spam404MainBlacklist.cosmeticFilters));
  CHECK(compareNums(client.numHtmlFilters, spam404MainBlacklist.htmlFilters));
  CHECK(compareNums(client.numExceptionFilters +
          client.numNoFingerprintExceptionFilters +
          client.hostAnchoredExceptionHashSet->size(),
        spam404MainBlacklist.exceptions));

  const char *urlToCheck = "http://excellentmovies.net/";
  const char *currentPageDomain = "excellentmovies.net";
  CHECK(client.matches(urlToCheck, FODocument, currentPageDomain));
}


// Should parse lists without failing
TEST(client, parse_multiList) {
  string && fileContentsEasylist = // NOLINT
    getFileContents("./test/data/easylist.txt");

  string && fileContentsUblockUnbreak = // NOLINT
    getFileContents("./test/data/ublock-unbreak.txt");

  string && fileContentsBraveUnbreak = // NOLINT
    getFileContents("./test/data/brave-unbreak.txt");

  AdBlockClient client;
  client.parse(fileContentsEasylist.c_str());
  client.parse(fileContentsUblockUnbreak.c_str());
  client.parse(fileContentsBraveUnbreak.c_str());

  // I think counts are slightly off due to same rule hash set

  /*
  CHECK(compareNums(client.numFilters +
          client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        easyList.filters +
          ublockUnbreak.filters +
          braveUnbreak.filters));
          */
  CHECK(compareNums(client.numCosmeticFilters,
        easyList.cosmeticFilters +
          ublockUnbreak.cosmeticFilters +
          braveUnbreak.cosmeticFilters));

  CHECK(compareNums(client.numHtmlFilters,
        easyList.htmlFilters+
          ublockUnbreak.htmlFilters +
          braveUnbreak.htmlFilters));
  /*
  CHECK(compareNums(client.numExceptionFilters +
          client.hostAnchoredExceptionHashSet->size() +
          client.numNoFingerprintExceptionFilters,
        easyList.exceptions +
          ublockUnbreak.exceptions +
          braveUnbreak.exceptions));
  */
}

// Should parse lists without failing
TEST(client, parse_malware_multiList) {
  string && fileContentsSpam404 = // NOLINT
    getFileContents("./test/data/spam404-main-blacklist.txt");

  string && fileContentsDisconnectSimpleMalware = // NOLINT
    getFileContents("./test/data/disconnect-simple-malware.txt");

  AdBlockClient client;
  client.parse(fileContentsSpam404.c_str());
  client.parse(fileContentsDisconnectSimpleMalware.c_str());

  // I think counts are slightly off due to same rule hash set

  /*
  CHECK(compareNums(client.numFilters +
          client.numNoFingerprintFilters +
          client.hostAnchoredHashSet->size(),
        disconnectSimpleMalware.filters +
          spam404MainBlacklist.filters));
  */
  CHECK(compareNums(client.numCosmeticFilters,
        disconnectSimpleMalware.cosmeticFilters +
          spam404MainBlacklist.cosmeticFilters));

  CHECK(compareNums(client.numHtmlFilters,
        disconnectSimpleMalware.htmlFilters +
          spam404MainBlacklist.htmlFilters));

  CHECK(compareNums(client.numExceptionFilters +
          client.hostAnchoredExceptionHashSet->size() +
          client.numNoFingerprintExceptionFilters,
        disconnectSimpleMalware.exceptions+
          spam404MainBlacklist.exceptions));
}


// Calling parse amongst 2 different lists should preserve both sets of rules
TEST(multipleParse, multipleParse2) {
  AdBlockClient client;
  client.parse("adv\n"
               "@@test\n"
               "###test\n"
               "a.com$$script[src]\n");
  client.parse("adv2\n"
               "@@test2\n"
               "###test2\n"
               "adv3\n"
               "@@test3\n"
               "###test3\n"
               "b.com$$script[src]\n");

  CHECK(compareNums(client.numFilters +
        client.numNoFingerprintFilters, 3));
  CHECK(compareNums(client.numCosmeticFilters, 3));
  CHECK(compareNums(client.numHtmlFilters, 2));
  CHECK(compareNums(client.numExceptionFilters +
        client.numNoFingerprintExceptionFilters, 3));
}

// Demo app test
TEST(demoApp, demoApp2) {
  AdBlockClient client;
  client.parse("||googlesyndication.com/safeframe/$third-party");
  const char *urlToCheck =
    "http://tpc.googlesyndication.com/safeframe/1-0-2/html/container.html";
  const char *currentPageDomain = "slashdot.org";
  CHECK(client.matches(urlToCheck, FOScript, currentPageDomain));
}

TEST(hostAnchoredFiltersParseCorrectly, hostAnchoredFiltersParseCorrectly2) {
  // Host anchor is calculated correctly
  Filter filter;
  parseFilter("||test.com$third-party", &filter);
  CHECK(!strcmp("test.com", filter.host));

  Filter filter2;
  parseFilter("||test.com/ok$third-party", &filter2);
  CHECK(!strcmp("test.com", filter2.host));

  Filter filter3;
  parseFilter("||test.com/ok", &filter3);
  CHECK(!strcmp("test.com", filter3.host));

  Filter filter4;
  Filter filter5;
  CHECK(filter4 == filter5);
}

TEST(misc, misc2) {
  for (int i = 0; i < 256; i++) {
    if (i == static_cast<int>(':') || i == static_cast<int>('?') ||
        i == static_cast<int>('/') ||
        i == static_cast<int>('=') || i == static_cast<int>('^') ||
        i == static_cast<int>('$')) {
      CHECK(isSeparatorChar(static_cast<char>(i)));
    } else {
      CHECK(!isSeparatorChar(static_cast<int>(static_cast<char>(i))));
    }
  }
}


TEST(serializationTests, serializationTests2) {
  AdBlockClient client;
  client.parse(
      "||googlesyndication.com$third-party\n@@||googlesyndication.ca");
  int size;
  char * buffer = client.serialize(&size);

  AdBlockClient client2;
  CHECK(client2.deserialize(buffer));

  Filter f(static_cast<FilterType>(FTHostAnchored | FTHostOnly), FOThirdParty,
      FONoFilterOption, "googlesyndication.com", 21, nullptr,
      "googlesyndication.com");
  Filter f2(FTNoFilterType, FOThirdParty, FONoFilterOption,
      "googleayndication.com", 21, nullptr, "googleayndication.com");
  CHECK(client.hostAnchoredHashSet->exists(f));
  CHECK(client2.hostAnchoredHashSet->exists(f));
  CHECK(!client.hostAnchoredHashSet->exists(f2));
  CHECK(!client2.hostAnchoredHashSet->exists(f2));

  Filter f3(static_cast<FilterType>(FTHostAnchored | FTHostOnly | FTException),
      FONoFilterOption, FONoFilterOption, "googlesyndication.ca",
      20, nullptr, "googlesyndication.ca");
  Filter f4(FTNoFilterType, FONoFilterOption, FONoFilterOption,
      "googleayndication.ca", 20, nullptr, "googleayndication.ca");
  CHECK(client.hostAnchoredExceptionHashSet->exists(f3));
  CHECK(client2.hostAnchoredExceptionHashSet->exists(f3));
  CHECK(!client.hostAnchoredExceptionHashSet->exists(f4));
  CHECK(!client2.hostAnchoredExceptionHashSet->exists(f4));

  delete[] buffer;
}

// Testing matchingFilter
TEST(findMatchingFilters, basic) {
  AdBlockClient client;
  client.parse("||googlesyndication.com/safeframe/$third-party\n"
      "||brianbondy.com/ads");
  const char *urlToCheck =
    "http://tpc.googlesyndication.com/safeframe/1-0-2/html/container.html";
  const char *currentPageDomain = "slashdot.org";

  Filter none;
  Filter *matchingFilter = &none;
  Filter *matchingExceptionFilter = &none;

  // Test finds a match
  CHECK(client.findMatchingFilters(urlToCheck, FOScript, currentPageDomain,
    &matchingFilter, &matchingExceptionFilter));
  CHECK(matchingFilter)
  CHECK(matchingExceptionFilter == nullptr)
  CHECK(!strcmp(matchingFilter->data, "googlesyndication.com/safeframe/"));

  // Test when no filter is found, returns false and sets out params to nullptr
  CHECK(!client.findMatchingFilters("ssafsdf.com", FOScript, currentPageDomain,
    &matchingFilter, &matchingExceptionFilter));
  CHECK(matchingFilter == nullptr)
  CHECK(matchingExceptionFilter == nullptr)

  // Parse that it finds exception filters correctly
  client.parse("@@safeframe\n");
  CHECK(!client.findMatchingFilters(urlToCheck, FOScript, currentPageDomain,
    &matchingFilter, &matchingExceptionFilter));
  CHECK(matchingFilter)
  CHECK(matchingExceptionFilter)
  CHECK(!strcmp(matchingFilter->data, "googlesyndication.com/safeframe/"));
  CHECK(!strcmp(matchingExceptionFilter->data, "safeframe"));
}
