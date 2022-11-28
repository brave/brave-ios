// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BraveShared
import Shared

private let log = ContentBlockerManager.log

/// This class is responsible for loading the engine when new resources arrive.
/// It ensures that we always have a fresh new engine as new data is downloaded
public actor AdBlockEngineManager: Sendable {
  /// The source of a resource. In some cases we need to remove all resources for a given source.
  enum Source: Hashable {
    case adBlock
    case cosmeticFilters
    case filterList(uuid: String)
    
    /// The order of this source relative to other sources.
    ///
    /// Used to compute an overall order of the resources
    fileprivate var relativeOrder: Int {
      switch self {
      case .adBlock: return 0
      case .cosmeticFilters: return 3
      case .filterList: return 100
      }
    }
  }
  
  /// The type of resource so we know how to compile it and add it into the engine
  public enum ResourceType: CaseIterable {
    case dat
    case jsonResources
    case ruleList
    
    /// The order of this resource type relative to other resource types.
    ///
    /// Used to compute an overall order of the resources
    var relativeOrder: Int {
      switch self {
      case .ruleList: return 0
      case .dat: return 1
      case .jsonResources: return 2
      }
    }
  }
  
  /// An object representing a resource that can be compiled into our engine.
  struct Resource: Hashable {
    /// The type of resource so we know how to compile it and add it into the engine
    let type: ResourceType
    /// The source of this resource so we can remove all resources for this source at a later time
    let source: Source
    
    fileprivate var relativeOrder: Int {
      return type.relativeOrder + source.relativeOrder
    }
  }
  
  /// An aboject containing the resource and version.
  ///
  /// Stored in this way so we can replace resources with an older version
  public struct ResourceWithVersion: Hashable {
    /// The resource that we need to compile
    let resource: Resource
    /// The local file url for the given resource
    let fileURL: URL
    /// The version of this resource
    let version: String?
    /// The order of this resource relative to other resources.
    ///
    /// Used to compute an overall order of the resources
    let relativeOrder: Int
    
    /// The overal order of this resource taking account the order of the resource type, resource source and relative order
    fileprivate var order: Int {
      return resource.relativeOrder + relativeOrder
    }
  }
  
  public static var shared = AdBlockEngineManager()
  
  /// The stats to store the engines on
  private let stats: AdBlockStats
  /// The repeating build task
  private var endlessBuildTask: Task<(), Error>?
  /// The current set resources which will be compiled and loaded
  var enabledResources: Set<ResourceWithVersion>
  /// The compile results
  var compileResults: [ResourceWithVersion: Result<Void, Error>]
  /// The current compile task. Ensures we don't try to compile while we're already compiling
  var compileTask: Task<Void, Error>?
  /// Cached engines
  var cachedEngines: [Source: AdblockEngine]
  
  /// The amount of time to wait before checking if new entries came in
  private static let buildSleepTime: TimeInterval = {
    #if DEBUG
    return 10
    #else
    return 1.minutes
    #endif
  }()
  
  /// Tells us if all the enabled resources are synced
  /// (i.e. we didn't compile too little or too many resources and don't need to recompile them)
  private var isSynced: Bool {
    return enabledResources.allSatisfy({ compileResults[$0] != nil }) && compileResults.allSatisfy({ key, _ in
      enabledResources.contains(key)
    })
  }
  
  init(stats: AdBlockStats = AdBlockStats.shared) {
    self.stats = stats
    self.enabledResources = []
    self.compileResults = [:]
    self.cachedEngines = [:]
  }
  
  /// Tells this manager to add this resource next time it compiles this engine
  func add(resource: Resource, fileURL: URL, version: String?, relativeOrder: Int = 0) async {
    let resourceWithVersion = ResourceWithVersion(
      resource: resource,
      fileURL: fileURL,
      version: version,
      relativeOrder: relativeOrder
    )
    
    add(resource: resourceWithVersion)
  }
  
  /// Tells this manager to remove all resources for the given source next time it compiles this engine
  func removeResources(for source: Source, resourceTypes: Set<ResourceType> = Set(ResourceType.allCases)) async {
    self.enabledResources = self.enabledResources.filter { resourceWithVersion in
      let resource = resourceWithVersion.resource
      guard resource.source == source && resourceTypes.contains(resource.type) else { return true }
      return false
    }
  }
  
  /// Start a timer that will compile resources if they change
  public func startTimer() {
    guard endlessBuildTask == nil else { return }
    
    self.endlessBuildTask = Task.detached(priority: .background) {
      try await withTaskCancellationHandler(operation: {
        while true {
          try await Task.sleep(seconds: Self.buildSleepTime)
          guard await self.compileTask == nil else { continue }
          guard await !self.isSynced else { continue }
          await self.compileResources(priority: .background)
        }
      }, onCancel: {
        Task { @MainActor in
          await self.removeBuildTask()
        }
      })
    }
  }
  
  /// Compile all resources
  public func compileResources(priority: TaskPriority) async {
    compileTask?.cancel()
    set(compileTask: nil)
    
    let resourcesWithVersion = self.enabledResources.sorted(by: {
      $0.order < $1.order
    })
    
    let task = Task.detached(priority: priority) {
      let results = await AdblockEngine.createEnginesOnSerialQueue(from: resourcesWithVersion)
      await self.set(compileResults: results.compileResults)
      
      try await MainActor.run {
        try Task.checkCancellation()
        self.stats.set(engines: results.engines)
      }
      
      #if DEBUG
      await self.debug(resources: resourcesWithVersion)
      #endif
    }
    
    set(compileTask: task)
    
    do {
      try await task.value
    } catch {
      log.error("\(error.localizedDescription)")
    }
    
    set(compileTask: nil)
  }
  
  private func removeBuildTask() {
    endlessBuildTask = nil
  }
  
  /// Tells this manager to add this resource next time it compiles this engine
  private func add(resource: ResourceWithVersion) {
    self.enabledResources = enabledResources.filter({ resourceWithVersion in
      guard resourceWithVersion.resource == resource.resource else { return true }
      // Remove these compile results so we have to compile again
      compileResults.removeValue(forKey: resourceWithVersion)
      return false
    })
    
    enabledResources.insert(resource)
  }
  
  /// Set the compile results so this manager can compute if its in sync or not
  private func set(compileResults: [ResourceWithVersion: Result<Void, Error>]) {
    self.compileResults = compileResults
  }
  
  /// Set the compile results so this manager can compute if its in sync or not
  private func add(engine: AdblockEngine, for source: Source) {
    self.cachedEngines[source] = engine
  }
  
  /// Set the current compile task to avoid overlaping compilations
  private func set(compileTask: Task<Void, Error>?) {
    self.compileTask = compileTask
  }
}

