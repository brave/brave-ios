// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

struct Amount: Decodable {
    let currency: String
    let value: String
}

struct Item: Decodable {
    let label: String
    let amount: Amount
}

struct PaymentRequestDetailsHandler: Decodable {
    let total: Item
    let displayItems: [Item]
}
