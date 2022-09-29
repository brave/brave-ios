// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

struct FilterList: Decodable, Identifiable {
  enum CodingKeys: String, CodingKey {
    case uuid, title, componentId, description = "desc", urlString = "url"
  }
  
  /// The component ID of the filter list that blocks "Open in app" notices
  public static let mobileNotificationsComponentID = "bfpgedeaaibpoidldhjcknekahbikncb"
  /// The component ID of the filter list that blocks cookie consent notices.
  public static let cookieConsentNoticesComponentID = "cdbbhgbmjhfnhnmgeddbliobbofkgdhe"
  
  // TODO: @JS Remove these values once we compile block lists from raw filter list text files: #5975
  /// The UUID of the filter list that blocks cookie consent notices.
  /// We need this in case the user enables this filter list before our filter lists have loaded.
  public static let cookieConsentNoticesUUID = "AC023D22-AE88-4060-A978-4FEEEC4221693"
  /// The UUID of the filter list that blocks "Open in app" notices
  /// We need this in case the user enables this filter list before our filter lists have loaded.
  public static let mobileNotificationsUUID = "2F3DCE16-A19A-493C-A88F-2E110FBD37D6"
  
  let componentId: String
  let title: String
  let description: String
  let urlString: String
  var isEnabled: Bool = false
  
  // TODO: @JS Remove this value once we compile block lists from raw filter list text files: #5975
  @available(*, deprecated, message: "Use `componentId` instead")
  let uuid: String
  
  var id: String { return componentId }
  
  init(from filterList: AdblockFilterListCatalogEntry, isEnabled: Bool) {
    self.uuid = filterList.uuid
    self.title = filterList.title
    self.description = filterList.desc
    self.componentId = filterList.componentId
    self.isEnabled = isEnabled
    self.urlString = filterList.url
  }
  
  func makeRuleType() -> ContentBlockerManager.BlocklistRuleType {
    return .filterList(componentId: componentId)
  }
}
