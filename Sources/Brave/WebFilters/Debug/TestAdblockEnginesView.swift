//
//  SwiftUIView.swift
//  
//
//  Created by Jacob on 2023-10-04.
//

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
  
  @State private var testStarted = false
  @State private var testRunning = false
  @State private var result: Result<ContinuousClock.Instant.Duration, Error>?
  @State private var compiledCount = 0
  
  var body: some View {
    List {
      Section {
        TextField("Number of engines", value: $numberOfEngines, format: .number)
        Picker("Process", selection: $compileType) {
          ForEach(CompileType.allCases, id: \.rawValue) { type in
            Text(type.title).tag(type)
          }
        }
        Button("Start test", systemImage: "play", action: startTest)
          .disabled(testRunning)
      } header: {
        Text("Compile test engines")
      } footer: {
        Text("This will compile N engines from a filter list with ~150k entries. You can specify the number of engines and what kind of process to use (parallel or series)")
      }
      
      if testStarted {
        Section {
          switch result {
          case .success(let result):
            Text("Success after \(result.formatted())").foregroundStyle(.green)
          case .failure(let error):
            Text(String(describing: error)).foregroundStyle(.red)
          case nil:
            ProgressView("Compiling engines", value: Double(compiledCount), total: Double(numberOfEngines))
              .progressViewStyle(.linear)
          }
        } header: {
          Text("Results")
        }
      }
    }.navigationTitle("Test engines")
  }
  
  private func startTest() {
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
              try await compileEngine(at: index)
              
              await MainActor.run {
                self.compiledCount += 1
              }
            }
          case .parallel:
            try await (0..<numberOfEngines).asyncConcurrentForEach { index in
              try await compileEngine(at: index)
              
              await MainActor.run {
                self.compiledCount += 1
              }
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
  
  private func compileEngine(at index: Int) async throws {
    let uuid = "test-engine-\(index)"
    let sampleFilterListURL = Bundle.module.url(forResource: "list", withExtension: "txt")!
    let resourcesURL = Bundle.module.url(forResource: "resources", withExtension: "json")!
    
    let resourcesInfo = CachedAdBlockEngine.ResourcesInfo(
      localFileURL: resourcesURL, version: "bundled"
    )
    
    let filterListInfo = CachedAdBlockEngine.FilterListInfo(
      source: .filterList(componentId: uuid),
      localFileURL: sampleFilterListURL,
      version: "bundled", fileType: .text
    )
    
    _ = try await CachedAdBlockEngine.compile(
      filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: false
    )
  }
}

#if swift(>=5.9)
@available(iOS 17.0, *)
#Preview {
  TestAdblockEnginesView()
}
#endif
