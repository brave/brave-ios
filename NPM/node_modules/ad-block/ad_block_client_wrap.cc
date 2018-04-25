/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "./ad_block_client_wrap.h"
#include <node_buffer.h>
#include <algorithm>
#include "./bad_fingerprint.h"
#include "./data_file_version.h"
#include "./filter_list.h"
#include "./lists/regions.h"
#include "./lists/malware.h"
#include "./lists/default.h"

namespace ad_block_client_wrap {

using v8::Array;
using v8::Function;
using v8::FunctionCallbackInfo;
using v8::FunctionTemplate;
using v8::Isolate;
using v8::Local;
using v8::MaybeLocal;
using v8::Int32;
using v8::Object;
using v8::Persistent;
using v8::String;
using v8::Boolean;
using v8::Value;
using v8::Exception;

Persistent<Function> AdBlockClientWrap::constructor;

AdBlockClientWrap::AdBlockClientWrap() {
}

AdBlockClientWrap::~AdBlockClientWrap() {
}

Local<Object> ToLocalObject(Isolate* isolate, FilterList filter_list) {
  Local<Object> list = Object::New(isolate);
  list->Set(String::NewFromUtf8(isolate, "uuid"),
    String::NewFromUtf8(isolate, filter_list.uuid.c_str()));
  list->Set(String::NewFromUtf8(isolate, "listURL"),
    String::NewFromUtf8(isolate, filter_list.url.c_str()));
  list->Set(String::NewFromUtf8(isolate, "title"),
    String::NewFromUtf8(isolate, filter_list.title.c_str()));
  list->Set(String::NewFromUtf8(isolate, "supportURL"),
    String::NewFromUtf8(isolate, filter_list.support_url.c_str()));

  Local<Array> langs = Array::New(isolate);
  int j = 0;
  std::for_each(filter_list.langs.begin(), filter_list.langs.end(),
    [&isolate, &langs, &j](const std::string &lang) {
    langs->Set(j++,
      String::NewFromUtf8(isolate, lang.c_str()));
  });
  if (filter_list.langs.size() > 0) {
    list->Set(String::NewFromUtf8(isolate, "langs"), langs);
  }
  return list;
}

Local<Array> ToLocalObject(Isolate* isolate,
    const std::vector<FilterList> &list) {
  Local<Array> lists = Array::New(isolate);
  int j = 0;
  std::for_each(list.begin(), list.end(),
    [&isolate, &lists, &j](const FilterList &filter_list) {
    lists->Set(j++, ToLocalObject(isolate, filter_list));
  });
  return lists;
}

void AdBlockClientWrap::Init(Local<Object> exports) {
  Isolate* isolate = exports->GetIsolate();

  // Prepare constructor template
  Local<FunctionTemplate> tpl = FunctionTemplate::New(isolate, New);
  tpl->SetClassName(String::NewFromUtf8(isolate, "AdBlockClient"));
  tpl->InstanceTemplate()->SetInternalFieldCount(1);

  // Prototype
  NODE_SET_PROTOTYPE_METHOD(tpl, "clear", AdBlockClientWrap::Clear);
  NODE_SET_PROTOTYPE_METHOD(tpl, "parse", AdBlockClientWrap::Parse);
  NODE_SET_PROTOTYPE_METHOD(tpl, "matches", AdBlockClientWrap::Matches);
  NODE_SET_PROTOTYPE_METHOD(tpl, "findMatchingFilters",
      AdBlockClientWrap::FindMatchingFilters);
  NODE_SET_PROTOTYPE_METHOD(tpl, "serialize", AdBlockClientWrap::Serialize);
  NODE_SET_PROTOTYPE_METHOD(tpl, "deserialize",
    AdBlockClientWrap::Deserialize);
  NODE_SET_PROTOTYPE_METHOD(tpl, "getParsingStats",
    AdBlockClientWrap::GetParsingStats);
  NODE_SET_PROTOTYPE_METHOD(tpl, "getMatchingStats",
    AdBlockClientWrap::GetMatchingStats);
  NODE_SET_PROTOTYPE_METHOD(tpl, "enableBadFingerprintDetection",
    AdBlockClientWrap::EnableBadFingerprintDetection);
  NODE_SET_PROTOTYPE_METHOD(tpl, "generateBadFingerprintsHeader",
    AdBlockClientWrap::GenerateBadFingerprintsHeader);
  NODE_SET_PROTOTYPE_METHOD(tpl, "cleanup", AdBlockClientWrap::Cleanup);

  // filter options
  Local<Object> filterOptions = Object::New(isolate);
  filterOptions->Set(String::NewFromUtf8(isolate, "noFilterOption"),
    Int32::New(isolate, 0));
  filterOptions->Set(String::NewFromUtf8(isolate, "script"),
    Int32::New(isolate, 01));
  filterOptions->Set(String::NewFromUtf8(isolate, "image"),
    Int32::New(isolate, 02));
  filterOptions->Set(String::NewFromUtf8(isolate, "stylesheet"),
    Int32::New(isolate, 04));
  filterOptions->Set(String::NewFromUtf8(isolate, "object"),
    Int32::New(isolate, 010));
  filterOptions->Set(String::NewFromUtf8(isolate, "xmlHttpRequest"),
    Int32::New(isolate, 020));
  filterOptions->Set(String::NewFromUtf8(isolate, "objectSubrequest"),
    Int32::New(isolate, 040));
  filterOptions->Set(String::NewFromUtf8(isolate, "subdocument"),
    Int32::New(isolate, 0100));
  filterOptions->Set(String::NewFromUtf8(isolate, "document"),
    Int32::New(isolate, 0200));
  filterOptions->Set(String::NewFromUtf8(isolate, "other"),
    Int32::New(isolate, 0400));
  filterOptions->Set(String::NewFromUtf8(isolate, "xbl"),
    Int32::New(isolate, 01000));
  filterOptions->Set(String::NewFromUtf8(isolate, "collapse"),
    Int32::New(isolate, 02000));
  filterOptions->Set(String::NewFromUtf8(isolate, "doNotTrack"),
    Int32::New(isolate, 04000));
  filterOptions->Set(String::NewFromUtf8(isolate, "elemHide"),
    Int32::New(isolate, 010000));
  filterOptions->Set(String::NewFromUtf8(isolate, "thirdParty"),
    Int32::New(isolate, 020000));
  filterOptions->Set(String::NewFromUtf8(isolate, "notThirdParty"),
    Int32::New(isolate, 040000));

  // Adblock lists
  Local<Object> lists = Object::New(isolate);
  lists->Set(String::NewFromUtf8(isolate, "default"),
    ToLocalObject(isolate, default_lists));
  lists->Set(String::NewFromUtf8(isolate, "malware"),
    ToLocalObject(isolate, malware_lists));
  lists->Set(String::NewFromUtf8(isolate, "regions"),
    ToLocalObject(isolate, region_lists));

  constructor.Reset(isolate, tpl->GetFunction());
  exports->Set(String::NewFromUtf8(isolate, "AdBlockClient"),
               tpl->GetFunction());
  exports->Set(String::NewFromUtf8(isolate, "FilterOptions"), filterOptions);
  exports->Set(String::NewFromUtf8(isolate, "adBlockLists"), lists);
  exports->Set(String::NewFromUtf8(isolate, "adBlockDataFileVersion"),
               Int32::New(isolate, DATA_FILE_VERSION));
}

void AdBlockClientWrap::New(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();

  if (args.IsConstructCall()) {
    // Invoked as constructor: `new AdBlockClient(...)`
    AdBlockClientWrap* obj = new AdBlockClientWrap();
    obj->Wrap(args.This());
    args.GetReturnValue().Set(args.This());
  } else {
    // Invoked as plain function `AdBlockClient(...)`,
    // turn into construct call.
    const int argc = 1;
    Local<Value> argv[argc] = { args[0] };
    Local<Function> cons = Local<Function>::New(isolate, constructor);
    args.GetReturnValue().Set(cons->NewInstance(argc, argv));
  }
}

void AdBlockClientWrap::Clear(const FunctionCallbackInfo<Value>& args) {
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  obj->clear();
}

void AdBlockClientWrap::Parse(const FunctionCallbackInfo<Value>& args) {
  String::Utf8Value str(args[0]->ToString());
  const char * buffer = *str;

  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  obj->parse(buffer);
}

void AdBlockClientWrap::Matches(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  String::Utf8Value str(args[0]->ToString());
  const char * buffer = *str;
  int32_t filterOption = static_cast<FilterOption>(args[1]->Int32Value());
  String::Utf8Value currentPageDomain(args[2]->ToString());
  const char * currentPageDomainBuffer = *currentPageDomain;

  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  bool matches = obj->matches(buffer,
    static_cast<FilterOption>(filterOption),
    currentPageDomainBuffer);

  args.GetReturnValue().Set(Boolean::New(isolate, matches));
}

void AdBlockClientWrap::FindMatchingFilters(
    const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  String::Utf8Value str(args[0]->ToString());
  const char * buffer = *str;
  int32_t filterOption = static_cast<FilterOption>(args[1]->Int32Value());
  String::Utf8Value currentPageDomain(args[2]->ToString());
  const char * currentPageDomainBuffer = *currentPageDomain;

  Filter *matchingFilter;
  Filter *matchingExceptionFilter;
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  bool matches = obj->findMatchingFilters(buffer,
    static_cast<FilterOption>(filterOption),
    currentPageDomainBuffer, &matchingFilter, &matchingExceptionFilter);

  Local<Object> foundData = Object::New(isolate);
  foundData->Set(String::NewFromUtf8(isolate, "matches"),
    Boolean::New(isolate, matches));
  if (matchingFilter) {
    foundData->Set(String::NewFromUtf8(isolate, "machingFilter"),
      String::NewFromUtf8(isolate, matchingFilter->data));
  }
  if (matchingExceptionFilter) {
    foundData->Set(String::NewFromUtf8(isolate, "matchingExceptionFilter"),
      String::NewFromUtf8(isolate, matchingExceptionFilter->data));
  }
  args.GetReturnValue().Set(foundData);
}

void AdBlockClientWrap::Serialize(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());

