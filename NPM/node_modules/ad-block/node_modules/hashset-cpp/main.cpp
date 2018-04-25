/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include "./HashSet.h"
#include "./test/exampleData.h"

using std::cout;
using std::endl;

int main(int argc, char **argv) {
  HashSet<ExampleData> set(256);
  set.add(ExampleData("test"));

  // Prints true
  cout << "test exists: " << (set.exists(ExampleData("test"))
      ? "true" : "false") << endl;
  // Prints false
  cout << "test2 exists: " << (set.exists(ExampleData("test2"))
      ? "true" : "false") << endl;

  uint32_t len;
  char * buffer = set.serialize(&len);
  HashSet<ExampleData> set2(0);
  set2.deserialize(buffer, len);
  // Prints true
  cout << "test exists: " << (set2.exists(ExampleData("test"))
      ? "true" : "false") << endl;
  // Prints false
  cout << "test2 exists: " << (set2.exists(ExampleData("test2"))
      ? "true" : "false") << endl;

  delete[] buffer;
  return 0;
}
