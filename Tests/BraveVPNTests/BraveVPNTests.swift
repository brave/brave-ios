// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
@testable import BraveVPN
import BraveShared
import XCTest
import GuardianConnect

class BraveVPNTests: XCTestCase {

  override func setUp() {
//    subject = ["line-items": ["quantity": "1",
//                              "expires_date": "2023-07-27 22:19:43 Etc/GMT",
//                              "expires_date_pst": "2023-07-27 15:19:43 America/Los_Angeles",
//                              "is_in_intro_offer_period": "false",
//                              "purchase_date_ms": "1690492783000",
//                              "transaction_id": "2000000377681042",
//                              "is_trial_period": "false",
//                              "original_transaction_id": "2000000159090000",
//                              "in_app_ownership_type": "PURCHASED",
//                              "original_purchase_date_pst": "2022-09-20 08:12:56 America/Los_Angeles",
//                              "product_id": "bravevpn.yearly",
//                              "purchase_date": "2023-07-27 21:19:43 Etc/GMT",
//                              "subscription_group_identifier": "20621968",
//                              "original_purchase_date_ms": "1663686776000",
//                              "web_order_line_item_id": "2000000032896443",
//                              "expires_date_ms": "1690496383000",
//                              "purchase_date_pst": "2023-07-27 14:19:43 America/Los_Angeles",
//                              "original_purchase_date": "2022-09-20 15:12:56 Etc/GMT"],
//               "line-items-metadata": ["product_id": "bravevpn.yearly",
//                                       "original_transaction_id": "2000000159090000",
//                                       "auto_renew_product_id": "bravevpn.yearly",
//                                       "auto_renew_status": "1"]
//               ]
    
    let lineItem: NSDictionary = ["quantity": "1",
                        "expires_date": "2023-07-27 22:19:43 Etc/GMT",
                        "expires_date_pst": "2023-07-27 15:19:43 America/Los_Angeles",
                        "is_in_intro_offer_period": "false",
                        "purchase_date_ms": "1690492783000",
                        "transaction_id": "2000000377681042",
                        "is_trial_period": "false",
                        "original_transaction_id": "2000000159090000",
                        "in_app_ownership_type": "PURCHASED",
                        "original_purchase_date_pst": "2022-09-20 08:12:56 America/Los_Angeles",
                        "product_id": "bravevpn.yearly",
                        "purchase_date": "2023-07-27 21:19:43 Etc/GMT",
                        "subscription_group_identifier": "20621968",
                        "original_purchase_date_ms": "1663686776000",
                        "web_order_line_item_id": "2000000032896443",
                        "expires_date_ms": "1690496383000",
                        "purchase_date_pst": "2023-07-27 14:19:43 America/Los_Angeles",
                        "original_purchase_date": "2022-09-20 15:12:56 Etc/GMT"]
    
    let lineItemMetaData: NSDictionary = ["product_id": "bravevpn.yearly",
                                          "original_transaction_id": "2000000159090000",
                                          "auto_renew_product_id": "bravevpn.yearly",
                                          "auto_renew_status": "1"]
    
    let receiptLineItem: GRDReceiptLineItem = GRDReceiptLineItem(dictionary: lineItem as! [AnyHashable: Any])
    let receiptLineItemMetaData: GRDReceiptLineItemMetadata = GRDReceiptLineItemMetadata(dictionary: lineItemMetaData as! [AnyHashable: Any])
    
    let receiptResponse = GRDIAPReceiptResponse(withReceiptResponse: ["":""])
    receiptResponse.lineItems = [receiptLineItem]
    receiptResponse.lineItemsMetadata = [receiptLineItemMetaData]

    subject = receiptResponse
  }

  override func tearDown() {
    subject = nil

    super.tearDown()
  }

  func testAutoRenewEnabled() {
    print("Test")

    let processedLineItem = BraveVPN.processReceiptResponse(receiptResponseItem: subject)
    
    XCTAssertTrue(processedLineItem.response.status == .active)

  }


  private var subject: GRDIAPReceiptResponse!
}
