// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

class BraveLeoSkusManager {
  
  enum Product: String {
    case leoMonthly = "braveleo.monthly"
    case leoYearly = "braveleo.yearly"
    
    var webStorageKey: String {
      switch self {
      case .leoMonthly, .leoYearly: return "braveLeo.receipt"
      }
    }
    
    var skusDomain: String {
      switch self {
      case .leoMonthly, .leoYearly: return "leo.bravesoftware.com"
      }
    }
  }
  
  enum SkusError: Error {
    case skusServiceUnavailable
    case invalidBundleId
    case invalidReceiptURL
    case invalidReceiptData
    case cannotEncodeReceipt
    case cannotCreateOrder
  }
  
  private let product: Product
  private let skusService: SkusSkusService?
  
  init(product: Product, isPrivateMode: Bool) {
    self.product = product
    self.skusService = Skus.SkusServiceFactory.get(privateMode: isPrivateMode)
  }
  
  // MARK: - Implementation

  private var receipt: String {
    get throws {
      guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
        throw SkusError.invalidReceiptURL
      }
      
      do {
        return try Data(contentsOf: receiptUrl).base64EncodedString
      } catch {
        // Logger.module.error("Failed to retrieve AppStore Receipt: \(error.localizedDescription)")
        throw SkusError.invalidReceiptData
      }
    }
  }
  
  private var encodedReceipt: (product: Product, value: String) {
    get throws {
      struct Receipt: Codable {
        let type: String
        let rawReceipt: String
        let package: String
        let subscriptionId: String
        
        enum CodingKeys: String, CodingKey {
          case type, package
          case rawReceipt = "raw_receipt"
          case subscriptionId = "subscription_id"
        }
      }
      
      let receipt = try receipt
      guard let bundleId = Bundle.main.bundleIdentifier else {
        throw SkusError.invalidBundleId
      }
      
      let json = Receipt(type: "ios",
                         rawReceipt: receipt,
                         package: bundleId,
                         subscriptionId: product.rawValue)
      
      do {
        return (product: product, value: try JSONEncoder().encode(json).base64EncodedString)
      } catch {
        // Logger.module.error("Failed to serialize AppStore Receipt for LocalStorage: \(error.localizedDescription)")
        throw SkusError.cannotEncodeReceipt
      }
    }
  }
  
  @MainActor
  func createOrder() async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    let receipt = try encodedReceipt
    return try await withCheckedThrowingContinuation { @MainActor continuation in
      skusService.createOrder(fromReceipt: product.skusDomain, receipt: receipt.value) { orderId in
        if orderId.isEmpty {
          continuation.resume(throwing: SkusError.cannotCreateOrder)
          return
        }
        
        continuation.resume(returning: orderId)
      }
    }
  }
  
  @MainActor
  func submitReceipt(orderId: String) async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    let receipt = try encodedReceipt
    return try await withCheckedThrowingContinuation { @MainActor continuation in
      skusService.submitReceipt(product.skusDomain, orderId: orderId, receipt: receipt.value) { response in
        continuation.resume(returning: response)
      }
    }
  }
}
