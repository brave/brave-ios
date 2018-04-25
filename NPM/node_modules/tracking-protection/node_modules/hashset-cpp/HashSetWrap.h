/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef HASHSETWRAP_H_
#define HASHSETWRAP_H_

#include <node.h>
#include <node_object_wrap.h>

#include "HashSet.h"
#include "test/exampleData.h"

namespace HashSetWrap {

/**
 * Wraps Hash Set for use in Node
 */
class HashSetWrap : public HashSet<ExampleData>, public node::ObjectWrap {
 public:
  static void Init(v8::Local<v8::Object> exports);

 private:
  explicit HashSetWrap(uint32_t bucketCount);
  virtual ~HashSetWrap();

  static void New(const v8::FunctionCallbackInfo<v8::Value>& args);

  static void Add(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Exists(const v8::FunctionCallbackInfo<v8::Value>& args);

  static v8::Persistent<v8::Function> constructor;
};

}  // namespace HashSetWrap

#endif  // HASHSETWRAP_H_
