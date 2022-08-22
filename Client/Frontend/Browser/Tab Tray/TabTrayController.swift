// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveCore
import BraveShared
import Combine
import Data
import SnapKit

protocol TabTrayDelegate: AnyObject {
  /// Notifies the delegate that order of tabs on tab tray has changed.
  /// This info can be used to update UI in other place, for example update order of tabs in tabs bar.
  func tabOrderChanged()
}

class TabTrayController: LoadingViewController {

  typealias DataSource = UICollectionViewDiffableDataSource<TabTraySection, Tab>
  typealias Snapshot = NSDiffableDataSourceSnapshot<TabTraySection, Tab>
  
  // MARK: Internal
  
  enum TabTraySection {
    case main
  }
  
  enum TabTrayMode {
    case local
    case sync
  }

  let tabManager: TabManager
  private let openTabsAPI: BraveOpenTabsAPI  
  private var openTabsSessionServiceListener: OpenTabsSessionStateListener?
  
  weak var delegate: TabTrayDelegate?
  weak var toolbarUrlActionsDelegate: ToolbarUrlActionsDelegate?

  private(set) lazy var dataSource =
    DataSource(
      collectionView: tabTrayView.collectionView,
      cellProvider: { [weak self] collectionView, indexPath, tab -> UICollectionViewCell? in
        self?.cellProvider(collectionView: collectionView, indexPath: indexPath, tab: tab)
      })
  
  private(set) var sessionList = [OpenDistantSession]()
  var hiddenSections = Set<Int>()

  private(set) var privateMode: Bool = false {
    didSet {
      // Should be set immediately before other logic executes
      PrivateBrowsingManager.shared.isPrivateBrowsing = privateMode
      applySnapshot()

      privateModeButton.isSelected = privateMode
      tabTypeSelector.isHidden = privateMode
    }
  }

  var searchTabTrayTimer: Timer?
  var isTabTrayBeingSearched = false
  var tabTraySearchQuery = ""
  var tabTrayMode: TabTrayMode = .local
  private var privateModeCancellable: AnyCancellable?
  private var initialScrollCompleted = false
  
  // MARK: User Interface Elements
  
  private struct UX {
    static let buttonEdgeInset = 10.0
  }
  
  private let containerView = UIView().then {
    $0.backgroundColor = .secondaryBraveBackground
  }
  
  private let tabContentView = UIView().then {
    $0.backgroundColor = .braveBackground
  }
  
