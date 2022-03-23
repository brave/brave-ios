// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Static
import WebKit
import Shared
import BraveShared

private let log = Logger.browserLogger

class AdblockDebugMenuTableViewController: TableViewController {

  private let fm = FileManager.default

  override func viewDidLoad() {
    super.viewDidLoad()

    ContentBlockerHelper.ruleStore.getAvailableContentRuleListIdentifiers { lists in
      let listNames = lists ?? []
      if listNames.isEmpty { return }

      self.dataSource.sections = [
        self.actionsSection,
        self.fetchSection,
        self.datesSection,
        self.bundledListsSection(names: listNames),
        self.downloadedListsSection(names: listNames),
      ]
    }
  }

  private var actionsSection: Section {
    var section = Section(header: .title("Actions"))
    section.rows = [
      Row(
        text: "Recompile Content Blockers",
        selection: {
          BlocklistName.allLists.forEach { $0.fileVersionPref?.value = nil }
          Task {
            _ = await ContentBlockerHelper.compileBundledLists()
            await MainActor.run { [weak self] in
              let alert = UIAlertController(title: nil, message: "Recompiled Blockers", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default))
              self?.present(alert, animated: true)
            }
          }
        }, cellClass: ButtonCell.self)
    ]

    return section
  }

  private var fetchSection: Section {
    var section = Section(footer: "Last time we pinged the server for new data. If adblock list hasn't changed `Last Time Updated` section does not update.")
    let dateFormatter = DateFormatter().then {
      $0.dateStyle = .short
      $0.timeStyle = .short
    }

    section.rows = [
      .init(
        text: "Last fetch time (adblock)",
        detailText:
          dateFormatter.string(from: AdblockResourceDownloader.shared.lastFetchDate)),
      .init(
        text: "Last fetch time (cosmetic-filters)",
        detailText:
          dateFormatter.string(from: CosmeticFiltersResourceDownloader.shared.lastFetchDate)),
    ]

    return section
  }

  private var datesSection: Section {
    var section = Section(
      header: "Last time updated",
      footer: "When the lists were last time updated on the device")
    var rows = [Row]()

    let dateFormatter = DateFormatter().then {
      $0.dateStyle = .short
      $0.timeStyle = .short
    }

    var generalDateString = "-"
    if let generalDate = Preferences.Debug.lastGeneralAdblockUpdate.value {
      generalDateString = dateFormatter.string(from: generalDate)
      rows.append(.init(text: "General blocklist", detailText: generalDateString))
    }

    var regionalDateString = "-"
    if let regionalDate = Preferences.Debug.lastRegionalAdblockUpdate.value {
      regionalDateString = dateFormatter.string(from: regionalDate)
      rows.append(.init(text: "Regional blocklist", detailText: regionalDateString))
    }

    var cosmeticFilterStylesDateString = "-"
    if let stylesDate = Preferences.Debug.lastCosmeticFiltersCSSUpdate.value {
      cosmeticFilterStylesDateString = dateFormatter.string(from: stylesDate)
      rows.append(.init(text: "Cosmetic Filters (CSS)", detailText: cosmeticFilterStylesDateString))
    }

    var cosmeticFilterScripletsDateString = "-"
    if let scripletsDate = Preferences.Debug.lastCosmeticFiltersCSSUpdate.value {
      cosmeticFilterScripletsDateString = dateFormatter.string(from: scripletsDate)
      rows.append(.init(text: "Cosmetic Filters (Scriptlets)", detailText: cosmeticFilterScripletsDateString))
    }

    section.rows = rows
    return section
  }

  private func bundledListsSection(names: [String]) -> Section {
    var section = Section(
      header: "Preinstalled lists",
      footer: "Lists bundled within the iOS app.")

    var rows = [Row]()

    names.forEach {
      if let bundlePath = Bundle.main.path(forResource: $0, ofType: "json") {
        guard let jsonData = fm.contents(atPath: bundlePath),
          let json = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String: Any]]
        else { return }

        var text = $0 + ".json"

        // Rules with count = 1 don't have to be shown, they are static rules for cookie control
        // tracking protection and httpse.
        if json.count > 1 {
          text += ": \(json.count) rules"
        }

        let hashText = "sha1: \(jsonData.sha1.hexEncodedString)"
        rows.append(.init(text: text, detailText: hashText, cellClass: ShrinkingSubtitleCell.self))
      }

      if $0 == "block-ads",
        let bundlePath = Bundle.main.path(
          forResource: "ABPFilterParserData",
          ofType: "dat"),
        let data = fm.contents(atPath: bundlePath) {
        let hashText = "sha1: \(data.sha1.hexEncodedString)"
        rows.append(.init(text: "ABPFilterParserData.dat", detailText: hashText, cellClass: ShrinkingSubtitleCell.self))
      }
    }

    section.rows = rows
    return section
  }

  private func downloadedListsSection(names: [String]) -> Section {
    var section = Section(
      header: "Downloaded lists",
      footer: "Lists downloaded from the internet at app launch.")

    func getEtag(name: String, folder: String) -> String? {
      guard let folderUrl = fm.getOrCreateFolder(name: folder) else {
        return nil
      }
      let etagUrl = folderUrl.appendingPathComponent(name + ".etag")
      guard let data = fm.contents(atPath: etagUrl.path) else { return nil }
      return String(data: data, encoding: .utf8)
    }

    func getLastModified(name: String, folder: String) -> String? {
      let dateFormatter = DateFormatter().then {
        $0.dateStyle = .short
        $0.timeStyle = .short
        $0.timeZone = TimeZone(abbreviation: "GMT")
      }

      guard let folderUrl = fm.getOrCreateFolder(name: folder) else {
        return nil
      }
      let etagUrl = folderUrl.appendingPathComponent(name + ".lastmodified")
      guard let data = fm.contents(atPath: etagUrl.path),
        let stringData = String(data: data, encoding: .utf8)
      else { return nil }

      let timeInterval = (stringData as NSString).doubleValue
      let date = Date(timeIntervalSince1970: timeInterval)

      return dateFormatter.string(from: date)
    }

    func createRows(folderName: String, names: [String]) -> [Row] {
      guard let folderUrl = fm.getOrCreateFolder(name: folderName) else { return [] }

      var rows = [Row]()
      names.forEach {
        if let data = fm.contents(atPath: folderUrl.appendingPathComponent($0 + ".json").path),
          let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String: Any]] {
          let text = "\($0).json: \(json.count) rules"
          let name = $0 + ".json"

          let etag = getEtag(name: name, folder: folderName) ?? "-"
          let lastModified = getLastModified(name: name, folder: folderName) ?? "-"

          let detail = "\(lastModified), etag: \(etag)"

          rows.append(.init(text: text, detailText: detail, cellClass: ShrinkingSubtitleCell.self))
        }

        if fm.contents(atPath: folderUrl.appendingPathComponent($0 + ".dat").path) != nil {
          let name = $0 + ".dat"

          let etag = getEtag(name: name, folder: folderName) ?? "-"
          let lastModified = getLastModified(name: name, folder: folderName) ?? "-"

          let detail = "\(lastModified), etag: \(etag)"

          rows.append(.init(text: $0 + ".dat", detailText: detail, cellClass: ShrinkingSubtitleCell.self))
        }
      }
      return rows
    }

    let cosmeticFilterNames = [
      CosmeticFiltersResourceDownloader.CosmeticFilterType.cosmeticSample.identifier,
      CosmeticFiltersResourceDownloader.CosmeticFilterType.resourceSample.identifier,
    ]

    var rows = [Row]()
    rows.append(contentsOf: createRows(folderName: AdblockResourceDownloader.folderName, names: names))
    rows.append(contentsOf: createRows(folderName: CosmeticFiltersResourceDownloader.folderName, names: cosmeticFilterNames))
    section.rows = rows
    return section
  }
}

fileprivate class ShrinkingSubtitleCell: SubtitleCell {

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    textLabel?.adjustsFontSizeToFitWidth = true
    detailTextLabel?.adjustsFontSizeToFitWidth = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
