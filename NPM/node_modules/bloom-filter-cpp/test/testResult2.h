/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TEST_TESTRESULT2_H_
#define TEST_TESTRESULT2_H_

#include "./CppUnitLite/TestHarness.h"

class TestResult2 : public TestResult {
 public:
  TestResult2() : hasFailures(false) {
  }
  virtual void addFailure(const Failure& failure) {
    hasFailures = true;
    TestResult::addFailure(failure);
  }
  bool hasFailures;
};

#endif  // TEST_TESTRESULT2_H_
