/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <node_buffer.h>
#include "TPParserWrap.h"

namespace TPParserWrap {

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

    char *deserializedData = nullptr;

    Persistent<Function> CTPParserWrap::constructor;

    CTPParserWrap::CTPParserWrap() {
    }

    CTPParserWrap::~CTPParserWrap() {
    }

    void CTPParserWrap::Init(Local<Object> exports) {
        Isolate* isolate = exports->GetIsolate();

        // Prepare constructor template
        Local<FunctionTemplate> tpl = FunctionTemplate::New(isolate, New);
        tpl->SetClassName(String::NewFromUtf8(isolate, "CTPParser"));
        tpl->InstanceTemplate()->SetInternalFieldCount(1);

        NODE_SET_PROTOTYPE_METHOD(tpl, "addTracker", CTPParserWrap::AddTracker);
        NODE_SET_PROTOTYPE_METHOD(tpl, "matchesTracker", CTPParserWrap::MatchesTracker);
        NODE_SET_PROTOTYPE_METHOD(tpl, "addFirstPartyHosts", CTPParserWrap::AddFirstPartyHosts);
        NODE_SET_PROTOTYPE_METHOD(tpl, "findFirstPartyHosts", CTPParserWrap::FindFirstPartyHosts);
        NODE_SET_PROTOTYPE_METHOD(tpl, "serialize", CTPParserWrap::Serialize);
        NODE_SET_PROTOTYPE_METHOD(tpl, "deserialize", CTPParserWrap::Deserialize);
        NODE_SET_PROTOTYPE_METHOD(tpl, "cleanup", CTPParserWrap::Cleanup);

        constructor.Reset(isolate, tpl->GetFunction());
        exports->Set(String::NewFromUtf8(isolate, "CTPParser"),
                     tpl->GetFunction());
    }

    void CTPParserWrap::New(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();

        if (args.IsConstructCall()) {
            // Invoked as constructor: `new CTPParserWrap(...)`
            CTPParserWrap* obj = new CTPParserWrap();
            obj->Wrap(args.This());
            args.GetReturnValue().Set(args.This());
        } else {
            // Invoked as plain function `CTPParserWrap(...)`,
            // turn into construct call.
            const int argc = 1;
            Local<Value> argv[argc] = { args[0] };
            Local<Function> cons = Local<Function>::New(isolate, constructor);
            args.GetReturnValue().Set(cons->NewInstance(argc, argv));
        }
    }

    void CTPParserWrap::AddTracker(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();
        if (args.Length() < 1) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong number of arguments")));
            return;
        }

        if (!args[0]->IsString()) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong arguments")));
            return;
        }

        String::Utf8Value str(args[0]->ToString());
        const char * buffer = *str;

        CTPParserWrap* obj = ObjectWrap::Unwrap<CTPParserWrap>(args.Holder());
        obj->addTracker(buffer);
    }

    void CTPParserWrap::MatchesTracker(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();
        if (args.Length() < 2) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong number of arguments")));
            return;
        }

        if (!args[0]->IsString() || !args[1]->IsString()) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong arguments")));
            return;
        }

        String::Utf8Value strFirstPartyHost(args[0]->ToString());
        String::Utf8Value strHost(args[1]->ToString());
        const char * bufferFirstPartyHost = *strFirstPartyHost;
        const char * bufferHost = *strHost;

        CTPParserWrap* obj = ObjectWrap::Unwrap<CTPParserWrap>(args.Holder());
        args.GetReturnValue().Set(Boolean::New(isolate, obj->matchesTracker(bufferFirstPartyHost, bufferHost)));
    }

    void CTPParserWrap::AddFirstPartyHosts(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();
        if (args.Length() < 2) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong number of arguments")));
            return;
        }

        if (!args[0]->IsString() || !args[1]->IsString()) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong arguments")));
            return;
        }

        String::Utf8Value strFirstHost(args[0]->ToString());
        String::Utf8Value strThirdPartyHosts(args[1]->ToString());

        const char* firstHost = *strFirstHost;
        const char* thirdPartyHosts = *strThirdPartyHosts;

        CTPParserWrap* obj = ObjectWrap::Unwrap<CTPParserWrap>(args.Holder());
        obj->addFirstPartyHosts(firstHost, thirdPartyHosts);
    }

    void CTPParserWrap::FindFirstPartyHosts(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();
        if (args.Length() < 1) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong number of arguments")));
            return;
        }

        if (!args[0]->IsString()) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong arguments")));
            return;
        }

        String::Utf8Value strFirstHost(args[0]->ToString());

        const char* firstHost = *strFirstHost;
        CTPParserWrap* obj = ObjectWrap::Unwrap<CTPParserWrap>(args.Holder());
        char* thirdPartyHosts = obj->findFirstPartyHosts(firstHost);
        if (nullptr != thirdPartyHosts) {
            v8::Local<String> toReturn = String::NewFromUtf8(isolate, thirdPartyHosts);
            args.GetReturnValue().Set(toReturn);
            delete []thirdPartyHosts;
        }
    }

    void CTPParserWrap::Serialize(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();

        CTPParserWrap* obj = ObjectWrap::Unwrap<CTPParserWrap>(args.Holder());

        unsigned int totalSize = 0;
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
        ::memcpy(node::Buffer::Data(localBuffer), data, totalSize);

        delete []data;

        args.GetReturnValue().Set(localBuffer);
    }

    void CTPParserWrap::Deserialize(const FunctionCallbackInfo<Value>& args) {
        Isolate* isolate = args.GetIsolate();
        if (args.Length() < 1) {
            isolate->ThrowException(Exception::TypeError(
                                                         String::NewFromUtf8(isolate, "Wrong number of arguments")));
            return;
        }

        unsigned char *buf = (unsigned char *)node::Buffer::Data(args[0]);
        size_t length = node::Buffer::Length(args[0]);

        if (nullptr != deserializedData) {
            delete []deserializedData;
        }
        deserializedData = new char[length];
        memcpy(deserializedData, buf, length);

        CTPParserWrap* obj = ObjectWrap::Unwrap<CTPParserWrap>(args.Holder());
        args.GetReturnValue().Set(Boolean::New(isolate, obj->deserialize(deserializedData)));
    }

    void CTPParserWrap::Cleanup(const FunctionCallbackInfo<Value>& args) {
        if (nullptr != deserializedData) {
            delete []deserializedData;
            deserializedData = nullptr;
        }
    }

}   //namespace TPParserWrap