  private var tabTypeSelectorItems = [UIImage]()
  private lazy var tabTypeSelector: UISegmentedControl = {
    let segmentedControl = UISegmentedControl(items: tabTypeSelectorItems).then {
      $0.selectedSegmentIndex = 0
      $0.backgroundColor = .secondaryBraveBackground
      $0.addTarget(self, action: #selector(typeSelectionDidChange(_:)), for: .valueChanged)
    }
    return segmentedControl
  }()
  
  var tabTrayView = TabTrayContainerView().then {
    $0.isHidden = false
  }
  
  var tabSyncView = TabSyncContainerView().then {
    $0.isHidden = true
  }
  
  let newTabButton = UIButton(type: .system).then {
    $0.setImage(UIImage(named: "add_tab", in: .current, compatibleWith: nil)!.template, for: .normal)
    $0.accessibilityLabel = Strings.tabTrayAddTabAccessibilityLabel
    $0.accessibilityIdentifier = "TabTrayController.addTabButton"
    $0.tintColor = .braveLabel
    $0.contentEdgeInsets = .init(top: 0, left: UX.buttonEdgeInset, bottom: 0, right: UX.buttonEdgeInset)
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  let doneButton = UIButton(type: .system).then {
    $0.setTitle(Strings.done, for: .normal)
    $0.titleLabel?.font = .preferredFont(forTextStyle: .body)
    $0.titleLabel?.adjustsFontForContentSizeCategory = true
    $0.contentHorizontalAlignment = .right
    $0.titleLabel?.adjustsFontSizeToFitWidth = true
    $0.accessibilityLabel = Strings.done
    $0.accessibilityIdentifier = "TabTrayController.doneButton"
    $0.tintColor = .braveLabel
  }

  let privateModeButton = PrivateModeButton().then {
    $0.titleLabel?.font = .preferredFont(forTextStyle: .body)
    $0.titleLabel?.adjustsFontForContentSizeCategory = true
    $0.contentHorizontalAlignment = .left
    $0.setTitle(Strings.private, for: .normal)
    $0.tintColor = .braveLabel

    if Preferences.Privacy.privateBrowsingOnly.value {
      $0.alpha = 0
    }
  }
  
  private var searchBarView: TabTraySearchBar?
  let tabTraySearchController = UISearchController(searchResultsController: nil)

  private lazy var emptyStateOverlayView: UIView = EmptyStateOverlayView(title: Strings.noSearchResultsfound)

  override var preferredStatusBarStyle: UIStatusBarStyle {
    if PrivateBrowsingManager.shared.isPrivateBrowsing {
      return .lightContent
    }
    
    return view.overrideUserInterfaceStyle == .light ? .darkContent : .lightContent
  }

  // MARK: Lifecycle
  
  init(tabManager: TabManager, openTabsAPI: BraveOpenTabsAPI) {
    self.tabManager = tabManager
    self.openTabsAPI = openTabsAPI
    super.init(nibName: nil, bundle: nil)

    if !UIAccessibility.isReduceMotionEnabled {
      transitioningDelegate = self
      modalPresentationStyle = .fullScreen
    }
    
    // Adding the Open Tabs session observer in constructor to watch synced sessions updating
    openTabsSessionServiceListener = openTabsAPI.add(
      OpenTabsStateObserver { [weak self] stateChange in
        guard let self = self else { return }
        
        switch stateChange {
        case .openTabsSyncCycleCompleted:
          self.reloadOpenTabsSession()
        default:
          break
        }
      }
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  deinit {
    tabManager.removeDelegate(self)
    
    // Remove the open tabs service observer
    if let observer = openTabsSessionServiceListener {
      openTabsAPI.removeObserver(observer)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    definesPresentationContext = true

    searchBarView = TabTraySearchBar(searchBar: tabTraySearchController.searchBar).then {
      $0.searchBar.autocapitalizationType = .none
      $0.searchBar.autocorrectionType = .no
      $0.searchBar.placeholder = Strings.tabTraySearchBarTitle
    }

    tabTraySearchController.do {
      $0.searchResultsUpdater = self
      $0.obscuresBackgroundDuringPresentation = false
      $0.delegate = self
      // Don't hide the navigation bar because the search bar is in it.
      $0.hidesNavigationBarDuringPresentation = false
    }

    navigationItem.do {
      // Place the search bar in the navigation item's title view.
      $0.titleView = searchBarView
      $0.hidesSearchBarWhenScrolling = true
    }

    tabManager.addDelegate(self)

    tabTrayView.collectionView.do {
      $0.dataSource = dataSource
      $0.delegate = self
      $0.dragDelegate = self
      $0.dropDelegate = self
      $0.dragInteractionEnabled = true
    }
    
    tabSyncView.tableView.do {
      $0.dataSource = self
      $0.delegate = self
    }

    privateMode = tabManager.selectedTab?.isPrivate == true

    doneButton.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
    newTabButton.addTarget(self, action: #selector(newTabAction), for: .touchUpInside)
    privateModeButton.addTarget(self, action: #selector(togglePrivateModeAction), for: .touchUpInside)

    navigationController?.isToolbarHidden = false

    toolbarItems = [
      UIBarButtonItem(customView: privateModeButton),
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
      UIBarButtonItem(customView: newTabButton),
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
      UIBarButtonItem(customView: doneButton),
    ]
    
    privateModeCancellable = PrivateBrowsingManager.shared
      .$isPrivateBrowsing
      .removeDuplicates()
      .sink(receiveValue: { [weak self] isPrivateBrowsing in
        self?.updateColors(isPrivateBrowsing)
      })
  
    reloadOpenTabsSession()
  }
  
  override func loadView() {
    createTypeSelectorItems()
    layoutTabTray()
  }
  
  private func layoutTabTray() {
    let contentStackView = UIStackView().then {
      $0.axis = .vertical
      $0.alignment = .center
    }
        
    contentStackView.addArrangedSubview(tabTypeSelector)
    contentStackView.addArrangedSubview(tabContentView)
    
    containerView.addSubview(contentStackView)
    
    contentStackView.snp.makeConstraints {
      $0.edges.equalTo(containerView.safeAreaLayoutGuide)
    }
    
    tabTypeSelector.snp.makeConstraints {
      $0.width.equalTo(contentStackView.snp.width).dividedBy(2)
    }
    
    tabContentView.addSubview(tabTrayView)
    tabContentView.addSubview(tabSyncView)
    
    tabTrayView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    tabSyncView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    view = containerView
  }
  
  private func createTypeSelectorItems() {
    tabTypeSelectorItems = [UIImage(systemName: "square.on.square")!.template,
                            UIImage(systemName: "laptopcomputer.and.iphone")!.template]
  }
  
  @objc func typeSelectionDidChange(_ sender: UISegmentedControl) {
    tabTraySearchController.isActive = false
    tabTrayMode = sender.selectedSegmentIndex == 0 ? .local : .sync

    tabTrayView.isHidden = tabTrayMode == .sync
    tabSyncView.isHidden = tabTrayMode == .local
    
    searchBarView?.searchBar.placeholder = tabTrayMode == .local ? Strings.tabTraySearchBarTitle : "Search Open Tabs"
  }
  
  private func updateColors(_ isPrivateBrowsing: Bool) {
    if isPrivateBrowsing {
      overrideUserInterfaceStyle = .dark
    } else {
      overrideUserInterfaceStyle = DefaultTheme(
        rawValue: Preferences.General.themeNormalMode.value)?.userInterfaceStyleOverride ?? .unspecified
    }
    
    setNeedsStatusBarAppearanceUpdate()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // When user opens the tray for the first time, we scroll the collection view to selected tab.
    if initialScrollCompleted { return }

    if let selectedTab = tabManager.selectedTab,
      let selectedIndexPath = dataSource.indexPath(for: selectedTab) {
      DispatchQueue.main.async {
        self.tabTrayView.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
      }

      initialScrollCompleted = true
    }
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    searchBarView?.frame = navigationController?.navigationBar.frame ?? .zero
    navigationItem.titleView = searchBarView
    
    searchBarView?.setNeedsLayout()
    searchBarView?.layoutIfNeeded()
  }

  // MARK: Snapshot handling

  func applySnapshot(for query: String? = nil) {
    var snapshot = Snapshot()
    snapshot.appendSections([.main])
    snapshot.appendItems(tabManager.tabsForCurrentMode(for: query))
    dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
      guard let self = self else { return }
      
      let isSearchResultEmpty = self.dataSource.snapshot().numberOfItems == 0 && self.isTabTrayBeingSearched
      self.updateEmptyPanelState(isHidden: !isSearchResultEmpty)
    }
  }

  /// Reload the data source even if no changes are present. Use with caution.
  func forceReload() {
    var snapshot = dataSource.snapshot()
    snapshot.reloadSections([.main])
    dataSource.apply(snapshot, animatingDifferences: false)
  }

  private func cellProvider(
    collectionView: UICollectionView,
    indexPath: IndexPath,
    tab: Tab
  ) -> UICollectionViewCell? {
    guard
      let cell =
        collectionView
        .dequeueReusableCell(
          withReuseIdentifier: TabCell.identifier,
          for: indexPath) as? TabCell
    else { return UICollectionViewCell() }

    cell.configure(with: tab)

    if tab == tabManager.selectedTab {
      cell.setTabSelected(tab)
    }

    cell.closedTab = { [weak self] tab in
      self?.remove(tab: tab)
      UIAccessibility.post(notification: .announcement, argument: Strings.tabTrayClosingTabAccessibilityNotificationText)
    }

    return cell
  }
  
  func reloadOpenTabsSession(for query: String? = nil) {
    sessionList = fetchSyncedSessions(for: query)
    
    tabSyncView.do {
      $0.tableView.reloadData()
      $0.updateNoSyncPanelState(isHidden: sessionList.count > 0)
    }
    
    updateEmptyPanelState(isHidden: !(isTabTrayBeingSearched && sessionList.isEmpty && !(query?.isEmpty ?? true)))
  }
  
  private func fetchSyncedSessions(for query: String? = nil) -> [OpenDistantSession] {
    let allSessions = openTabsAPI.getSyncedSessions()
    var queriedSessions = [OpenDistantSession]()
    
    if let query = query, !query.isEmpty {
      for session in allSessions {
        let queriedSyncedTabList = session.tabs.filter {
          ($0.title?.lowercased().contains(query) ?? false) || ($0.url.baseDomain?.contains(query) ?? false)
        }

        session.tabs = queriedSyncedTabList
        queriedSessions.append(session)
      }
    }
    
    return queriedSessions
  }

  private func updateEmptyPanelState(isHidden: Bool) {
    if isHidden {
      emptyStateOverlayView.removeFromSuperview()
    } else {
      showEmptyPanelState()
    }
  }

  private func showEmptyPanelState() {
    if emptyStateOverlayView.superview == nil {
      view.addSubview(emptyStateOverlayView)
      view.bringSubviewToFront(emptyStateOverlayView)
      emptyStateOverlayView.snp.makeConstraints {
        $0.edges.equalTo(tabTrayView.collectionView)
      }
    }
  }
  
  // MARK: - Actions

  @objc func doneAction() {
    tabTraySearchController.isActive = false

    dismiss(animated: true)
  }

  @objc func newTabAction() {
    tabTraySearchController.isActive = false

    let wasPrivateModeInfoShowing = tabTrayView.isPrivateModeInfoShowing
    if privateMode {
      tabTrayView.hidePrivateModeInfo()
      navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // If private mode info is showing it means we already added one tab.
    // So when user taps on the 'new tab' button we do nothing, only dismiss the view.
    if wasPrivateModeInfoShowing {
      dismiss(animated: true)
    } else {
      tabManager.addTabAndSelect(isPrivate: privateMode)
    }
  }

  @objc func togglePrivateModeAction() {
    tabTraySearchController.isActive = false

    // Record the slected index before private mode navigation
    if !privateMode {
      tabManager.normalTabSelectedIndex = tabManager.selectedIndex
    }
    
    tabManager.willSwitchTabMode(leavingPBM: privateMode)
    privateMode.toggle()
    
    // When we switch from Private => Regular make sure we reset _selectedIndex, fix for bug #888
    tabManager.resetSelectedIndex()
    if privateMode {
      tabTypeSelector.selectedSegmentIndex = 0
      tabTypeSelector.sendActions(for: UIControl.Event.valueChanged)
      
      tabTrayView.showPrivateModeInfo()
      // New private tab is created immediately to reflect changes on NTP.
      // If user drags the modal down or dismisses it, a new private tab will be ready.
      tabManager.addTabAndSelect(isPrivate: true)
    } else {
      tabTrayView.hidePrivateModeInfo()
      
      // When you go back from private mode, a previous current tab is selected
      // Reloding the collection view in order to mark the selecte the tab
      tabManager.selectTab(tabManager.tabsForCurrentMode[safe: tabManager.normalTabSelectedIndex])
      tabTrayView.collectionView.reloadData()
    }
    
    navigationController?.setNavigationBarHidden(privateMode, animated: false)
    tabTypeSelector.isHidden = privateMode

  }

  private func remove(tab: Tab) {
    tabManager.removeTab(tab)
    
    let query = isTabTrayBeingSearched ? tabTraySearchQuery : nil
    applySnapshot(for: query)
  }

  func removeAllTabs() {
    tabManager.removeTabsWithUndoToast(tabManager.tabsForCurrentMode)
    applySnapshot()
  }
}

// MARK: TabManagerDelegate

extension TabTrayController: TabManagerDelegate {
  func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
    applySnapshot()

    // This check is mainly for entering private mode.
    // Then a first private tab is created, and we want to show an informational screen
    // instead of taking the user directly to new tab page.
    if tabManager.tabsForCurrentMode.count > 1 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.dismiss(animated: true)
      }
    }
  }

  func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
    // When user removes their last tab, a new one is created.
    // Until then, the view is dismissed and takes the user directly to that tab.
    if tabManager.tabsForCurrentMode.count < 1 {
      dismiss(animated: true)
    }
  }

  func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {}
  func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {}
  func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {}
  func tabManagerDidAddTabs(_ tabManager: TabManager) {}
  func tabManagerDidRestoreTabs(_ tabManager: TabManager) {}
  func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {}
}

// MARK: UIScrollViewAccessibilityDelegate

extension TabTrayController: UIScrollViewAccessibilityDelegate {
  func accessibilityScrollStatus(for scrollView: UIScrollView) -> String? {
    let collectionView = tabTrayView.collectionView

    guard var visibleCells = collectionView.visibleCells as? [TabCell] else { return nil }
    var bounds = collectionView.bounds
    bounds = bounds.offsetBy(dx: collectionView.contentInset.left, dy: collectionView.contentInset.top)
    bounds.size.width -= collectionView.contentInset.left + collectionView.contentInset.right
    bounds.size.height -= collectionView.contentInset.top + collectionView.contentInset.bottom
    // visible cells do sometimes return also not visible cells when attempting to go past the last cell with VoiceOver right-flick gesture; so make sure we have only visible cells (yeah...)
    visibleCells = visibleCells.filter { !$0.frame.intersection(bounds).isEmpty }

    let cells = visibleCells.compactMap { collectionView.indexPath(for: $0) }
    let indexPaths = cells.sorted { (a: IndexPath, b: IndexPath) -> Bool in
      return a.section < b.section || (a.section == b.section && a.row < b.row)
    }

    if indexPaths.isEmpty {
      return Strings.tabTrayEmptyVoiceOverText
    }

    guard let firstTab = indexPaths.first, let lastTab = indexPaths.last else {
      return nil
    }

    let firstTabRow = firstTab.row + 1
    let lastTabRow = lastTab.row + 1
    let tabCount = collectionView.numberOfItems(inSection: 0)

    if firstTabRow == lastTabRow {
      return String(
        format: Strings.tabTraySingleTabPositionFormatVoiceOverText,
        NSNumber(value: firstTabRow), NSNumber(value: tabCount))
    } else {
      return String(format: Strings.tabTrayMultiTabPositionFormatVoiceOverText, NSNumber(value: firstTabRow as Int), NSNumber(value: lastTabRow), NSNumber(value: tabCount))
    }
  }
}
