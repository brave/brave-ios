// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CryptoKit
@testable import Client

class FarblingProtectionHelperTests: XCTestCase {
  func testGivenTheSameRandomManagerThenSameFakePluginData() throws {
    // Given
    // Same random manager
    let sessionKey = SymmetricKey(size: .bits256)
    let randomManager = RandomManager(etld: "example.com", sessionKey: sessionKey)

    // Then
    // Same results
    XCTAssertEqual(
      String(describing: FarblingProtectionHelper.makeFarblingParams(from: randomManager)),
      String(describing: FarblingProtectionHelper.makeFarblingParams(from: randomManager))
    )
  }

  func testGivenDifferentRandomManagerThenDifferentFakePluginData() throws {
    // Given
    // Different random manager
    let sessionKey = SymmetricKey(size: .bits256)
    let firstRandomManager = RandomManager(etld: "example.com", sessionKey: sessionKey)
    let secondRandomManager = RandomManager(etld: "brave.com", sessionKey: sessionKey)

    // Then
    // Different results
    XCTAssertNotEqual(
      String(describing: FarblingProtectionHelper.makeFarblingParams(from: firstRandomManager)),
      String(describing: FarblingProtectionHelper.makeFarblingParams(from: secondRandomManager))
    )
  }
}
