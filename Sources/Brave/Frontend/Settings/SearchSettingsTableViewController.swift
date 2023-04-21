/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Preferences
import os.log

// MARK: - SearchEnginePickerDelegate

protocol SearchEnginePickerDelegate: AnyObject {
  func searchEnginePicker(
    _ searchEnginePicker: SearchEnginePicker?,
    didSelectSearchEngine engine: OpenSearchEngine?, forType: DefaultEngineType?)
}

// MARK: - SearchSettingsTableViewController

class SearchSettingsTableViewController: UITableViewController {

  // MARK: UX

  struct UX {
    static let iconSize = CGSize(
      width: OpenSearchEngine.preferredIconSize,
      height: OpenSearchEngine.preferredIconSize)

    static let headerHeight: CGFloat = 44
  }

  // MARK: Constants

  struct Constants {
    static let addCustomEngineRowIdentifier = "addCustomEngineRowIdentifier"
    static let searchEngineRowIdentifier = "searchEngineRowIdentifier"
    static let switchCell = "switchCell"
    static let quickSearchEngineRowIdentifier = "quickSearchEngineRowIdentifier"
    static let customSearchEngineRowIdentifier = "customSearchEngineRowIdentifier"
  }

  // MARK: Section

  enum Section: Int, CaseIterable {
    case current
    case customSearch
    case braveSearch
  }

  // MARK: CurrentEngineType

  enum CurrentEngineType: Int, CaseIterable {
    case standard
    case `private`
    case quick
    case suggestions
    case recentSearches
  }

  private var searchEngines: SearchEngines
  private let profile: Profile
  private var showDeletion = false

  private func searchPickerEngines(type: DefaultEngineType) -> [OpenSearchEngine] {
    let isPrivate = type == .privateMode

    var orderedEngines = searchEngines.orderedEngines
      .sorted { $0.shortName < $1.shortName }
      .sorted { engine, _ in engine.shortName == OpenSearchEngine.EngineNames.brave }

    if isPrivate {
      orderedEngines =
      orderedEngines
        .filter { !$0.isCustomEngine || $0.engineID == OpenSearchEngine.migratedYahooEngineID }
    }

    if let priorityEngine = InitialSearchEngines().priorityEngine?.rawValue {
      orderedEngines =
      orderedEngines
        .sorted { engine, _ in
          engine.engineID == priorityEngine
        }
    }

    return orderedEngines
  }

  private var customSearchEngines: [OpenSearchEngine] {
    searchEngines.orderedEngines.filter { $0.isCustomEngine }
  }

  // MARK: Lifecycle

