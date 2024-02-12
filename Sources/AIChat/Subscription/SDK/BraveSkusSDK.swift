// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import os.log
import BraveCore

// https://github.com/brave/brave-core/blob/master/components/skus/browser/rs/lib/src/models.rs#L137

/// A structure representing the customer's credentials
/// Returned by credentialsSummary
public struct SkusCredentialSummary: Codable {
  let order: SkusOrder
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

/// A structure representing the customer's order information
/// Returned by refreshOrder
public struct SkusOrder: Codable {
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
  let items: [SkusOrderItem]
  
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
  
  /// A structure representing a Line-Item within the customer's order
  /// An order can contain multiple items
  public struct SkusOrderItem: Codable {
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
    let credentialType: SkusCredentialType     // time-limited-v2
    
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
    
    /// A structure representing the customer's credential type
    enum SkusCredentialType: String, Codable {
      case singleUse = "single-use"
      case timeLimited = "time-limited"
      case timeLimitedv2 = "time-limited-v2"
    }
  }
}

/// A class for handling Brave Skus via SkusService
public class BraveSkusSDK {
  
  public init(product: BraveStoreProduct) {
    self.product = product
    self.skusService = Skus.SkusServiceFactory.get(privateMode: false)
  }
  
  // MARK: - Structures
  
  /// An error related to Skus handling
  public enum SkusError: Error {
    /// The SkusService failed is unavailable for use
    /// Can be thrown due to SkusServiceFactory returning null
    case skusServiceUnavailable
    
    /// The Application's BundleID is invalid
    /// Can be thrown when encoding AppStore receipts
    case invalidBundleId
    
    /// The URL of the receipt stored in the Application Bundle is null or invalid
    case invalidReceiptURL
    
    /// The receipt is invalid
    /// Thrown when Skus cannot validate the receipt and fetch credentials
    case invalidReceiptData
    
    /// The receipt cannot be encoded/serialized for use with Skus
    case cannotEncodeReceipt
    
    /// The SDK was unable to create a purchase order or retrieve an existing order
    case cannotCreateOrder
    
    ///  The SDK was unable to fetch the customer's purchase credentials
    case cannotFetchCredentials
    
    /// There was an error decoding an SDK response
    /// Can be thrown when the SDK fails to decode an order, order summary, credentials, etc
    case decodingError
  }
  
  // MARK: - Private
  
  /// The product the Skus SDK will be operating on
  private let product: BraveStoreProduct
  
  /// The Skus Brave-Core Service
  private let skusService: SkusSkusService?
  
  /// A custom JSON Decoder that handles decoding Skus Object dates as ISO-8601
  /// with optional milli-seconds
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
  
  /// Encodes a receipt for use with SkusSDK and Brave's Account Linking page
  /// - Parameter product: The purchased product to create a receipt for
  /// - Returns: Returns a Receipt structure encoded as Base64
  public static func receipt(for product: BraveStoreProduct) throws -> String {
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
    
    // Retrieve the AppStore receipt stored in the Application bundle
    let receipt = try AppStoreReceipt.receipt
    
    // Fetch the Application's Bundle-ID
    guard let bundleId = Bundle.main.bundleIdentifier else {
      throw SkusError.invalidBundleId
    }
    
    // Create a Receipt structure for Skus-iOS
    let json = Receipt(type: "ios",
                       rawReceipt: receipt,
                       package: bundleId,
                       subscriptionId: product.rawValue)
    
    do {
      // Encode the Receipt as JSON and Base-64 Encode it
      return try JSONEncoder().encode(json).base64EncodedString
    } catch {
      Logger.module.error("[BraveSkusSDK] - Failed to serialize AppStore Receipt for LocalStorage: \(error.localizedDescription)")
      throw SkusError.cannotEncodeReceipt
    }
  }
  
  // MARK: - Implementation
  
