/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveUI
import SDWebImageSwiftUI

struct NFTImageView<Fallback: View>: View {
  let urlString: String
  
  private var fallback: () -> Fallback
  
  init(
    urlString: String,
    @ViewBuilder fallback: @escaping () -> Fallback
  ) {
    self.urlString = urlString
    self.fallback = fallback
  }
  
  var body: some View {
    if urlString.hasPrefix("data:image/") {
      WebImageReader(url: URL(string: urlString)) { image, isFinished in
        if let image = image {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
        } else {
          fallback()
        }
      }
    } else {
      if urlString.hasSuffix(".svg") {
        WebSVGImageView(url: URL(string: urlString))
      } else {
        WebImage(url: URL(string: urlString))
          .resizable()
          .placeholder { fallback() }
          .indicator(.activity)
          .transition(.fade(duration: 0.5))
          .aspectRatio(contentMode: .fit)
      }
    }
  }
}
