/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef FILTER_LIST_H_
#define FILTER_LIST_H_

#include <string>
#include <vector>

class FilterList {
 public:
    FilterList(const std::string &uuid,
      const std::string &url,
      const std::string &title,
      const std::vector<std::string> &langs,
      const std::string &support_url) :
        uuid(uuid), url(url), title(title),
        langs(langs), support_url(support_url) {
    }

    const std::string uuid;
    const std::string url;
    const std::string title;
    const std::vector<std::string> langs;
    const std::string support_url;
};

#endif  // FILTER_LIST_H_
