/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <fstream>
#include <sstream>
#include <iostream>
#include <string>
#include "./CppUnitLite/TestHarness.h"
#include "./test/util.h"

using std::cout;
using std::endl;

std::string getFileContents(const char *filename) {
  std::ifstream in(filename, std::ios::in);
  if (in) {
    std::ostringstream contents;
    contents << in.rdbuf();
    in.close();
    return(contents.str());
  }
  throw(errno);
}

bool compareNums(int actual, int expected) {
  if (actual != expected) {
    cout << "Actual: " << actual << endl << "Expected: " << expected << endl;
    return false;
  }
  return true;
}
