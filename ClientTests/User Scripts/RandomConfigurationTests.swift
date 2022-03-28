// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CryptoKit
@testable import Client

class RandomConfigurationTests: XCTestCase {
  func testSameResultsForSameETLDAndSessionKey() throws {
    // Given
    // Different session keys and same eTLD+1
    let sessionKey = SymmetricKey(size: .bits256)
    let firstRandomManager = RandomConfiguration(etld: "example.com", sessionKey: sessionKey)
    let secondRandomManager = RandomConfiguration(etld: "example.com", sessionKey: sessionKey)

    // Then
    // Everything should equal
    XCTAssertEqual(firstRandomManager.seed, secondRandomManager.seed)
    XCTAssertEqual(firstRandomManager.domainKey, secondRandomManager.domainKey)

    XCTAssertEqual(
      firstRandomManager.domainSignedKey(for: "TEST"),
      secondRandomManager.domainSignedKey(for: "TEST")
    )

    // Except
    // When signing different strings
    XCTAssertNotEqual(
      firstRandomManager.domainSignedKey(for: "TEST1"),
      secondRandomManager.domainSignedKey(for: "TEST2")
    )
  }

  func testDifferentResultsForDifferentETLDAndSameSessionKey() throws {
    // Given
    // Same session keys but different eTLD+1
    let sessionKey = SymmetricKey(size: .bits256)
    let firstRandomManager = RandomConfiguration(etld: "example.com", sessionKey: sessionKey)
    let secondRandomManager = RandomConfiguration(etld: "brave.com", sessionKey: sessionKey)

    // Then
    // Nothing should equal
    XCTAssertNotEqual(firstRandomManager.seed, secondRandomManager.seed)
    XCTAssertNotEqual(firstRandomManager.domainKey, secondRandomManager.domainKey)

    XCTAssertNotEqual(
      firstRandomManager.domainSignedKey(for: "TEST"),
      secondRandomManager.domainSignedKey(for: "TEST")
    )

    XCTAssertNotEqual(
      firstRandomManager.domainSignedKey(for: "TEST1"),
      secondRandomManager.domainSignedKey(for: "TEST2")
    )
  }

  func testDifferentResultsForSameETLDAndDifferentSessionKey() throws {
    // Given
    // Different session keys but same eTLD+1
    let firstRandomManager = RandomConfiguration(etld: "example.com", sessionKey: SymmetricKey(size: .bits256))
    let secondRandomManager = RandomConfiguration(etld: "example.com", sessionKey: SymmetricKey(size: .bits256))

    // Then
    // Nothing should equal
    XCTAssertNotEqual(firstRandomManager.seed, secondRandomManager.seed)
    XCTAssertNotEqual(firstRandomManager.domainKey, secondRandomManager.domainKey)

    XCTAssertNotEqual(
      firstRandomManager.domainSignedKey(for: "TEST"),
      secondRandomManager.domainSignedKey(for: "TEST")
    )

    XCTAssertNotEqual(
      firstRandomManager.domainSignedKey(for: "TEST1"),
      secondRandomManager.domainSignedKey(for: "TEST2")
    )
  }
}
