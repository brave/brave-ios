/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <node.h>
#include "TPParserWrap.h"

namespace TPParserWrap {

    using v8::Local;
    using v8::Object;

    void InitAll(Local<Object> exports) {
        CTPParserWrap::Init(exports);
    }

    NODE_MODULE(tp_node_addon, InitAll)

}  // namespace TPParserWrap
