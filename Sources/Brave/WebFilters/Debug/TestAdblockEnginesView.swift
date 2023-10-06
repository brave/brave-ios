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
  
  @AppStorage("TestAdblockEnginesView.numberOfEngines")
  private var numberOfEngines = 100
  @AppStorage("TestAdblockEnginesView.compileType")
  private var compileType: CompileType = .series
  @AppStorage("TestAdblockEnginesView.removeEngines")
  private var removeEngineAfterCompilation = true
  @AppStorage("TestAdblockEnginesView.numberOfSharedRuns")
  private var numberOfSharedRuns = 1
  @AppStorage("TestAdblockEnginesView.sharedCompileDelay")
  private var sharedCompileDelay = 100
  
  @State private var adblockStats = AdBlockStats()
  @State private var testStarted = false
  @State private var testRunning = false
  @State private var result: Result<ContinuousClock.Instant.Duration, Error>?
  @State private var compiledCount = 0
  
  @State private var compiledSharedEngineCount = 0
  @State private var numberOfSharedEngines = 0
  @State private var numberAvailableSharedEngines = 0
  @State private var compileSharedEnginesStarted = false
  @State private var compileSharedEnginesRunning = false
  @State private var compileSharedEnginesResult: Result<ContinuousClock.Instant.Duration, Error>?
  
  var body: some View {
    List {
      Section {
        TextField("Number of engines", value: $numberOfEngines, format: .number)
        Toggle("Remove engine after compilation", isOn: $removeEngineAfterCompilation)
        Picker("Process", selection: $compileType) {
          ForEach(CompileType.allCases, id: \.rawValue) { type in
            Text(type.title).tag(type)
          }
        }
        Button("Start test", systemImage: "play", action: startTest)
          .disabled(testRunning)
        
        if testStarted {
          switch result {
          case .success(let result):
            Text("Compiles \(compiledCount) engines in \(result.formatted())").foregroundStyle(.green)
          case .failure(let error):
            Text(String(describing: error)).foregroundStyle(.red)
          case nil:
            ProgressView(
              value: Double(compiledCount), total: Double(numberOfEngines),
              label: {
                HStack {
                  Text("Progress")
                  Spacer()
                  Text("\(compiledCount) of \(numberOfEngines)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
              }
            ).progressViewStyle(.linear)
          }
        }
      } header: {
        Text("Compile test engines")
      } footer: {
        Text("This will compile N engines from a filter list with ~150k entries. You can specify the number of engines and what kind of process to use (parallel or series)")
      }
      
      Section {
        LabeledContent("Number of shared engines", value: "\(numberOfSharedEngines)")
        LabeledContent("Number of avaialable engines", value: "\(numberAvailableSharedEngines)")
        TextField("Number of runs", value: $numberOfSharedRuns, format: .number)
        TextField("Delay per compile (ms)", value: $sharedCompileDelay, format: .number)
        
        Button("Clear all engines", systemImage: "trash", action: {
          Task {
            await AdBlockStats.shared.removeAllEngines()
            self.numberOfSharedEngines = await AdBlockStats.shared.numberOfEngines
            self.numberAvailableSharedEngines = await AdBlockStats.shared.numberOfAvailableFilterLists
          }
        })
        
        let title = numberOfSharedRuns > 1 ? "Compile available engines x\(numberOfSharedRuns)" : "Compile available engines"
        Button(title, systemImage: "play", action: compileAvailableEngines)
          .disabled(compileSharedEnginesRunning)
        
        if compileSharedEnginesStarted {
          switch compileSharedEnginesResult {
          case .success(let result):
            Text("Compiles \(compiledSharedEngineCount) engines in \(result.formatted())").foregroundStyle(.green)
          case .failure(let error):
            Text(String(describing: error)).foregroundStyle(.red)
          case nil:
            ProgressView(
              value: Double(compiledSharedEngineCount), total: Double(numberAvailableSharedEngines * numberOfSharedRuns),
              label: {
                HStack {
                  Text("Progress")
                  Spacer()
                  Text("\(compiledSharedEngineCount) of \(numberAvailableSharedEngines * numberOfSharedRuns)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
              }
            ).progressViewStyle(.linear)
          }
        }
      } header: {
        Text("Test AdBlockStats.shared")
      } footer: {
        Text("This tool allows us to perform some tests on the shared instance of AdblockStats")
      }
    }
    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
    .listRowBackground(Color(.secondaryBraveGroupedBackground))
    .navigationTitle("Test engines")
    .onAppear {
      Task {
        self.numberOfSharedEngines = await AdBlockStats.shared.numberOfEngines
        self.numberAvailableSharedEngines = await AdBlockStats.shared.numberOfAvailableFilterLists
      }
    }
  }
  
  private func compileAvailableEngines() {
    compileSharedEnginesRunning = true
    compileSharedEnginesStarted = true
    compileSharedEnginesResult = nil
    compiledSharedEngineCount = 0
    
    Task {
      let infos = await AdBlockStats.shared.availableFilterLists
      let delay = sharedCompileDelay
      do {
        let clock = ContinuousClock()
        let result = try await clock.measure {
          for run in 0..<numberOfSharedRuns {
            await AdBlockStats.shared.removeAllEngines()
            
            for (index, info) in infos.enumerated() {
              ContentBlockerManager.log.debug("Compiling \(info.value.filterListInfo.debugDescription)")
              try await AdBlockStats.shared.compile(
                filterListInfo: info.value.filterListInfo, isAlwaysAggressive: info.value.isAlwaysAggressive
              )
              numberOfSharedEngines = await AdBlockStats.shared.numberOfEngines
              self.compiledSharedEngineCount = (run * infos.count) + (index + 1)
              try await Task.sleep(for: .milliseconds(delay))
            }
          }
        }
          
        compileSharedEnginesResult = .success(result)
      } catch {
        compileSharedEnginesResult = .failure(error)
      }
      
      compileSharedEnginesRunning = false
    }
  }
  
  private func startTest() {
    adblockStats = AdBlockStats()
    testStarted = true
    compiledCount = 0
    result = nil
    testRunning = true
    
    Task {
      do {
        let clock = ContinuousClock()
        let result = try await clock.measure {
          switch compileType {
          case .series:
            try await (0..<numberOfEngines).asyncForEach { index in
              try await compileEngine(at: index, compileType: compileType)
              self.compiledCount = index + 1
            }
          case .parallel:
            try await (0..<numberOfEngines).asyncConcurrentForEach { index in
              try await compileEngine(at: index, compileType: compileType)
              self.compiledCount += 1
            }
          }
          
        }
        self.result = .success(result)
      } catch {
        self.result = .failure(error)
      }
      
      testRunning = false
    }
  }
  
  private func compileEngine(at index: Int, compileType: CompileType) async throws {
    let uuid = "test-engine-\(index)"
    let sampleFilterListURL = Bundle.module.url(forResource: "list", withExtension: "txt")!
    let resourcesURL = Bundle.module.url(forResource: "resources", withExtension: "json")!
    
    let resourcesInfo = CachedAdBlockEngine.ResourcesInfo(
      localFileURL: resourcesURL, version: "1.0"
    )
    
    let filterListInfo = CachedAdBlockEngine.FilterListInfo(
      source: .filterList(componentId: uuid),
      localFileURL: sampleFilterListURL,
      version: "bundled", fileType: .text
    )
    
    switch compileType {
    case .parallel:
      try await adblockStats.compileAsync(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: false
      )
      
      if removeEngineAfterCompilation {
        Task.detached {
          await adblockStats.removeEngine(for: .filterList(componentId: uuid))
        }
      }
    case .series:
      try await adblockStats.compile(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: false
      )
      
      if removeEngineAfterCompilation {
        await adblockStats.removeEngine(for: .filterList(componentId: uuid))
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
