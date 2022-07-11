// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

public struct FaviconAttributesContainer: Codable {
  public var image: UIImage?
  public var backgroundColor: UIColor?
  public var contentMode: UIView.ContentMode = .scaleAspectFit
  public var includePadding: Bool = false

  public init(
    image: UIImage? = nil,
    backgroundColor: UIColor? = nil,
    contentMode: UIView.ContentMode = .scaleAspectFit,
    includePadding: Bool = false
  ) {
    self.image = image
    self.backgroundColor = backgroundColor
    self.contentMode = contentMode
    self.includePadding = includePadding
  }

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case image
    case backgroundColor
    case contentMode
    case includePadding
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(image?.sd_imageData(), forKey: .image)
    try container.encode(backgroundColor?.rgb, forKey: .backgroundColor)
    try container.encode(contentMode.rawValue, forKey: .contentMode)
    try container.encode(includePadding, forKey: .includePadding)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let imageData = try container.decode(Data?.self, forKey: .image) {
      image = UIImage(data: imageData)
    }
    if let rgb = try container.decode(Int?.self, forKey: .backgroundColor) {
      backgroundColor = UIColor(rgb: rgb)
    }
    contentMode = UIView.ContentMode(rawValue: try container.decode(Int.self, forKey: .contentMode)) ?? .scaleAspectFit
    includePadding = try container.decode(Bool.self, forKey: .includePadding)
  }
}