  init(profile: Profile) {
    self.profile = profile
    self.searchEngines = profile.searchEngines
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = Strings.searchSettingNavTitle

    tableView.do {
      $0.allowsSelectionDuringEditing = true
      $0.registerHeaderFooter(SettingsTableSectionHeaderFooterView.self)
      $0.register(UITableViewCell.self, forCellReuseIdentifier: Constants.addCustomEngineRowIdentifier)
      $0.register(UITableViewCell.self, forCellReuseIdentifier: Constants.searchEngineRowIdentifier)
      $0.register(UITableViewCell.self, forCellReuseIdentifier: Constants.quickSearchEngineRowIdentifier)
      $0.register(UITableViewCell.self, forCellReuseIdentifier: Constants.customSearchEngineRowIdentifier)
      $0.register(UITableViewCell.self, forCellReuseIdentifier: Constants.switchCell)
      $0.sectionHeaderTopPadding = 5
    }

    // Insert Done button if being presented outside of the Settings Nav stack
    if navigationController?.viewControllers.first === self {
      navigationItem.leftBarButtonItem =
      UIBarButtonItem(title: Strings.settingsSearchDoneButton, style: .done, target: self, action: #selector(dismissAnimated))
    }

    let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: UX.headerHeight))
    tableView.tableFooterView = footer
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    updateTableEditModeVisibility()
    tableView.reloadData()
  }

  // MARK: Internal

  private func configureSearchEnginePicker(_ type: DefaultEngineType) -> SearchEnginePicker {
    return SearchEnginePicker(type: type, showCancel: false).then {
      // Order alphabetically, so that picker is always consistently ordered.
      // Every engine is a valid choice for the default engine, even the current default engine.
      // In private mode only custom engines will not be shown excluding migrated Yahoo Search Engine
      $0.engines = searchPickerEngines(type: type)
      $0.delegate = self
      $0.selectedSearchEngineName = searchEngines.defaultEngine(forType: type).shortName
    }
  }

  private func configureSearchEngineCell(type: DefaultEngineType, engineName: String?) -> UITableViewCell {
    guard let searchEngineName = engineName else { return UITableViewCell() }

    var text: String

    switch type {
    case .standard:
      text = Strings.standardTabSearch
    case .privateMode:
      text = Strings.privateTabSearch
    }

    let cell = UITableViewCell(style: .value1, reuseIdentifier: Constants.searchEngineRowIdentifier).then {
      $0.accessoryType = .disclosureIndicator
      $0.editingAccessoryType = .disclosureIndicator
      $0.accessibilityLabel = text
      $0.textLabel?.text = text
      $0.accessibilityValue = searchEngineName
      $0.detailTextLabel?.text = searchEngineName
    }

    return cell
  }
  
  private func updateTableEditModeVisibility() {
    tableView.endEditing(true)
    
    if customSearchEngines.isEmpty {
      navigationItem.rightBarButtonItem = nil
    } else {
      navigationItem.rightBarButtonItem = editButtonItem
    }
  }

  // MARK: TableViewDataSource - TableViewDelegate

  override func numberOfSections(in tableView: UITableView) -> Int {
    return Section.allCases.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let section = Section(rawValue: section) else {
      assertionFailure()
      return 0
    }

    switch section {
    case .current:
      return CurrentEngineType.allCases.count
    case .customSearch:
      return customSearchEngines.count + 1
    case .braveSearch:
      return 1
    }
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return UX.headerHeight
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell?
    guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
    
    switch section {
    case .current:
      cell = configureCurrentSectionCell(indexPath: indexPath)
    case .customSearch:
      cell = configureCustomSectionCell(indexPath: indexPath)
    case .braveSearch:
      cell = configureBraveSearchSection(indexPath: indexPath)
    }
    
    cell?.separatorInset = .zero
    
    return cell ?? UITableViewCell()
  }
  
  private func configureCurrentSectionCell(indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell?
    
    switch indexPath.item {
    case CurrentEngineType.standard.rawValue:
      let engine = searchEngines.defaultEngine(forType: .standard)
      cell = configureSearchEngineCell(type: .standard, engineName: engine.displayName)
    case CurrentEngineType.private.rawValue:
      let engine = searchEngines.defaultEngine(forType: .privateMode)
      cell = configureSearchEngineCell(type: .privateMode, engineName: engine.displayName)
    case CurrentEngineType.quick.rawValue:
      cell = configureQuickSearchEngineCell(indexPath: indexPath)
    case CurrentEngineType.suggestions.rawValue:
      cell = configureSearchSuggestionsCell(indexPath: indexPath)
    case CurrentEngineType.recentSearches.rawValue:
      cell = configureRecentSearchesCell(indexPath: indexPath)
    default:
      assertionFailure()
    }
    
    return cell ?? UITableViewCell()
  }
  
  private func configureCustomSectionCell(indexPath: IndexPath) -> UITableViewCell {
    if indexPath.item == customSearchEngines.count {
      let cell = tableView.dequeueReusableCell(withIdentifier: Constants.addCustomEngineRowIdentifier, for: indexPath).then {
        $0.textLabel?.text = Strings.searchSettingAddCustomEngineCellTitle
        $0.accessoryType = .disclosureIndicator
        $0.editingAccessoryType = .disclosureIndicator
      }
      return cell
    } else {
      let engine = customSearchEngines[indexPath.item]
      let cell = tableView.dequeueReusableCell(withIdentifier: Constants.customSearchEngineRowIdentifier, for: indexPath).then {
        $0.textLabel?.text = engine.displayName
        $0.textLabel?.adjustsFontSizeToFitWidth = true
        $0.textLabel?.minimumScaleFactor = 0.5
        $0.imageView?.image = engine.image.createScaled(UX.iconSize)
        $0.imageView?.layer.cornerRadius = 4
        $0.imageView?.layer.cornerCurve = .continuous
        $0.imageView?.layer.masksToBounds = true
        $0.selectionStyle = .none
      }
      return cell
    }
  }
  
  private func configureQuickSearchEngineCell(indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.quickSearchEngineRowIdentifier, for: indexPath).then {
      $0.textLabel?.text = Strings.quickSearchEngines
      $0.accessoryType = .disclosureIndicator
      $0.editingAccessoryType = .disclosureIndicator
    }
    
    return cell
  }
  
  private func configureSearchSuggestionsCell(indexPath: IndexPath) -> UITableViewCell {
    let toggle = UISwitch().then {
      $0.addTarget(self, action: #selector(didToggleSearchSuggestions), for: .valueChanged)
      $0.isOn = searchEngines.shouldShowSearchSuggestions
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.switchCell, for: indexPath).then {
      $0.textLabel?.text = Strings.searchSettingSuggestionCellTitle
      $0.accessoryView = toggle
      $0.selectionStyle = .none
    }
    
    return cell
  }
  
  private func configureRecentSearchesCell(indexPath: IndexPath) -> UITableViewCell {
    let toggle = UISwitch().then {
      $0.addTarget(self, action: #selector(didToggleRecentSearches), for: .valueChanged)
      $0.isOn = searchEngines.shouldShowRecentSearches
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.switchCell, for: indexPath).then {
      $0.textLabel?.text = Strings.searchSettingRecentSearchesCellTitle
      $0.accessoryView = toggle
      $0.selectionStyle = .none
    }
    
    return cell
  }
  
  private func configureBraveSearchSection(indexPath: IndexPath) -> UITableViewCell {
    let toggle = UISwitch().then {
      $0.addTarget(self, action: #selector(didToggleFallbackMixing), for: .valueChanged)
      $0.isOn = Preferences.General.forceBraveSearchFallbackMixing.value
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.switchCell, for: indexPath).then {
      $0.textLabel?.text = Strings.Settings.braveSearchFallbackMixingOption
      $0.accessoryView = toggle
      $0.selectionStyle = .none
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let section = Section(rawValue: section) else {
      assertionFailure()
      return nil
    }
    let headerView = tableView.dequeueReusableHeaderFooter() as SettingsTableSectionHeaderFooterView
    
    let label = headerView.titleLabel
    var text: String?
    
    switch section {
    case .current:
      text = Strings.currentlyUsedSearchEngines
    case .customSearch:
      text = Strings.customSearchEngines
    case .braveSearch:
      text = Strings.Settings.braveSearchSection
    }
    
    label.text = text?.uppercased()
    
    return headerView
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard section == Section.braveSearch.rawValue else { return nil }
    let headerView = tableView.dequeueReusableHeaderFooter() as SettingsTableSectionHeaderFooterView
    headerView.titleLabel.text = Strings.Settings.braveSearchFallbackMixingFooter
    return headerView
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    guard let section = Section(rawValue: section) else {
      return 0
    }
    
    switch section {
    case .braveSearch:
      return UITableView.automaticDimension
    case .current, .customSearch:
      return 0
    }
  }
  
  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    guard let section = Section(rawValue: indexPath.section), let nav = navigationController else { return nil }
    let item = indexPath.item
    
    switch (section, item) {
    case (.current, CurrentEngineType.standard.rawValue):
      nav.pushViewController(configureSearchEnginePicker(.standard), animated: true)
    case (.current, CurrentEngineType.private.rawValue):
      nav.pushViewController(configureSearchEnginePicker(.privateMode), animated: true)
    case (.current, CurrentEngineType.quick.rawValue):
      let quickSearchEnginesViewController = SearchQuickEnginesViewController(profile: profile)
      nav.pushViewController(quickSearchEnginesViewController, animated: true)
    case (.customSearch, let item) where item == customSearchEngines.count:
      let customEngineViewController = SearchCustomEngineViewController(profile: profile)
      nav.pushViewController(customEngineViewController, animated: true)
    default:
      break
    }

    return nil
  }

  // Determine whether to show delete button in edit mode
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    guard indexPath.section == Section.customSearch.rawValue, indexPath.row != customSearchEngines.count else {
      return .none
    }

    return .delete
  }

  // Determine whether to indent while in edit mode for deletion
  override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
    return indexPath.section == Section.customSearch.rawValue && indexPath.row != customSearchEngines.count
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      guard let engine = customSearchEngines[safe: indexPath.row] else { return }
      
      func deleteCustomEngine() {
        do {
          try searchEngines.deleteCustomEngine(engine)
          tableView.deleteRows(at: [indexPath], with: .right)
          tableView.reloadData()
          updateTableEditModeVisibility()
        } catch {
          Logger.module.error("Search Engine Error while deleting")
        }
      }

      if engine == searchEngines.defaultEngine(forType: .standard) {
        let alert = UIAlertController(
          title: String(format: Strings.CustomSearchEngine.deleteEngineAlertTitle, engine.displayName),
          message: Strings.CustomSearchEngine.deleteEngineAlertDescription,
          preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel))
        
        alert.addAction(UIAlertAction(title: Strings.delete, style: .destructive) { [weak self] _ in
          guard let self = self else { return }
          
          self.searchEngines.updateDefaultEngine(
            self.searchEngines.defaultEngine(forType: .privateMode).shortName,
            forType: .standard)
          
          deleteCustomEngine()
        })

        UIImpactFeedbackGenerator(style: .medium).bzzt()
        present(alert, animated: true, completion: nil)
      } else {
        deleteCustomEngine()
      }
    }
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return indexPath.section == Section.customSearch.rawValue
  }
}

