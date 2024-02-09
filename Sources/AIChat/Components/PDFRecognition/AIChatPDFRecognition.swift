// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import PDFKit

class AIChatPDFRecognition {
  static func parse(url: URL) async -> String? {
    guard let pdf = PDFDocument(url: url) else { return nil }
    
    let pageCount = pdf.pageCount
    let documentContent = NSMutableAttributedString()
    
    for i in 0 ..< pageCount {
      guard let page = pdf.page(at: i) else { continue }
      guard let pageContent = page.attributedString else { continue }
      documentContent.append(pageContent)
    }
    
    return documentContent.string
  }
}
