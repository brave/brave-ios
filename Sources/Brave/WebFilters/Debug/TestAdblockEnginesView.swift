// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@available(iOS 16.0, *)
struct TestAdblockEnginesView: View {
  enum CompileType: String, Hashable, CaseIterable {
    case series
    case parallel
    
    var title: String {
      switch self {
      case .series: return "Series"
      case .parallel: return "Parallel"
      }
    }
  }
  
  enum Status {
    case running
    case finished(Result<ContinuousClock.Instant.Duration, Error>)
  }
  
  @AppStorage("TestAdblockEnginesView.numberOfEngines")
  private var numberOfEngines = 100
  @AppStorage("TestAdblockEnginesView.compileType")
  private var compileType: CompileType = .series
  @AppStorage("TestAdblockEnginesView.copyToDisk")
  private var copyToDisk = true
  @AppStorage("TestAdblockEnginesView.clearEnginesAtAmount")
  private var clearEnginesAtAmount = 10
  @AppStorage("TestAdblockEnginesView.removeSharedEngineAfterCompilation")
  private var removeSharedEngineAfterCompilation = true
  @AppStorage("TestAdblockEnginesView.useSharedInstanceForSharedEngines")
  private var useSharedInstanceForSharedEngines = false
  @AppStorage("TestAdblockEnginesView.numberOfSharedRuns")
  private var numberOfSharedRuns = 1
  @AppStorage("TestAdblockEnginesView.throttle")
  private var throttle = 100
  
  @State private var selectedFilterList: AdBlockStats.LazyFilterListInfo?
  @State private var adblockStats = AdBlockStats()
  @State private var compiledCount = 0
  @State private var compileTask: Task<(), Never>?
  @State private var compileStatus: Status?
  
