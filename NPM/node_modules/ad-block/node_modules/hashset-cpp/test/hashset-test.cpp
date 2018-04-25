/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "./CppUnitLite/TestHarness.h"
#include "./CppUnitLite/Test.h"
#include "./HashSet.h"
#include "./exampleData.h"
#include "./hashFn.h"

TEST(hashSet, test1) {
  {
    HashSet<ExampleData> hashSet(2);
    hashSet.add(ExampleData("test"));
    uint32_t len;
    char *buffer = hashSet.serialize(&len);
    HashSet<ExampleData> hashSet2(0);
    hashSet2.deserialize(buffer, len);
    hashSet2.exists(ExampleData("test"));
  }

  HashSet<ExampleData> hashSets[] = {HashSet<ExampleData>(1),
    HashSet<ExampleData>(2), HashSet<ExampleData>(500)};
  for (unsigned int i = 0; i < sizeof(hashSets) / sizeof(hashSets[0]); i++) {
    HashSet<ExampleData> &hashSet = hashSets[i];
    LONGS_EQUAL(0, hashSet.size());
    hashSet.add(ExampleData("test"));
    LONGS_EQUAL(1, hashSet.size());
    CHECK(hashSet.exists(ExampleData("test")));
    hashSet.add(ExampleData("test"));
    CHECK(hashSet.exists(ExampleData("test")));
    LONGS_EQUAL(1, hashSet.size());
    hashSet.add(ExampleData("test2"));
    CHECK(hashSet.exists(ExampleData("test2")));
    LONGS_EQUAL(2, hashSet.size());
    hashSet.add(ExampleData("test3"));
    CHECK(hashSet.exists(ExampleData("test3")));
    hashSet.add(ExampleData("test4"));
    CHECK(hashSet.exists(ExampleData("test4")));

    // Check that a smaller substring of something that exists, doesn't exist
    CHECK(!hashSet.exists(ExampleData("tes")));
    // Check that a longer string of something that exists, doesn't exist
    CHECK(!hashSet.exists(ExampleData("test22")));
    CHECK(!hashSet.exists(ExampleData("test5")));

    LONGS_EQUAL(4, hashSet.size());
    hashSet.add(ExampleData("a\0b\0\0c", 6));
    LONGS_EQUAL(5, hashSet.size());
    CHECK(!hashSet.exists(ExampleData("a")));
    CHECK(!hashSet.exists(ExampleData("a", 1)));
    CHECK(hashSet.exists(ExampleData("a\0b\0\0c", 6)));
    CHECK(!hashSet.exists(ExampleData("a\0b\0\0c", 7)));

    // Test that remove works
    LONGS_EQUAL(5, hashSet.size());
    CHECK(hashSet.exists(ExampleData("test2")));
    CHECK(hashSet.remove(ExampleData("test2")));
    LONGS_EQUAL(4, hashSet.size());
    CHECK(!hashSet.exists(ExampleData("test2")));
    CHECK(!hashSet.remove(ExampleData("test2")));
    LONGS_EQUAL(4, hashSet.size());
    CHECK(hashSet.add(ExampleData("test2")));
    LONGS_EQUAL(5, hashSet.size());

    // Try to find something that doesn't exist
    CHECK(hashSet.find(ExampleData("fdsafasd")) == nullptr);

    // Show how extra data works
    ExampleData item("ok");
    item.extraData = 1;
    hashSet.add(item);

    ExampleData *p = hashSet.find(ExampleData("ok"));
    LONGS_EQUAL(1, p->extraData);

    item.extraData = 2;
    hashSet.add(item);
    LONGS_EQUAL(6, hashSet.size());
    // ExampleData is configuredd to merge extraData on updates
    LONGS_EQUAL(3, p->extraData);
  }

  uint32_t len = 0;
  for (unsigned int i = 0; i < sizeof(hashSets) / sizeof(hashSets[0]); i++) {
    HashSet<ExampleData> &hs1 = hashSets[i];
    char *buffer = hs1.serialize(&len);
    HashSet<ExampleData> dhs(0);
    // Deserializing some invalid data should fail
    CHECK(!dhs.deserialize(const_cast<char*>("31131"), 2));
    CHECK(dhs.deserialize(buffer, len));
    CHECK(dhs.exists(ExampleData("test")));
    CHECK(dhs.exists(ExampleData("test2")));
    CHECK(dhs.exists(ExampleData("test3")));
    CHECK(dhs.exists(ExampleData("test4")));
    CHECK(!dhs.exists(ExampleData("tes")));
    CHECK(!dhs.exists(ExampleData("test22")));
    CHECK(!dhs.exists(ExampleData("test5")));
    CHECK(!dhs.exists(ExampleData("a")));
    CHECK(!dhs.exists(ExampleData("a", 1)));
    CHECK(dhs.exists(ExampleData("a\0b\0\0c", 6)));
    CHECK(!dhs.exists(ExampleData("a\0b\0\0c", 7)));
    LONGS_EQUAL(6, dhs.size());

    // Make sure  HashSet clears correctly
    CHECK(dhs.exists(ExampleData("test")));
    dhs.clear();
    CHECK(!dhs.exists(ExampleData("test")));

    delete[] buffer;
  }

  // Make sure HashFn produces the correct hash
  HashFn h(19, false);
  HashFn h2(19, true);
  const char *sz = "facebook.com";
  const char *sz2 = "abcde";
  LONGS_EQUAL(h(sz, strlen(sz)), 12510474367240317);
  LONGS_EQUAL(h2(sz, strlen(sz)), 12510474367240317);
  LONGS_EQUAL(h(sz2, strlen(sz2)), 13351059);
  LONGS_EQUAL(h2(sz2, strlen(sz2)), 13351059);
}