// MARK: - Actions

extension SearchSettingsTableViewController {

  @objc func didToggleSearchSuggestions(_ toggle: UISwitch) {
    // Setting the value in settings dismisses any opt-in.
    searchEngines.shouldShowSearchSuggestions = toggle.isOn
    searchEngines.shouldShowSearchSuggestionsOptIn = false
  }

  @objc func didToggleRecentSearches(_ toggle: UISwitch) {
    // Setting the value in settings dismisses any opt-in.
    searchEngines.shouldShowRecentSearches = toggle.isOn
    searchEngines.shouldShowRecentSearchesOptIn = false
  }
  
  @objc func didToggleFallbackMixing(_ toggle: UISwitch) {
    Preferences.General.forceBraveSearchFallbackMixing.value = toggle.isOn
  }
  
  @objc func dismissAnimated() {
    self.dismiss(animated: true, completion: nil)
  }
}

// MARK: SearchEnginePickerDelegate

extension SearchSettingsTableViewController: SearchEnginePickerDelegate {

  func searchEnginePicker(
    _ searchEnginePicker: SearchEnginePicker?,
    didSelectSearchEngine searchEngine: OpenSearchEngine?, forType: DefaultEngineType?
  ) {
    if let engine = searchEngine, let type = forType {
      searchEngines.updateDefaultEngine(engine.shortName, forType: type)
      self.tableView.reloadData()
    }
    _ = navigationController?.popViewController(animated: true)
  }
}
