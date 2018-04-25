/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef LISTS_DEFAULT_H_
#define LISTS_DEFAULT_H_

#include <vector>
#include "../filter_list.h"

const std::vector<FilterList> default_lists = {
  {
    "67F880F5-7602-4042-8A3D-01481FD7437A",
    "https://easylist.to/easylist/easylist.txt",
    "EasyList",
    {},
    "https://easylist.to/"
  }, {
    "200392E7-9A0F-40DF-86EB-6AF7E4071322",
    "https://raw.githubusercontent.com/brave/adblock-lists/master/ublock-unbreak.txt", // NOLINT
    "uBlock Unbreak",
    {},
    "https://github.com/gorhill/uBlock"
  }, {
    "2FBEB0BC-E2E1-4170-BAA9-05E76AAB5BA5",
    "https://raw.githubusercontent.com/brave/adblock-lists/master/brave-unbreak.txt", // NOLINT
    "Brave Unblock",
    {},
    "https://github.com/brave/adblock-lists"
  }, {
    "BCDF774A-7845-4121-B7EB-77EB66CEDF84",
    "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt", // NOLINT
    "NoCoin Filter List",
    {},
    "https://github.com/hoshsadiq/adblock-nocoin-list/"
  }
};

#endif  // LISTS_DEFAULT_H_