extension AdblockEngine {
  public enum CompileError: Error {
    case invalidResourceJSON
    case fileNotFound
    case couldNotDeserializeDATFile
  }
  
  static func createEnginesOnSerialQueue(
    from resources: [AdBlockEngineManager.ResourceWithVersion]
  ) async -> (engines: [CachedAdBlockEngine], compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
    return await withUnsafeContinuation { continuation in
      AdBlockStats.adblockSerialQueue.async {
        let results = Self.createEngines(from: resources)
        continuation.resume(returning: results)
      }
    }
  }
  
  static func createEngines(
    from resources: [AdBlockEngineManager.ResourceWithVersion]
  ) -> (engines: [CachedAdBlockEngine], compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
    let groupedResources = group(resources: resources)
    
    let enginesWithCompileResults = groupedResources.map { source, resources -> (engine: CachedAdBlockEngine, compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) in
      let results = AdblockEngine.createEngine(from: resources)
      let cachedEngine = CachedAdBlockEngine(engine: results.engine, source: source)
      return (cachedEngine, results.compileResults)
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
  
  /// Create an engine from the given resources
  static func createEngineOnSerialQueue(from resources: [AdBlockEngineManager.ResourceWithVersion]) async -> (engine: AdblockEngine, compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
    return await withUnsafeContinuation { continuation in
      AdBlockStats.adblockSerialQueue.async {
        let results = Self.createEngine(from: resources)
        continuation.resume(returning: results)
      }
    }
  }
  
  /// Create an engine from the given resources
  static func createEngine(from resources: [AdBlockEngineManager.ResourceWithVersion]) -> (engine: AdblockEngine, compileResults: [AdBlockEngineManager.ResourceWithVersion: Result<Void, Error>]) {
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
  
  private static func group(
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
        log.error("\(error.localizedDescription)")
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

#if DEBUG
extension AdBlockEngineManager {
  /// A method that logs info on the given resources
  fileprivate func debug(resources: [ResourceWithVersion]) {
    let resourcesString = resources.sorted(by: { $0.order < $1.order })
      .map { resourceWithVersion -> String in
        let resource = resourceWithVersion.resource
        let type: String
        let sourceString: String
        let resultString: String
        
        switch resource.type {
        case .dat:
          type = "dat"
        case .jsonResources:
          type = "jsonResources"
        case .ruleList:
          type = "ruleList"
        }
        
        switch resource.source {
        case .filterList(let uuid):
          sourceString = "filterList(\(uuid))"
        case .adBlock:
          sourceString = "adBlock"
        case .cosmeticFilters:
          sourceString = "cosmeticFilters"
        }
        
        switch compileResults[resourceWithVersion] {
        case .failure(let error):
          resultString = error.localizedDescription
        case .success:
          resultString = "success"
        case .none:
          resultString = "not compiled"
        }
        
        let sourceDebugString = [
          "order: \(resourceWithVersion.order)",
          "fileName: \(resourceWithVersion.fileURL.lastPathComponent)",
          "source: \(sourceString)",
          "version: \(resourceWithVersion.version ?? "nil")",
          "type: \(type)",
          "result: \(resultString)",
        ].joined(separator: ", ")
        
        return ["{", sourceDebugString, "}"].joined()
      }.joined(separator: ", ")

    log.debug("Loaded \(self.enabledResources.count, privacy: .public) (total) engine resources: \(resourcesString, privacy: .public)")
  }
}
#endif
