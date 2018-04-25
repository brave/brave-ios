/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TEST_EXAMPLEDATA_H_
#define TEST_EXAMPLEDATA_H_

#include <math.h>
#include <string.h>
#include "hashFn.h"

static HashFn h(19);

class ExampleData {
 public:
  uint64_t hash() const {
    return h(data, dataLen);
  }

  ~ExampleData() {
    if (data && !borrowedMemory) {
      delete[] data;
    }
  }
  explicit ExampleData(const char *data) {
    dataLen = static_cast<uint32_t>(strlen(data)) + 1;
    this->data = new char[dataLen];
    memcpy(this->data, data, dataLen);
    borrowedMemory = false;
    extraData = 0;
  }

  ExampleData(const char *data, int dataLen) {
    this->dataLen = dataLen;
    this->data = new char[dataLen];
    memcpy(this->data, data, dataLen);
    borrowedMemory = false;
    extraData = 0;
  }

  ExampleData(const ExampleData &rhs) {
    this->dataLen = rhs.dataLen;
    data = new char[dataLen];
    memcpy(data, rhs.data, dataLen);
    borrowedMemory = rhs.borrowedMemory;
    extraData = rhs.extraData;
  }

  ExampleData() : extraData(0), data(nullptr), dataLen(0),
    borrowedMemory(false) {
  }

  bool operator==(const ExampleData &rhs) const {
    if (dataLen != rhs.dataLen) {
      return false;
    }

    return !memcmp(data, rhs.data, dataLen);
  }

  bool operator!=(const ExampleData &rhs) const {
    return !(*this == rhs);
  }

  void update(const ExampleData &other) {
    extraData = extraData | other.extraData;
  }

  uint32_t serialize(char *buffer) {
    uint32_t totalSize = 0;
    char sz[32];
    uint32_t dataLenSize = 1 + snprintf(sz, sizeof(sz), "%x", dataLen);
    if (buffer) {
      memcpy(buffer + totalSize, sz, dataLenSize);
    }
    totalSize += dataLenSize;
    if (buffer) {
      memcpy(buffer + totalSize, data, dataLen);
    }
    totalSize += dataLen;

    if (buffer) {
      buffer[totalSize] = extraData;
    }
    totalSize++;

    return totalSize;
  }

  uint32_t deserialize(char *buffer, uint32_t bufferSize) {
    dataLen = 0;
    if (!hasNewlineBefore(buffer, bufferSize)) {
      return 0;
    }
    sscanf(buffer, "%x", &dataLen);
    uint32_t consumed = static_cast<uint32_t>(strlen(buffer)) + 1;
    if (consumed + dataLen >= bufferSize) {
      return 0;
    }
    data = buffer + consumed;
    borrowedMemory = true;
    memcpy(data, buffer + consumed, dataLen);
    consumed += dataLen;

    extraData = buffer[consumed];
    consumed++;

    return consumed;
  }

  // Just an example which is not used in comparisons but
  // is used for serializing / deserializing, showing the
  // need for find vs exists.
  char extraData;

 private:
  bool hasNewlineBefore(char *buffer, uint32_t bufferSize) {
    char *p = buffer;
    for (uint32_t i = 0; i < bufferSize; ++i) {
      if (*p == '\0')
        return true;
      p++;
    }
    return false;
  }

  char *data;
  uint32_t dataLen;
  bool borrowedMemory;
};

#endif  // TEST_EXAMPLEDATA_H_
