/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared
import Combine
import BraveCore
import Data
import os.log

struct CosmeticFilterModel: Codable {
  let hideSelectors: [String]
  let styleSelectors: [String: [String]]
  let exceptions: [String]
  let injectedScript: String
  let genericHide: Bool
  
  enum CodingKeys: String, CodingKey {
    case hideSelectors = "hide_selectors"
    case styleSelectors = "style_selectors"
    case exceptions = "exceptions"
    case injectedScript = "injected_script"
    case genericHide = "generichide"
  }
  
  func makeCSSRules() -> String {
    let hideRules = hideSelectors.reduce("") { partialResult, rule in
      return [partialResult, rule, "{display: none !important}\n"].joined()
    }
    
    let styleRules = styleSelectors.reduce("") { partialResult, entry in
      let subRules = entry.value.reduce("") { partialResult, subRule in
        return [partialResult, subRule, ";"].joined()
      }
      
      return [partialResult, entry.key, "{", subRules, " !important}\n"].joined()
    }
    
    return [hideRules, styleRules].joined()
  }
}

/// An object that wraps around an `AdblockEngine` and caches some results
public class CachedAdBlockEngine {
  /// We cache the models so that they load faster when we need to poll information about the frame
  private var cachedCosmeticFilterModels = FifoDict<URL, CosmeticFilterModel?>()
  private var cachedShouldBlockResult = FifoDict<String, Bool>()
  /// We cache the user scripts so that they load faster on refreshes and back and forth
  private var cachedFrameScriptTypes = FifoDict<URL, Set<UserScriptType>>()
  
  let engine: AdblockEngine
  let source: AdBlockEngineManager.Source
  let serialQueue: DispatchQueue
  
  init(engine: AdblockEngine, source: AdBlockEngineManager.Source, serialQueue: DispatchQueue) {
    self.engine = engine
    self.source = source
    self.serialQueue = serialQueue
  }
  
  /// Checks the general and regional engines to see if the request should be blocked.
  func shouldBlock(requestURL: URL, sourceURL: URL, resourceType: AdblockEngine.ResourceType, callback: @escaping (Bool) -> Void) {
    serialQueue.async { [weak self] in
      let shouldBlock = self?.shouldBlock(requestURL: requestURL, sourceURL: sourceURL, resourceType: resourceType) == true
      
      DispatchQueue.main.async {
        callback(shouldBlock)
      }
    }
  }
  
  /// Checks the general and regional engines to see if the request should be blocked.
  func shouldBlock(requestURL: URL, sourceURL: URL, resourceType: AdblockEngine.ResourceType) async -> Bool {
    return await withUnsafeContinuation { continuation in
      serialQueue.async { [weak self] in
        let shouldBlock = self?.shouldBlock(requestURL: requestURL, sourceURL: sourceURL, resourceType: resourceType) == true
        continuation.resume(returning: shouldBlock)
      }
    }
  }
  
