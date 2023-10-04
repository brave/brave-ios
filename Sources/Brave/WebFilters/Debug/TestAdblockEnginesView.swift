// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UniformTypeIdentifiers

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
  
  enum SelectedFilterList: Hashable {
    case sample
    case iterateDownloaded([AvailableFilterList])
    case downloaded(AvailableFilterList)
    
    func compileInfo(index: Int) -> String {
      switch self {
      case .sample:
        return "Compiling sample"
      case .iterateDownloaded(let selections):
        let index = index % selections.count
        let selection = selections[index]
        return "Compiling \(selection.title)"
      case .downloaded(let selection):
        return "Compiling \(selection.title)"
      }
    }
    
    func filterListInfo(index: Int) -> CachedAdBlockEngine.FilterListInfo {
      switch self {
      case .sample:
        return CachedAdBlockEngine.FilterListInfo(
          source: .adBlock, localFileURL: Bundle.module.url(forResource: "list", withExtension: "txt")!,
          version: "sample", fileType: .text
        )
      case .iterateDownloaded(let selections):
        let index = index % selections.count
        return selections[index].lazyInfo.filterListInfo
      case .downloaded(let selection):
        return selection.lazyInfo.filterListInfo
      }
    }
  }
  
  enum SelectedResource: Hashable {
    case sample
    case downloaded(CachedAdBlockEngine.ResourcesInfo)
    
    var resourcesInfo: CachedAdBlockEngine.ResourcesInfo {
      switch self {
      case .sample:
        return CachedAdBlockEngine.ResourcesInfo(
          localFileURL: Bundle.module.url(forResource: "resources", withExtension: "json")!,
          version: "sample"
        )
      case .downloaded(let resourcesInfo):
        return resourcesInfo
      }
    }
  }
  
  struct AvailableFilterList: Hashable {
    let title: String
    let lazyInfo: AdBlockStats.LazyFilterListInfo
  }
  
  enum Status {
    case running
    case finished(Result<String?, Error>)
  }
  
  @AppStorage("TestAdblockEnginesView.numberOfEngines")
  private var numberOfEngines = 100
  @AppStorage("TestAdblockEnginesView.copyLocation")
  private var copyLocation = false
  @AppStorage("TestAdblockEnginesView.compileContentBlockers")
  private var compileContentBlockers = true
  
  @State private var availableFilterLists: [AvailableFilterList] = []
  @State private var availableResources: [CachedAdBlockEngine.ResourcesInfo] = []
  @State private var selectedFilterList: SelectedFilterList = .sample
  @State private var selectedResource: SelectedResource = .sample
  @State private var compiledCount = 0
  @State private var compileTask: Task<(), Never>?
  @State private var compileStatus: Status?
  @State private var compileInfo: String?
  
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading) {
          Text("Number of engines")
          TextField("Number of engines", value: $numberOfEngines, format: .number, prompt: Text("Enter a number of 1+"))
        }
        
        Picker("Filter list", selection: $selectedFilterList) {
          Text("Sample")
            .tag(SelectedFilterList.sample)
          
          if !availableFilterLists.isEmpty {
            Text("Iterate all")
              .tag(SelectedFilterList.iterateDownloaded(availableFilterLists))
          }
          
          ForEach(availableFilterLists, id: \.lazyInfo.filterListInfo.source) { availableFilterList in
            Text(availableFilterList.title)
              .lineLimit(1)
              .truncationMode(.middle)
              .tag(SelectedFilterList.downloaded(availableFilterList))
          }
        }
        
        Picker("Resource", selection: $selectedResource) {
          Text("Sample").tag(SelectedResource.sample)
          
          ForEach(availableResources, id: \.version) { info in
            Text(info.version)
              .tag(SelectedResource.downloaded(info))
          }
        }
        
        Toggle("Copy File", isOn: $copyLocation)
        
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
            total: numberOfEngines,
            message: compileInfo
          )
        }
      } header: {
        Text("Compile test engines")
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      .toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .navigationTitle("Test engines")
    .onAppear {
      loadAvaliableEngines()
    }
  }
  
  @ViewBuilder private func makeRow(for status: Status, compiled: Int, total: Int, message: String?) -> some View {
    switch status {
    case .running:
      VStack(alignment: .leading) {
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
        
        if let message = message {
          Text(message).foregroundStyle(.secondary).font(.caption)
        }
      }
    case .finished(let result):
      switch result {
      case .success(let success):
        if let success = success {
          Text("Compiled \(compiled)/\(total) engines in \(success)").foregroundStyle(.green)
        } else {
          Text("Compiled \(compiled)/\(total) engines").foregroundStyle(.green)
        }
      case .failure(let failure):
        Text(String(describing: failure)).foregroundStyle(.red)
      }
    }
  }
  
  private func startTest() {
    compileTask?.cancel()
    compiledCount = 0
    compileStatus = .running
    self.compileInfo = nil
    let selectedFilterList = self.selectedFilterList
    let selectedResource = self.selectedResource
    let copyFile = self.copyLocation
    
    compileTask = Task {
      do {
        let result = try await measure() {
          let engines = try await (0..<numberOfEngines).asyncCompactMap { index -> CachedAdBlockEngine? in
            do {
              try Task.checkCancellation()
              self.compileInfo = selectedFilterList.compileInfo(index: index)
              
              let lazyInfo = try getFilterListInfo(
                at: index, filterList: selectedFilterList, copyFile: copyFile
              )
              
              let engine = try await Task {
                return try CachedAdBlockEngine.compile(
                  filterListInfo: lazyInfo.filterListInfo,
                  resourcesInfo: selectedResource.resourcesInfo,
                  isAlwaysAggressive: lazyInfo.isAlwaysAggressive
                )
              }.value
              
              self.compiledCount += 1
              return engine
            } catch is CancellationError {
              return nil
            }
          }
        }
        self.compileStatus = .finished(.success(result))
      } catch {
        self.compileStatus = .finished(.failure(error))
      }
      
      compileInfo = nil
      compileTask = nil
    }
  }
  
  private func measure(callback: () async throws -> Void) async rethrows -> String? {
    if #available(iOS 16.0, *) {
      let clock = ContinuousClock()
      let result = try await clock.measure {
        try await callback()
      }
      
      return result.formatted()
    } else {
      try await callback()
      return nil
    }
  }
  
  private func getFilterListInfo(
    at index: Int, filterList: SelectedFilterList,
    copyFile: Bool
  ) throws -> AdBlockStats.LazyFilterListInfo {
    var filterListInfo = filterList.filterListInfo(index: index)
    
    if copyFile {
      let testDirectory = FileManager.default.temporaryDirectory
          .appendingPathComponent("engine-tests", conformingTo: .directory)
      
      if !FileManager.default.fileExists(atPath: testDirectory.path) {
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
      }
      
      let tempFileName = "\(UUID().uuidString).\(filterListInfo.fileType.fileExtension)"
      let tempFileURL = testDirectory
        .appendingPathComponent(tempFileName, conformingTo: .data)
      let data = try Data(contentsOf: filterListInfo.localFileURL)
      try data.write(to: tempFileURL)
      
      filterListInfo = CachedAdBlockEngine.FilterListInfo(
        source: filterListInfo.source, localFileURL: tempFileURL,
        version: filterListInfo.version, fileType: filterListInfo.fileType
      )
    }
    
    return AdBlockStats.LazyFilterListInfo(filterListInfo: filterListInfo, isAlwaysAggressive: false)
  }
  
  private func loadAvaliableEngines() {
    Task { @MainActor in
      let filterListsSources = FilterListStorage.shared.filterLists.map({ $0.engineSource })
      let customFilterListSources = CustomFilterListStorage.shared.filterListsURLs.map({ $0.setting.engineSource })
      self.availableResources = await [AdBlockStats.shared.resourcesInfo].compactMap({ $0 })
      self.availableFilterLists = await AdBlockStats.shared.availableFilterLists
        .sorted(by: { left, right in
          switch left.key {
          case .adBlock:
            return true
          case .filterList:
            switch right.key {
            case .adBlock:
              return false
            case .filterList:
              let leftIndex = filterListsSources.firstIndex(of: left.key)
              let rightIndex = filterListsSources.firstIndex(of: right.key)
              guard let leftIndex = leftIndex else { return rightIndex == nil }
              guard let rightIndex = rightIndex else { return true }
              return leftIndex < rightIndex
            case .filterListURL:
              return true
            }
          case .filterListURL:
            switch right.key {
            case .adBlock, .filterList:
              return false
            case .filterListURL:
              let leftIndex = customFilterListSources.firstIndex(of: left.key)
              let rightIndex = customFilterListSources.firstIndex(of: right.key)
              guard let leftIndex = leftIndex else { return rightIndex == nil }
              guard let rightIndex = rightIndex else { return true }
              return leftIndex < rightIndex
            }
          }
        })
        .map({ tuple in
          let title = tuple.value.filterListInfo.makeTitle()
          return AvailableFilterList(
            title: "\(title) v\(tuple.value.filterListInfo.version)",
            lazyInfo: tuple.value
          )
        })
    }
  }
}

#if swift(>=5.9)
@available(iOS 17.0, *)
#Preview {
  TestAdblockEnginesView()
}
#endif

private extension CachedAdBlockEngine.FilterListInfo {
  @MainActor func makeTitle() -> String {
    switch self.source {
    case .adBlock: return "Default"
    case .filterList(let componentId):
      let filterList = FilterListStorage.shared.filterLists.first(where: { $0.entry.componentId == componentId })
      return filterList?.entry.title ?? source.debugDescription
    case .filterListURL(let uuid):
      let filterList = CustomFilterListStorage.shared.filterListsURLs.first(where: { $0.setting.uuid == uuid })
      return filterList?.title ?? source.debugDescription
    }
  }
}

extension CachedAdBlockEngine.FileType {
  var conformingType: UTType {
    switch self {
    case .dat: return .data
    case .text: return .text
    }
  }
  
  var fileExtension: String {
    switch self {
    case .dat: return "dat"
    case .text: return "txt"
    }
  }
}
