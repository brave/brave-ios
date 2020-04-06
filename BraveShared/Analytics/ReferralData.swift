/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let log = Logger.browserLogger

struct ReferralData: Codable {

    let downloadId: String
    let referralCode: String
    let offerPage: String?

    let customHeaders: [CustomHeaderData]?

    func isExtendedUrp() -> Bool {
        return offerPage != nil
    }

    init(downloadId: String, code: String, offerPage: String? = nil, customHeaders: [CustomHeaderData]? = nil) {
        self.downloadId = downloadId
        self.referralCode = code

        self.offerPage = offerPage
        self.customHeaders = customHeaders
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        downloadId = try container.decode(String.self, forKey: .downloadId)
        referralCode = try container.decode(String.self, forKey: .referralCode)
        offerPage = try container.decode(String.self, forKey: .offerPage)

        let headers = try container.decode([String: String].self, forKey: .customHeaders)
        let customHeaders = try CustomHeaderData.customHeaders(from: JSONSerialization.data(withJSONObject: headers, options: .init(rawValue: 0)))
        self.customHeaders = headers.count > 0 ? customHeaders : nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case downloadId = "download_id"
        case offerPage = "offer_page_url"
        case referralCode = "referral_code"
        case customHeaders = "headers"
    }
}