  int totalSize = 0;
  // Serialize data
  char* data = obj->serialize(&totalSize);
  if (nullptr == data) {
    isolate->ThrowException(Exception::TypeError(
      String::NewFromUtf8(isolate, "Could not serialize")));
    return;
  }

  MaybeLocal<Object> buffer = node::Buffer::New(isolate, totalSize);
  Local<Object> localBuffer;
  if (!buffer.ToLocal(&localBuffer)) {
    isolate->ThrowException(Exception::TypeError(
      String::NewFromUtf8(isolate, "Could not convert MaybeLocal to Local")));
    return;
  }
  memcpy(node::Buffer::Data(localBuffer), data, totalSize);
  delete[] data;
  args.GetReturnValue().Set(localBuffer);
}
void AdBlockClientWrap::Deserialize(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());

  if (args.Length() < 1) {
    isolate->ThrowException(Exception::TypeError(
      String::NewFromUtf8(isolate, "Wrong number of arguments")));
    return;
  }
  unsigned char *buf = (unsigned char *)node::Buffer::Data(args[0]);
  size_t length = node::Buffer::Length(args[0]);
  const char *oldDeserializedData = obj->getDeserializedBuffer();
  if (nullptr != oldDeserializedData) {
    delete []oldDeserializedData;
  }
  char *deserializedData = new char[length];
  memcpy(deserializedData, buf, length);
  args.GetReturnValue().Set(Boolean::New(isolate,
    obj->deserialize(deserializedData)));
}