  /// Creates an order from an AppStore Receipt
  /// If an order already exists, returns the existing Order-ID
  /// - Returns: The Order-ID associated with the AppStore receipt
  @MainActor
  public func createOrder() async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    let receipt = try BraveSkusSDK.receipt(for: product)
    return try await withCheckedThrowingContinuation { @MainActor continuation in
      skusService.createOrder(fromReceipt: product.skusDomain, receipt: receipt) { orderId in
        if orderId.isEmpty {
          continuation.resume(throwing: SkusError.cannotCreateOrder)
          return
        }
        
        continuation.resume(returning: orderId)
      }
    }
  }
  
  /// Links an existing order to an AppStore Receipt
  /// - Returns: The Order-ID associated with the AppStore receipt
  /// - Throws: An exception if the Order could not be linked with the receipt or if the Order already exists
  @MainActor
  public func submitReceipt(orderId: String) async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    let receipt = try BraveSkusSDK.receipt(for: product)
    return try await withCheckedThrowingContinuation { @MainActor continuation in
      skusService.submitReceipt(product.skusDomain, orderId: orderId, receipt: receipt) { response in
        continuation.resume(returning: response)
      }
    }
  }
  
  /// Retrieves and refreshes the local cached order for the given Order-ID
  /// - Parameter orderId: The ID of the order to retrieve
  /// - Returns: The order information for the given order
  /// - Throws: An exception if the order could not be found or decoded
  @MainActor
  @discardableResult
  public func refreshOrder(orderId: String) async throws -> SkusOrder {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    func decode<T: Decodable>(_ response: String) throws -> T {
      guard let data = response.data(using: .utf8) else {
        throw SkusError.decodingError
      }
       
      return try self.jsonDecoder.decode(T.self, from: data)
    }
    
    return try await decode(skusService.refreshOrder(product.skusDomain, orderId: orderId)) as SkusOrder
  }
  
  /// Retrieves the Customer's Credentials Summary
  /// - Returns: The customer's credentials summary which includes their order information
  /// - Throws: An exception if the credentials could not be retrieved or decoded
  @MainActor
  public func credentialsSummary() async throws -> SkusCredentialSummary {
    func decode<T: Decodable>(_ response: String) throws -> T {
      guard let data = response.data(using: .utf8) else {
        throw SkusError.decodingError
      }
      
      return try self.jsonDecoder.decode(T.self, from: data)
    }
    
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    return try await decode(skusService.credentialSummary(product.skusDomain)) as SkusCredentialSummary
  }
  
  /// Retrieves the Customer's Credentials for a specified Order
  /// - Parameter orderId: The ID of the order whose credentials to retrieve
  /// - Throws: An exception if fetching credentials failed
  @MainActor
  public func fetchCredentials(orderId: String) async throws {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    let result = await skusService.fetchOrderCredentials(product.skusDomain, orderId: orderId)
    if !result.isEmpty {
      Logger.module.error("[BraveSkusSDK] - Failed to Fetch Credentials: \(result)")
      throw SkusError.cannotFetchCredentials
    }
  }
  
  /// Retrieves the Customer's Credentials encoded as an HTTP-Cookie
  /// - Parameter path: Attribute that indicates a URL path that must exist in the requested URL in order to send the Cookie header.
  /// - Returns: The Customer's Credentials Cookie.
  ///            Example: `__Secure-sku#brave-product-premium=EncodedCookie;path=*;samesite=strict;expires=Tue, 06 Feb 2024 16:18:43 GMT;secure*`
  @MainActor
  public func prepareCredentials(path: String = "*") async throws -> String {
    guard let skusService = skusService else {
      throw SkusError.skusServiceUnavailable
    }
    
    return await skusService.prepareCredentialsPresentation(product.skusDomain, path: path)
  }
  
  @MainActor
  public func testSkus() async throws {
    let orderId = try await createOrder()
    let order = try await refreshOrder(orderId: orderId)
    assert(orderId == order.id, "Skus Order-Id Mismatch")
    
    try await fetchCredentials(orderId: order.id)
    
    let credentialsToken = try await prepareCredentials(path: "/")
    assert(credentialsToken.starts(with: "__Secure-sku#brave-leo-premium"), "Invalid Skus Credentials")
    
    let credentials = try await credentialsSummary()
    assert(credentials.order.id ==  orderId, "Skus Credentials Mismatch")
  }
}
