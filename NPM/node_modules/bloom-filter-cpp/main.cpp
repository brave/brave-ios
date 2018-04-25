/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include "BloomFilter.h"

using std::cout;
using std::endl;

char separatorBuffer[32] = { 0, 0, 0, 0, 0, -128, 0, -92, 0, 0, 0, 64 };
inline bool isSeparatorChar(char c) {
  return !!(separatorBuffer[c / 8] & 1 << c % 8);
}

int main(int argc, char**argv) {
  BloomFilter bloomFilter(8, 32);
  bloomFilter.setBit(static_cast<int>(':'));
  bloomFilter.setBit(static_cast<int>('?'));
  bloomFilter.setBit(static_cast<int>('/'));
  bloomFilter.setBit(static_cast<int>('='));
  bloomFilter.setBit(static_cast<int>('^'));
  cout << "size: " << bloomFilter.getByteBufferSize() << endl;
  for (int i = 0; i < bloomFilter.getByteBufferSize(); i++) {
    cout << " " << static_cast<int>(bloomFilter.getBuffer()[i]);
  }
  cout << endl;

  cout << "Separator chars: " << isSeparatorChar(':') << " "
    << isSeparatorChar('?') << " " <<  isSeparatorChar('/') << " "
    << isSeparatorChar('=') <<  isSeparatorChar('^')  << endl;

  cout << "NON Separator chars: " << isSeparatorChar('a') << " "
    << isSeparatorChar('!') << " " <<  isSeparatorChar('#') << " "
    << isSeparatorChar('X') <<  isSeparatorChar('.')
    << isSeparatorChar('\\') << isSeparatorChar('"')
    << isSeparatorChar(-128) << endl;

  return 0;
}
