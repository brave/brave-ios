/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeUtils {

  static func generateReaderContent(_ readabilityResult: ReadabilityResult,
                                    initialStyle: ReaderModeStyle,
                                    titleNonce: String) -> String? {
    guard let tmplPath = Bundle.current.path(forResource: "Reader", ofType: "html"),
      let tmpl = try? String(contentsOfFile: tmplPath, encoding: .utf8)
    else { return nil }

    return tmpl.replacingOccurrences(of: "%READER-TITLE-NONCE%", with: titleNonce)  // This MUST be the first line/replacement!
      .replacingOccurrences(of: "%READER-STYLE%", with: initialStyle.asJSON)
      .replacingOccurrences(of: "%READER-TITLE%",
                            with: readabilityResult.title?.javaScriptEscapedString?.unquotedIfNecessary ??
                            readabilityResult.title?.htmlEntityEncodedString ?? "")
      .replacingOccurrences(of: "%READER-CREDITS%",
                            with: readabilityResult.credits?.javaScriptEscapedString?.unquotedIfNecessary ??
                            readabilityResult.credits?.htmlEntityEncodedString ?? "")
      .replacingOccurrences(of: "%READER-CONTENT%", with: readabilityResult.content)
  }
}

extension String {
  var unquotedIfNecessary: String {
    var str = self
    if str.first == "\"" || str.first == "'" {
      str = String(str.dropFirst())
    }

    if str.last == "\"" || str.last == "'" {
      str = String(str.dropLast())
    }
    return str
  }
}
