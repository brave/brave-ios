/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef AD_BLOCK_CLIENT_WRAP_H_
#define AD_BLOCK_CLIENT_WRAP_H_

#include <node.h>
#include <node_object_wrap.h>

#include "./ad_block_client.h"

namespace ad_block_client_wrap {

/**
 * Wraps AdBlockClient for use in Node
 */
class AdBlockClientWrap : public AdBlockClient, public node::ObjectWrap {
 public:
  static void Init(v8::Local<v8::Object> exports);

 private:
  AdBlockClientWrap();
  virtual ~AdBlockClientWrap();

  static void New(const v8::FunctionCallbackInfo<v8::Value>& args);

  static void Clear(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Parse(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Matches(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Serialize(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Deserialize(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void Cleanup(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void GetParsingStats(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void GetMatchingStats(const v8::FunctionCallbackInfo<v8::Value>& args);
  static void EnableBadFingerprintDetection(
      const v8::FunctionCallbackInfo<v8::Value>& args);
  static void GenerateBadFingerprintsHeader(
      const v8::FunctionCallbackInfo<v8::Value>& args);
  static void FindMatchingFilters(
      const v8::FunctionCallbackInfo<v8::Value>& args);

  static v8::Persistent<v8::Function> constructor;
};

}  // namespace ad_block_client_wrap

#endif  // AD_BLOCK_CLIENT_WRAP_H_
