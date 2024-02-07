// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

// https://github.com/brave/brave-core/blob/master/components/skus/browser/rs/lib/src/models.rs#L137

/// Returned by credentialsSummary
struct CredentialSummary: Codable {
  let order: Order
  let remainingCredentialCount: UInt   // 512
  let expiresAt: Date?                 // 2024-02-06T16:18:43
  let active: Bool                     // true
  let nextActiveAt: Date?              // 2024-02-06T16:18:43
  
  enum CodingKeys: String, CodingKey {
    case order
    case remainingCredentialCount = "remaining_credential_count"
    case expiresAt = "expires_at"
    case active
    case nextActiveAt = "next_active_at"
  }
}

/// Returned by refreshOrder
struct Order: Codable {
  let id: String              // UUID
  let createdAt: Date         // 2024-02-05T23:14:19.260973
  let currency: String        // USD
  let updatedAt: Date         // 2024-02-05T23:14:19.260973
  let totalPrice: Double      // 15.0
  let location: String        // leo.bravesoftware.com
  let merchantId: String      // brave.com
  let status: String          // paid
  let expiresAt: Date?        // 2024-02-05T23:14:19.260973
  let lastPaidAt: Date?       // 2024-02-05T23:14:19.260973
  let items: [OrderItem]
  
  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case currency
    case updatedAt = "updated_at"
    case totalPrice = "total_price"
    case location
    case merchantId = "merchant_id"
    case status
    case items
    // case metadata
    case expiresAt = "expires_at"
    case lastPaidAt = "last_paid_at"
  }
  
  struct OrderItem: Codable {
    let id: String                         // UUID
    let orderId: String                    // UUID
    let sku: String                        // brave-leo-premium
    let createdAt: Date                    // 2024-02-05T21:33:58.598300
    let updatedAt: Date                    // 2024-02-05T21:33:58.598300
    let currency: String                   // USD
    let quantity: Int                      // 1
    let price: Double                      // 15.0
    let subTotal: Double                   // 15.0
    let location: String                   // leo.bravesoftware.com
    let productDescription: String         // Premium access to Leo
    let credentialType: CredentialType     // time-limited-v2
    
    enum CodingKeys: String, CodingKey {
      case id
      case orderId = "order_id"
      case sku
      case createdAt = "created_at"
      case updatedAt = "updated_at"
      case currency
      case quantity
      case price
      case subTotal = "subtotal"
      case location
      case productDescription = "description"
      case credentialType = "credential_type"
    }
    
    enum CredentialType: String, Codable {
      case singleUse = "single-use"
      case timeLimited = "time-limited"
      case timeLimitedv2 = "time-limited-v2"
    }
  }
}

/// Class for handling Skus SDK via SkusService
class LeoSkusSDK {
  
  init(product: Product, isPrivateMode: Bool) {
    self.product = product
    self.skusService = Skus.SkusServiceFactory.get(privateMode: isPrivateMode)
  }
  
