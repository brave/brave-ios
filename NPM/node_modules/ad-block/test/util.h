/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TEST_UTIL_H_
#define TEST_UTIL_H_

#include <string>

SimpleString StringFrom(const std::string& value);
std::string getFileContents(const char *filename);
bool compareNums(int actual, int expected);

#endif  // TEST_UTIL_H_
