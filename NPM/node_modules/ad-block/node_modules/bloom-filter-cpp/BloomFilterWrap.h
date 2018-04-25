/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef BLOOMFILTERWRAP_H_
#define BLOOMFILTERWRAP_H_

#include <node.h>
#include <node_object_wrap.h>

#include "BloomFilter.h"

namespace BloomFilterWrap {

/**
 * Wraps Bloom Filter for use in Node
 */
class BloomFilterWrap : public BloomFilter, public node::ObjectWrap {
 public:
  static void Init(v8::Local<v8::Object> exports);

 private:
  BloomFilterWrap(unsigned int bitsPerElement = 10,
    unsigned int estimatedNumElements = 50000,
    HashFn hashFns[] = defaultHashFns,
    int numHashFns = sizeof(defaultHashFns)/sizeof(defaultHashFns[0]));
  virtual ~BloomFilterWrap();

  static void New(const v8::FunctionCallbackInfo<v8::Value>& args);

  static void Add(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Exists(const v8::FunctionCallbackInfo<v8::Value>& args);

  static v8::Persistent<v8::Function> constructor;
};

}  // namespace BloomFilterWrap

#endif  // BLOOMFILTERWRAP_H_