  // MARK: - Structures
  
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
    case decodingError
  }
  
  // MARK: - Private
  
  private let product: Product
  
  private let skusService: SkusSkusService?
  
  private let jsonDecoder: JSONDecoder = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [
      .withYear,
      .withMonth,
      .withDay,
      .withTime,
      .withDashSeparatorInDate,
      .withColonSeparatorInTime
    ]
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom({ decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)
      
      guard let date = formatter.date(from: try container.decode(String.self)) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
      }
      
      return date
    })
    return decoder
  }()
  
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
  
  // MARK: - Implementation
  
  /// Creates an order from an AppStore Receipt
  /// Returns existing Order-ID if one is already created
  /// Returns Order-ID
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
  
  /// Links an existing order to an AppStore Receipt
  /// Returns Order-ID
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
  
  /// Updates the local cached order via the given Order-ID
  @MainActor
  func refreshOrder(orderId: String) async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    return await skusService.refreshOrder(product.skusDomain, orderId: orderId)
  }
  
  ///  Fetch and refresh order details of a subscription
  @MainActor
  func fetchAndRefreshOrderDetails() async throws -> (orderId: String, orderDetails: Order) {
    func decode<T: Decodable>(_ response: String) throws -> T {
      guard let data = response.data(using: .utf8) else {
        throw SkusError.decodingError
      }
       
      return try self.jsonDecoder.decode(T.self, from: data)
    }
    
    do {
      let orderId = try await createOrder()
      let order = try await decode(refreshOrder(orderId: orderId)) as Order
      let errorCode = try await fetchCredentials(orderId: orderId)
      
      if orderId.isEmpty || !errorCode.isEmpty {
        throw SkusError.invalidReceiptData
      }

      return (orderId, order)
    } catch {
      throw error
    }

  }
  
  /// Fetches Credentials Summary.
  @MainActor
  func credentialsSummary() async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    return await skusService.credentialSummary(product.skusDomain)
  }
  
  @MainActor
  func fetchCredentials(orderId: String) async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    return await skusService.fetchOrderCredentials(product.skusDomain, orderId: orderId)
  }
  
  @MainActor
  func prepareCredentials(path: String = "*") async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    /*
     "__Secure-sku#brave-leo-premium=eyJ0eXBlIjoidGltZS1saW1pdGVkLXYyIiwidmVyc2lvbiI6Miwic2t1IjoiYnJhdmUtbGVvLXByZW1pdW0iLCJwcmVzZW50YXRpb24iOiJleUoyWVd4cFpFWnliMjBpT2lJeU1ESTBMVEF5TFRBMVZERTJPakU0T2pReklpd2lkbUZzYVdSVWJ5STZJakl3TWpRdE1ESXRNRFpVTVRZNk1UZzZORE1pTENKcGMzTjFaWElpT2lKaWNtRjJaUzVqYjIwL2MydDFQV0p5WVhabExXeGxieTF3Y21WdGFYVnRJaXdpZENJNklsVkZaMGt4ZFdsSVduZzBjSFJxTlVWS1ozSldWM1ZqYmtOcmMwOXpVSEpqYmtoMldXeG9TR2d5VG10MWRHZHliME5tUW1Kb1N6YzVNbWh6UlM4NFpHMTZhMjVsVldsVk1rRkxia05xVVV4NGVtbHhSVEpSUFQwaUxDSnphV2R1WVhSMWNtVWlPaUo0U1RVdldHSk9ka2cwWmxSSk1ua3JOMnRqYVRsS1JubGtjVWt2Vmt0bFpUQldaa1owWkVncmR6Rk9jRUpDTjNaSlJrSnljVmM1YTNJMlVVZ3lSQ3RQV1U1VWVXZGpNbTh4V0cxb1ZsaFNNVFZOTVd4blFUMDlJbjA9In0%3D;path=*;samesite=strict;expires=Tue, 06 Feb 2024 16:18:43 GMT;secure"
     */
    return await skusService.prepareCredentialsPresentation(product.skusDomain, path: path)
  }
  
  @MainActor
  func testSkus() async throws {
    func decode<T: Decodable>(_ response: String) throws -> T {
      guard let data = response.data(using: .utf8) else {
        throw SkusError.decodingError
      }
      
      return try self.jsonDecoder.decode(T.self, from: data)
    }
    
    let orderId = try await createOrder()
    let order = try await decode(refreshOrder(orderId: orderId)) as Order
    assert(orderId == order.id, "Skus Order-Id Mismatch")
    
    let errorCode = try await fetchCredentials(orderId: order.id)
    assert(errorCode.isEmpty || errorCode == "{}", "Failed to fetch Skus Credentials")
    
    let credentialsToken = try await prepareCredentials(path: "/")
    assert(credentialsToken.starts(with: "__Secure-sku#brave-leo-premium"), "Invalid Skus Credentials")
    
    let credentials = try await decode(credentialsSummary()) as CredentialSummary
    assert(credentials.order.id ==  orderId, "Skus Credentials Mismatch")
  }
}