  @State private var compiledSharedEngineCount = 0
  @State private var numberOfSharedEngines = 0
  @State private var availableFilterLists: [AdBlockStats.LazyFilterListInfo] = []
  @State private var compileSharedStatus: Status?
  @State private var compileSharedTask: Task<(), Never>?
  
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading) {
          Text("Number of engines")
          TextField("Number of engines", value: $numberOfEngines, format: .number, prompt: Text("Enter a number of 1+"))
        }
        VStack(alignment: .leading) {
          Text("Clear engines when reaching amount")
          TextField("Clear engines when reaching amount", value: $clearEnginesAtAmount, format: .number, prompt: Text("Enter a number of 1+"))
        }
        
        Toggle("Copy to disk", isOn: $copyToDisk)
        Picker("Process", selection: $compileType) {
          ForEach(CompileType.allCases, id: \.rawValue) { type in
            Text(type.title).tag(type)
          }
        }
        
        Picker("Filter list", selection: $selectedFilterList) {
          Text("Bundled").tag(nil as AdBlockStats.LazyFilterListInfo?)
          ForEach(availableFilterLists, id: \.filterListInfo.source) { lazyInfo in
            Text(lazyInfo.filterListInfo.source.debugDescription)
              .tag(lazyInfo as AdBlockStats.LazyFilterListInfo?)
          }
        }
        
        if compileTask == nil {
          Button(action: startTest) {
            Label("Start test", systemImage: "play")
          }
        } else {
          Button {
            compileTask?.cancel()
            compileTask = nil
          } label: {
            Label("Stop", systemImage: "stop")
          }
        }
        
        if let status = compileStatus {
          makeRow(
            for: status,
            compiled: compiledCount,
            total: numberOfEngines
          )
        }
      } header: {
        Text("Compile test engines")
      } footer: {
        Text("This will compile N engines from a filter list with ~150k entries. You can specify the number of engines and what kind of process to use (parallel or series)")
      }
      
      Section {
        LabeledContent("Number of shared engines", value: "\(numberOfSharedEngines)")
        LabeledContent("Number of avaialable engines", value: "\(availableFilterLists.count)")
        VStack(alignment: .leading) {
          Text("Number of runs")
          TextField("Number of runs", value: $numberOfSharedRuns, format: .number, prompt: Text("Enter a number of 1+"))
        }
        VStack(alignment: .leading) {
          Text("Throttle (ms)")
          TextField("Throttle", value: $throttle, format: .number, prompt: Text("Enter a number of 0+"))
        }
        
        Toggle("Remove engine after compilation", isOn: $removeSharedEngineAfterCompilation)
        Toggle("Use shared AdBlockStats", isOn: $useSharedInstanceForSharedEngines)
        
        Button {
          Task {
            await AdBlockStats.shared.removeAllEngines()
            self.numberOfSharedEngines = await AdBlockStats.shared.cachedEngines.count
            self.availableFilterLists = await AdBlockStats.shared.enabledSources.asyncCompactMap { source in
              return await AdBlockStats.shared.availableFilterLists[source]
            }
          }
        } label: {
          Label("Clear all engines", systemImage: "trash")
        }
        
        if compileSharedTask == nil {
          let title = numberOfSharedRuns > 1 ? "Compile available engines x\(numberOfSharedRuns)" : "Compile available engines"
          Button(action: compileAvailableEngines) {
            Label(title, systemImage: "play")
          }
        } else {
          Button {
            compileSharedTask?.cancel()
            compileSharedTask = nil
          } label: {
            Label("Stop", systemImage: "stop")
          }
        }
        
        if let status = compileSharedStatus {
          makeRow(
            for: status,
            compiled: compiledSharedEngineCount,
            total: availableFilterLists.count * numberOfSharedRuns
          )
        }
      } header: {
        Text("Test shared AdBlockStats")
      } footer: {
        Text("This tool allows us to perform some tests on the shared instance of AdblockStats")
      }
    }
    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
    .listRowBackground(Color(.secondaryBraveGroupedBackground))
    .navigationTitle("Test engines")
    .onAppear {
      Task {
        self.numberOfSharedEngines = await AdBlockStats.shared.cachedEngines.count
        self.availableFilterLists = await AdBlockStats.shared.enabledSources.asyncCompactMap { source in
          return await AdBlockStats.shared.availableFilterLists[source]
        }
      }
    }
  }
  
  @ViewBuilder private func makeRow(for status: Status, compiled: Int, total: Int) -> some View {
    switch status {
    case .running:
      ProgressView(
        value: Double(compiled), total: Double(total),
        label: {
          HStack {
            Text("Progress")
            Spacer()
            Text("\(compiled) of \(total)")
              .foregroundStyle(.secondary)
              .font(.caption)
          }
        }
      ).progressViewStyle(.linear)
    case .finished(let result):
      switch result {
      case .success(let success):
        Text("Compiled \(compiled)/\(total) engines in \(success.formatted())").foregroundStyle(.green)
      case .failure(let failure):
        Text(String(describing: failure)).foregroundStyle(.red)
      }
    }
  }
  
  private func compileAvailableEngines() {
    compileSharedTask?.cancel()
    compileSharedStatus = .running
    compiledSharedEngineCount = 0
    
    compileSharedTask = Task {
      var adblockStats = self.adblockStats
      
      if useSharedInstanceForSharedEngines {
        adblockStats = AdBlockStats.shared
      }
      
      guard let resourcesInfo = await AdBlockStats.shared.resourcesInfo else {
        return
      }
      
      do {
        let clock = ContinuousClock()
        let throttle = self.throttle
        
        let result = try await clock.measure {
          do {
            for _ in 0..<numberOfSharedRuns {
              await adblockStats.removeAllEngines()
              
              for info in availableFilterLists {
                try Task.checkCancellation()
                await adblockStats.compile(
                  filterListInfo: info.filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: info.isAlwaysAggressive
                )
                numberOfSharedEngines = await adblockStats.cachedEngines.count
                self.compiledSharedEngineCount += 1
                
                if removeSharedEngineAfterCompilation {
                  await adblockStats.removeEngine(for: info.filterListInfo.source)
                }
                
                try await Task.sleep(for: .milliseconds(throttle))
              }
            }
          } catch is CancellationError {
            return
          }
        }
          
        compileSharedStatus = .finished(.success(result))
      } catch {
        compileSharedStatus = .finished(.failure(error))
      }
      
      compileSharedTask = nil
    }
  }
  
  private func startTest() {
    compileTask?.cancel()
    adblockStats = AdBlockStats()
    compiledCount = 0
    compileStatus = .running
    let sampleFilterListURL = Bundle.module.url(forResource: "list", withExtension: "txt")!
    let sampleResourcesURL = Bundle.module.url(forResource: "resources", withExtension: "json")!
    
    compileTask = Task {
      do {
        var filterListURL = sampleFilterListURL
        var resourcesURL = sampleResourcesURL
        var fileType: CachedAdBlockEngine.FileType = .text
        
        if let filterListInfo = selectedFilterList?.filterListInfo {
          filterListURL = filterListInfo.localFileURL
          fileType = filterListInfo.fileType
        }
        
        if copyToDisk, let cachedDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
          let copiedFilterListURL = cachedDirectory.appendingPathComponent("list.txt", conformingTo: .text)
          let copiedResourcesURL = cachedDirectory.appendingPathComponent("resources.json", conformingTo: .json)
          
          if !FileManager.default.fileExists(atPath: copiedFilterListURL.path) {
            try FileManager.default.copyItem(at: sampleFilterListURL, to: copiedFilterListURL)
          }
          
          if !FileManager.default.fileExists(atPath: copiedResourcesURL.path) {
            try FileManager.default.copyItem(at: sampleResourcesURL, to: copiedResourcesURL)
          }
          
          filterListURL = copiedFilterListURL
          resourcesURL = copiedResourcesURL
        }
        
        let clock = ContinuousClock()
        let result = try await clock.measure {
          do {
            switch compileType {
            case .series:
              try await (0..<numberOfEngines).asyncForEach { index in
                try Task.checkCancellation()
                try await compileEngine(
                  at: index, compileType: compileType, 
                  resourcesURL: resourcesURL, filterListURL: filterListURL, fileType: fileType
                )
                self.compiledCount += 1
              }
            case .parallel:
              try await (0..<numberOfEngines).asyncConcurrentForEach { index in
                try Task.checkCancellation()
                try await compileEngine(
                  at: index, compileType: compileType,
                  resourcesURL: resourcesURL, filterListURL: filterListURL, fileType: fileType
                )
                self.compiledCount += 1
              }
            }
          } catch is CancellationError {
            return
          }
        }
        self.compileStatus = .finished(.success(result))
      } catch {
        self.compileStatus = .finished(.failure(error))
      }
      
      compileTask = nil
    }
  }
  
  private func compileEngine(at index: Int, compileType: CompileType, resourcesURL: URL, filterListURL: URL, fileType: CachedAdBlockEngine.FileType) async throws {
    let uuid = "test-engine-\(index)"
    
    let resourcesInfo = CachedAdBlockEngine.ResourcesInfo(
      localFileURL: resourcesURL, version: "1.0"
    )
    
    let filterListInfo = CachedAdBlockEngine.FilterListInfo(
      source: .filterList(componentId: uuid),
      localFileURL: filterListURL,
      version: "bundled", fileType: fileType
    )
    
    switch compileType {
    case .parallel:
      try await adblockStats.compileAsync(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: false
      )
      
      if clearEnginesAtAmount > 0, await adblockStats.cachedEngines.count >= clearEnginesAtAmount {
        await adblockStats.removeAllEngines()
      }
    case .series:
      await adblockStats.compile(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: false
      )
      
      if clearEnginesAtAmount > 0, await adblockStats.cachedEngines.count >= clearEnginesAtAmount {
        await adblockStats.removeAllEngines()
      }
    }
  }
}

#if swift(>=5.9)
@available(iOS 17.0, *)
#Preview {
  TestAdblockEnginesView()
}
#endif
