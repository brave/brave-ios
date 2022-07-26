// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

private let log = Logger.browserLogger

public class WebcompatReporter {
  private struct BaseURL {
    static let staging = "laptop-updates.bravesoftware.com"
    static let prod = "laptop-updates.brave.com"
  }

  private static let apiKeyPlistKey = "API_KEY"
  private static let version = "1"

  /// A custom user agent to send along with reports
  public static var userAgent: String?

  /// Report a webcompat issue on a given website
  ///
  /// - Returns: A deferred boolean on whether or not it reported successfully (default queue: main)
  @discardableResult
  public static func reportIssue(on url: URL) async -> Bool {
    let baseURL = AppConstants.buildChannel == .debug ? BaseURL.staging : BaseURL.prod
    let apiKey = (Bundle.main.infoDictionary?[apiKeyPlistKey] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    var components = URLComponents()
    components.scheme = "https"
    components.host = baseURL
    components.path = "/\(version)/webcompat"

    guard let baseDomain = url.baseDomain,
      let key = apiKey,
      let endpoint = components.url
    else {
      log.error("Failed to setup webcompat request")
      return false
    }

    // We want to ensure that the URL _can_ be normalized, since `domainURL` will return itself
    // (the full URL) if the URL can't be normalized. If the URL can't be normalized, send only
    // the base domain without scheme.
    let domain = url.normalizedHost() != nil ? url.domainURL.absoluteString : baseDomain

    let payload = [
      "domain": domain,
      "api_key": key,
    ]

    do {
      var request = URLRequest(url: endpoint)
      request.httpMethod = "POST"
      request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
      if let userAgent = userAgent {
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
      }

      let session = URLSession(configuration: .ephemeral)
      return await withCheckedContinuation { continuation in
        let task = session.dataTask(with: request) { data, response, error in
          var success: Bool = true
          if let error = error {
            log.error("Failed to report webcompat issue: \(error)")
            success = false
          }
          if let response = response as? HTTPURLResponse {
            success = response.statusCode >= 200 && response.statusCode < 300
            if !success {
              log.error("Failed to report webcompat issue: Status Code \(response.statusCode)")
            }
          }
          continuation.resume(returning: success)
        }
        task.resume()
      }
    } catch {
      log.error("Failed to setup webcompat request payload: \(error)")
      return false
    }
  }
}