void AdBlockClientWrap::GetParsingStats(
    const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  Local<Object> stats = Object::New(isolate);
  stats->Set(String::NewFromUtf8(isolate, "numFilters"),
    Int32::New(isolate, obj->numFilters));
  stats->Set(String::NewFromUtf8(isolate, "numCosmeticFilters"),
    Int32::New(isolate, obj->numCosmeticFilters));
  stats->Set(String::NewFromUtf8(isolate, "numExceptionFilters"),
    Int32::New(isolate, obj->numExceptionFilters));
  stats->Set(String::NewFromUtf8(isolate, "numNoFingerprintFilters"),
    Int32::New(isolate, obj->numNoFingerprintFilters));
  stats->Set(String::NewFromUtf8(isolate, "numNoFingerprintExceptionFilters"),
    Int32::New(isolate, obj->numNoFingerprintExceptionFilters));
  stats->Set(String::NewFromUtf8(isolate, "numHostAnchoredFilters"),
    Int32::New(isolate, obj->numHostAnchoredFilters));
  stats->Set(String::NewFromUtf8(isolate, "numHostAnchoredExceptionFilters"),
    Int32::New(isolate, obj->numHostAnchoredExceptionFilters));
  args.GetReturnValue().Set(stats);
}

void AdBlockClientWrap::GetMatchingStats(
    const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  Local<Object> stats = Object::New(isolate);
  stats->Set(String::NewFromUtf8(isolate, "numFalsePositives"),
    Int32::New(isolate, obj->numFalsePositives));
  stats->Set(String::NewFromUtf8(isolate, "numExceptionFalsePositives"),
    Int32::New(isolate, obj->numExceptionFalsePositives));
  stats->Set(String::NewFromUtf8(isolate, "numBloomFilterSaves"),
    Int32::New(isolate, obj->numBloomFilterSaves));
  stats->Set(String::NewFromUtf8(isolate, "numExceptionBloomFilterSaves"),
    Int32::New(isolate, obj->numExceptionBloomFilterSaves));
  stats->Set(String::NewFromUtf8(isolate, "numHashSetSaves"),
    Int32::New(isolate, obj->numHashSetSaves));
  stats->Set(String::NewFromUtf8(isolate, "numExceptionHashSetSaves"),
    Int32::New(isolate, obj->numExceptionHashSetSaves));
  args.GetReturnValue().Set(stats);
}

void AdBlockClientWrap::EnableBadFingerprintDetection(
    const v8::FunctionCallbackInfo<v8::Value>& args) {
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  obj->enableBadFingerprintDetection();
}

void AdBlockClientWrap::GenerateBadFingerprintsHeader(
    const v8::FunctionCallbackInfo<v8::Value>& args) {
  String::Utf8Value str(args[0]->ToString());
  const char * filename = *str;
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  obj->badFingerprintsHashSet->generateHeader(filename);
}

void AdBlockClientWrap::Cleanup(const FunctionCallbackInfo<Value>& args) {
  AdBlockClientWrap* obj =
    ObjectWrap::Unwrap<AdBlockClientWrap>(args.Holder());
  const char *deserializedData = obj->getDeserializedBuffer();
  if (nullptr != deserializedData) {
    delete []deserializedData;
    deserializedData = nullptr;
  }
  delete obj;
}

}  // namespace ad_block_client_wrap

