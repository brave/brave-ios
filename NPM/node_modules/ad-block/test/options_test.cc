/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <string.h>
#include <fstream>
#include <sstream>
#include <string>
#include <algorithm>
#include <cerrno>
#include <iostream>
#include <set>
#include "./CppUnitLite/TestHarness.h"
#include "./ad_block_client.h"
#include "./util.h"

using std::set;
using std::string;
using std::cout;
using std::endl;

void printSet(const set<string> &domainSet) {
  std::for_each(domainSet.begin(), domainSet.end(), [](string const &s) {
    cout << s.c_str() << " ";
  });
}

bool testOptionsWithFilter(Filter *f, const char *input,
    FilterOption expectedOption, FilterOption expectedAntiOption,
    const set<string> &expectedDomains,
    const set<string> &expectedAntiDomains) {
  if (f->filterOption != expectedOption) {
    cout << input << endl << "Actual options: " << f->filterOption
      << endl << "Expected: " << expectedOption << endl;
    return false;
  }
  if (f->antiFilterOption != expectedAntiOption) {
    cout << input << endl << "Actual anti options: " << f->antiFilterOption
      << endl << "Expected: " << expectedAntiOption << endl;
    return false;
  }
  if (expectedDomains.size() != f->getDomainCount()) {
    cout << input << endl << "Actual domain count: " << f->getDomainCount()
      << endl << "Expected: " << expectedDomains.size() << endl;
    return false;
  }
  if (expectedAntiDomains.size() != f->getDomainCount(true)) {
    cout << input << endl << "Actual anti domain count: "
      << f->getDomainCount(false) << endl << "Expected: "
      << expectedAntiDomains.size() << endl;
    return false;
  }

  bool ret = true;
  std::for_each(expectedDomains.begin(), expectedDomains.end(),
      [&f, &expectedDomains, &ret, input](string const &s) {
    if (!f->containsDomain(s.c_str())) {
      cout << input << endl << "Actual domains: "
      << (f->domainList ? f->domainList : "") << endl << "Expected: ";
      printSet(expectedDomains);
      cout << endl;
      cout << "Not found: " << s.c_str() << endl;
      ret = false;
    }
  });
  if (!ret) {
    return false;
  }

  std::for_each(expectedAntiDomains.begin(), expectedAntiDomains.end(),
      [&f, &expectedAntiDomains, &ret, input](string const &s) {
    if (!f->containsDomain(s.c_str(), true)) {
      cout << input << endl << "Actual anti domains: "
        << (f->domainList ? f->domainList : "") << endl << "Expected: ";
      printSet(expectedAntiDomains);
      cout << endl;
      ret = false;
    }
  });
  if (!ret) {
    return false;
  }

  return true;
}

bool testOptions(const char *rawOptions, FilterOption expectedOption,
    FilterOption expectedAntiOption,
    set<string> &&expectedDomains, // NOLINT
    set<string> &&expectedAntiDomains) { // NOLINT
  Filter f;
  f.parseOptions(rawOptions);
  return testOptionsWithFilter(&f, rawOptions, expectedOption,
      expectedAntiOption, expectedDomains, expectedAntiDomains);
}

bool testFilterOptions(const char *input, FilterOption expectedOption,
    FilterOption expectedAntiOption,
    set<string> &&expectedDomains, // NOLINT
    set<string> &&expectedAntiDomains) { // NOLINT
  Filter f;
  parseFilter(input, &f);
  return testOptionsWithFilter(&f, input, expectedOption,
      expectedAntiOption, expectedDomains, expectedAntiDomains);
}

// Option parsing should split options properly
TEST(options, splitOptions) {
  CHECK(testOptions("subdocument,third-party",
    static_cast<FilterOption>(FOThirdParty | FOSubdocument),
    FONoFilterOption,
    {},
    {}));

  CHECK(testOptions(
        "object-subrequest,script,domain=~msnbc.msn.com|~www.nbcnews.com",
    static_cast<FilterOption>(FOObjectSubrequest | FOScript),
    FONoFilterOption,
    {},
    {
      "msnbc.msn.com",
      "www.nbcnews.com"
    }));

  CHECK(testOptions("~document,xbl,domain=~foo|bar|baz|foo.xbl|gar,~collapse",
    FOXBL,
    static_cast<FilterOption>(FODocument | FOCollapse),
    {
      "bar",
      "baz",
      "foo.xbl",
      "gar"
    },
    {
      "foo"
    }));


  CHECK(testOptions("domain=~example.com|foo.example.com,script",
    FOScript,
    FONoFilterOption,
    {
      "foo.example.com"
    },
    {
      "example.com"
    }));
}

// domain rule types should be properly parsed
TEST(options, domainOptionStrings) {
  CHECK(testOptions("domain=example.com",
    FONoFilterOption,
    FONoFilterOption,
    {
      "example.com"
    },
    {}));

  CHECK(testOptions("domain=example.com|example.net",
    FONoFilterOption,
    FONoFilterOption,
    {
      "example.com",
      "example.net"
    },
    {}));

  CHECK(testOptions("domain=~example.com",
    FONoFilterOption,
    FONoFilterOption,
    { },
    {
      "example.com"
    }));

  CHECK(testOptions("domain=example.com|~foo.example.com",
    FONoFilterOption,
    FONoFilterOption,
    {
      "example.com",
    },
    {
      "foo.example.com"
    }));

  CHECK(testOptions("domain=~foo.example.com|example.com",
    FONoFilterOption,
    FONoFilterOption,
    {
      "example.com",
    },
    {
      "foo.example.com"
    }));

  CHECK(testOptions("domain=~msnbc.msn.com|~www.nbcnews.com",
    FONoFilterOption,
    FONoFilterOption,
    { },
    {
      "msnbc.msn.com",
      "www.nbcnews.com"
    }))
}

// parseFilter for full rules properly extracts options
TEST(options, optionsFromFilter) {
  CHECK(testFilterOptions("domain=foo.bar",
    FONoFilterOption,
    FONoFilterOption,
    {},
    {}))

  CHECK(testFilterOptions("+Ads/$~stylesheet",
    FONoFilterOption,
    FOStylesheet,
    {},
    {}))

  CHECK(testFilterOptions("-advertising-$domain=~advertise.bingads.domain.com",
    FONoFilterOption,
    FONoFilterOption,
    { },
    {
      "advertise.bingads.domain.com"
    }))

  CHECK(testFilterOptions(".se/?placement=$script,third-party",
    static_cast<FilterOption>(FOScript| FOThirdParty),
    FONoFilterOption,
    {},
    {}))

  CHECK(testFilterOptions("https:$ping",
    static_cast<FilterOption>(FOPing),
    FONoFilterOption,
    {},
    {}))

  CHECK(testFilterOptions(
      "||tst.net^$object-subrequest,third-party,domain=domain1.com|domain5.com",
    static_cast<FilterOption>(FOObjectSubrequest | FOThirdParty),
    FONoFilterOption,
    {
      "domain1.com",
      "domain5.com"
    },
    {}))
}