  /// Returns all the models for this frame URL
  /// The results are cached per url, so you may call this method as many times for the same url without any performance implications.
  func cosmeticFilterModel(forFrameURL frameURL: URL) async throws -> CosmeticFilterModel? {
    return try await withUnsafeThrowingContinuation { continuation in
      serialQueue.async {
        if let model = self.cachedCosmeticFilterModels.getElement(frameURL) {
          continuation.resume(returning: model)
          return
        }
        
        do {
          let model = try self.engine.cosmeticFilterModel(forFrameURL: frameURL)
          self.cachedCosmeticFilterModels.addElement(model, forKey: frameURL)
          continuation.resume(returning: model)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Return the selectors that need to be hidden given the frameURL, ids and classes
  func selectorsForCosmeticRules(frameURL: URL, ids: [String], classes: [String]) async throws -> [String] {
    let model = try await cosmeticFilterModel(forFrameURL: frameURL)
    
    return try await withUnsafeThrowingContinuation { continuation in
      serialQueue.async {
        let selectorsJSON = self.engine.stylesheetForCosmeticRulesIncluding(
          classes: classes,
          ids: ids,
          exceptions: model?.exceptions ?? []
        )
        
        guard let data = selectorsJSON.data(using: .utf8) else {
          continuation.resume(returning: [])
          return
        }
        
        let decoder = JSONDecoder()
        
        do {
          let selectors = try decoder.decode([String].self, from: data)
          continuation.resume(returning: selectors)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Checks the general and regional engines to see if the request should be blocked
  private func shouldBlock(requestURL: URL, sourceURL: URL, resourceType: AdblockEngine.ResourceType) -> Bool {
    let key = [requestURL.absoluteString, sourceURL.absoluteString, resourceType.rawValue].joined(separator: "_")
    
    if let cachedResult = cachedShouldBlockResult.getElement(key) {
        return cachedResult
    }
    
    let shouldBlock = engine.shouldBlock(
      requestURL: requestURL,
      sourceURL: sourceURL,
      resourceType: resourceType
    )
    
    cachedShouldBlockResult.addElement(shouldBlock, forKey: key)
    return shouldBlock
  }
  
  /// This returns all the user script types for the given frame
  func makeEngineScriptTypes(frameURL: URL, isMainFrame: Bool, domain: Domain, index: Int) async throws -> Set<UserScriptType> {
    if let userScriptTypes = cachedFrameScriptTypes.getElement(frameURL) {
      return userScriptTypes
    }
    
    // Add the selectors poller scripts for this frame
    var userScriptTypes: Set<UserScriptType> = []
    
    if let source = try await cosmeticFilterModel(forFrameURL: frameURL)?.injectedScript, !source.isEmpty {
      let configuration = UserScriptType.EngineScriptConfiguration(
        frameURL: frameURL, isMainFrame: isMainFrame, source: source, order: index,
        isDeAMPEnabled: Preferences.Shields.autoRedirectAMPPages.value
      )
      
      userScriptTypes.insert(.engineScript(configuration))
    }
      
    cachedFrameScriptTypes.addElement(userScriptTypes, forKey: frameURL)
    return userScriptTypes
  }
  
  /// Clear the caches.
  func clearCaches() {
    cachedCosmeticFilterModels = FifoDict()
    cachedShouldBlockResult = FifoDict()
    cachedFrameScriptTypes = FifoDict()
  }
  
  /// Returns a boolean indicating if the engine is enabled for the given domain.
  ///
  /// This is determined by checking the source of the engine and checking the appropriate shields.
  @MainActor func isEnabled(for domain: Domain) -> Bool {
    switch source {
    case .adBlock:
      // This engine source type is enabled only if shields are enabled
      // for the given domain
      return domain.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true)
    case .filterList, .cosmeticFilters:
      // Filter lists are controlled via the filter lists UI
      // whereas the cosmetic filters are always applied
      return true
    }
  }
  
  /// Create an engine from the given resources
  static func createEngine(from resources: [AdBlockEngineManager.ResourceWithVersion], source: AdBlockEngineManager.Source) async -> (engine: CachedAdBlockEngine, compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
    return await withUnsafeContinuation { continuation in
      let serialQueue = DispatchQueue(label: "com.brave.WrappedAdBlockEngine.\(UUID().uuidString)")
      
      serialQueue.async {
        let results = AdblockEngine.createEngine(from: resources)
        let cachedEngine = CachedAdBlockEngine(engine: results.engine, source: source, serialQueue: serialQueue)
        continuation.resume(returning: (cachedEngine, results.compileResults))
      }
    }
  }
}

public class AdBlockStats {
  public static let shared = AdBlockStats()

  // Adblock engine for general adblock lists.
  private var cachedEngines: [CachedAdBlockEngine]

  init() {
    cachedEngines = []
  }
  
  func clearCaches(clearEngineCaches: Bool = true) {
    guard clearEngineCaches else { return }
    cachedEngines.forEach({ $0.clearCaches() })
  }
  
  /// Checks the general and regional engines to see if the request should be blocked
  ///
  /// - Warning: This method needs to be synced on `AdBlockStatus.adblockSerialQueue`
  func shouldBlock(requestURL: URL, sourceURL: URL, resourceType: AdblockEngine.ResourceType) async -> Bool {
    return await cachedEngines.asyncConcurrentMap({ cachedEngine in
      return await cachedEngine.shouldBlock(
        requestURL: requestURL,
        sourceURL: sourceURL,
        resourceType: resourceType
      )
    }).contains(where: { $0 })
  }
  
  func set(engines: [CachedAdBlockEngine]) {
    self.cachedEngines = engines
    self.clearCaches(clearEngineCaches: false)
  }
  
  /// This returns all the user script types for the given frame
  func makeEngineScriptTypes(frameURL: URL, isMainFrame: Bool, domain: Domain) async -> Set<UserScriptType> {
    // Add any engine scripts for this frame
    return await cachedEngines.enumerated().asyncConcurrentMap({ (index, cachedEngine) -> Set<UserScriptType> in
      guard await cachedEngine.isEnabled(for: domain) else { return [] }
      
      do {
        return try await cachedEngine.makeEngineScriptTypes(
          frameURL: frameURL, isMainFrame: isMainFrame, domain: domain, index: index
        )
      } catch {
        assertionFailure()
        return []
      }
    }).reduce(Set<UserScriptType>(), { partialResult, scriptTypes in
      return partialResult.union(scriptTypes)
    })
  }
  
  /// Returns all the models for this frame URL
  @MainActor func cachedEngines(for domain: Domain) -> [CachedAdBlockEngine] {
    return cachedEngines.filter({ cachedEngine in
      return cachedEngine.isEnabled(for: domain)
    })
  }
  
  /// Returns all the models for this frame URL
  func cosmeticFilterModels(forFrameURL frameURL: URL, domain: Domain) async -> [CosmeticFilterModel] {
    return await cachedEngines(for: domain).asyncConcurrentCompactMap { cachedEngine in
      do {
        return try await cachedEngine.cosmeticFilterModel(forFrameURL: frameURL)
      } catch {
        assertionFailure()
        return nil
      }
    }
  }
}

private extension AdblockEngine {
  /// Parse a `CosmeticFilterModel` from the engine
  func cosmeticFilterModel(forFrameURL frameURL: URL) throws -> CosmeticFilterModel? {
    let rules = cosmeticResourcesForURL(frameURL.absoluteString)
    guard let data = rules.data(using: .utf8) else { return nil }
    return try JSONDecoder().decode(CosmeticFilterModel.self, from: data)
  }
}

extension AdblockEngine {
  public enum CompileError: Error {
    case invalidResourceJSON
    case fileNotFound
    case couldNotDeserializeDATFile
  }
  
  static func createEngines(
    from resources: [AdBlockEngineManager.ResourceWithVersion]
  ) async -> (engines: [CachedAdBlockEngine], compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
    let groupedResources = group(resources: resources)
    
    let enginesWithCompileResults = await groupedResources.asyncConcurrentMap { source, resources -> (engine: CachedAdBlockEngine, compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) in
      let results = await CachedAdBlockEngine.createEngine(from: resources, source: source)
      return (results.engine, results.compileResults)
    }
    
    var allCompileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>] = [:]
    let engines = enginesWithCompileResults.map({ $0.engine })
    
    for result in enginesWithCompileResults {
      for compileResult in result.1 {
        allCompileResults[compileResult.key] = compileResult.value
      }
    }
    
    return (engines, allCompileResults)
  }
  
  /// Create an engine from the given resources.
  ///
  /// - Warning: You should only have at max dat file in this list. Each dat file can only represent a single engine
  public static func createEngine(from resources: [AdBlockEngineManager.ResourceWithVersion]) -> (engine: AdblockEngine, compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
    let combinedRuleLists = Self.combineAllRuleLists(from: resources)
    // Create an engine with the combined rule lists
    let engine = AdblockEngine(rules: combinedRuleLists)
    // Compile remaining resources
    let compileResults = engine.compile(resources: resources)
    // Return the compiled data
    return (engine, compileResults)
  }
  
  /// Combine all resources of type rule lists to one single string
  private static func combineAllRuleLists(from resourcesWithVersion: [AdBlockEngineManager.ResourceWithVersion]) -> String {
    // Combine all rule lists that need to be injected during initialization
    let allResults = resourcesWithVersion.compactMap { resourceWithVersion -> String? in
      switch resourceWithVersion.resource.type {
      case .ruleList:
        guard let data = FileManager.default.contents(atPath: resourceWithVersion.fileURL.path) else {
          return nil
        }
        
        return String(data: data, encoding: .utf8)
      case .dat, .jsonResources:
        return nil
      }
    }
    
    let combinedRules = allResults.joined(separator: "\n")
    return combinedRules
  }
  
  static func group(
    resources: [AdBlockEngineManager.ResourceWithVersion]
  ) -> [AdBlockEngineManager.Source: [AdBlockEngineManager.ResourceWithVersion]] {
    var groups: [AdBlockEngineManager.Source: [AdBlockEngineManager.ResourceWithVersion]] = [:]
    
    for resourceWithVersion in resources {
      var group = groups[resourceWithVersion.resource.source] ?? []
      group.append(resourceWithVersion)
      groups[resourceWithVersion.resource.source] = group
    }
    
    return groups
  }
  
  /// Compile all the resources on a detached task
  func compile(resources: [AdBlockEngineManager.ResourceWithVersion]) -> [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>] {
    var compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>] = [:]
    
    for resourceWithVersion in resources {
      do {
        try self.compile(resource: resourceWithVersion)
        compileResults[resourceWithVersion] = .success(Void())
      } catch {
        compileResults[resourceWithVersion] = .failure(error)
        //log.error("\(error.localizedDescription)")
      }
    }
    
    return compileResults
  }
  
  /// Compile the given resource into the given engine
  func compile(resource: AdBlockEngineManager.ResourceWithVersion) throws {
    switch resource.resource.type {
    case .dat:
      guard let data = FileManager.default.contents(atPath: resource.fileURL.path) else {
        return
      }
      
      if !deserialize(data: data) {
        throw CompileError.couldNotDeserializeDATFile
      }
    case .jsonResources:
      guard let data = FileManager.default.contents(atPath: resource.fileURL.path) else {
        throw CompileError.fileNotFound
      }
      
      guard let json = try self.validateJSON(data) else {
        return
      }
      
      addResources(json)
    case .ruleList:
      // This is added during engine initialization
      break
    }
  }
  
  /// Return a `JSON` string if this data is valid
  private func validateJSON(_ data: Data) throws -> String? {
    let value = try JSONSerialization.jsonObject(with: data, options: [])
    
    if let value = value as? NSArray {
      guard value.count > 0 else { return nil }
      return String(data: data, encoding: .utf8)
    }
    
    guard let value = value as? NSDictionary else {
      throw CompileError.invalidResourceJSON
    }
      
    guard value.count > 0 else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
