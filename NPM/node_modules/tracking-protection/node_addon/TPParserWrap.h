/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TPPARSERWRAP_H_
#define TPPARSERWRAP_H_

#include <node.h>
#include <node_object_wrap.h>

#include "../TPParser.h"

namespace TPParserWrap {

    /**
     * Wraps Tracking Protection for use in Node
     */
    class CTPParserWrap : public CTPParser, public node::ObjectWrap {
    public:
        static void Init(v8::Local<v8::Object> exports);

    private:
        CTPParserWrap();
        virtual ~CTPParserWrap();

        static void New(const v8::FunctionCallbackInfo<v8::Value>& args);

        static void AddTracker(const v8::FunctionCallbackInfo<v8::Value>& args);
        static void MatchesTracker(const v8::FunctionCallbackInfo<v8::Value>& args);
        static void AddFirstPartyHosts(const v8::FunctionCallbackInfo<v8::Value>& args);
        static void FindFirstPartyHosts(const v8::FunctionCallbackInfo<v8::Value>& args);
        static void Serialize(const v8::FunctionCallbackInfo<v8::Value>& args);
        static void Deserialize(const v8::FunctionCallbackInfo<v8::Value>& args);
        static void Cleanup(const v8::FunctionCallbackInfo<v8::Value>& args);

        static v8::Persistent<v8::Function> constructor;
    };

}   // namespace TPParserWrap

#endif  //TPPARSERWRAP_H_
