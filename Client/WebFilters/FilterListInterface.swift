// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data

protocol FilterListInterface {
  var componentId: String { get }
  var uuid: String { get }
}
 
extension FilterListInterface {
  func makeResources() -> [ResourceDownloader.Resource] {
    return [
      .filterListContentBlockingBehaviors(uuid: uuid, componentId: componentId)
    ]
  }
}

extension FilterListSetting: FilterListInterface {}
extension FilterList: FilterListInterface {}
