/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import WebKit

struct TopTabsUX {
    static let TopTabsViewHeight: CGFloat = 44
    static let TopTabsBackgroundShadowWidth: CGFloat = 12
    static let TabWidth: CGFloat = 190
    static let FaderPading: CGFloat = 8
    static let SeparatorWidth: CGFloat = 1
    static let HighlightLineWidth: CGFloat = 3
    static let TabNudge: CGFloat = 1 // Nudge the favicon and close button by 1px
    static let TabTitlePadding: CGFloat = 10
    static let AnimationSpeed: TimeInterval = 0.1
    static let SeparatorYOffset: CGFloat = 7
    static let SeparatorHeight: CGFloat = 32
}

protocol TopTabsDelegate: class {
    func topTabsDidPressTabs()
    func topTabsDidPressNewTab(_ isPrivate: Bool)

    func topTabsDidTogglePrivateMode()
    func topTabsDidChangeTab()
}

protocol TopTabCellDelegate: class {
    func tabCellDidClose(_ cell: TopTabCell)
}

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?
    fileprivate var isPrivate = false
    fileprivate var isDragging = false

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: TopTabsViewLayout())
        collectionView.register(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.Identifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        collectionView.accessibilityIdentifier = "Top Tabs View"
        collectionView.semanticContentAttribute = .forceLeftToRight
        return collectionView
    }()
    
    fileprivate lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.semanticContentAttribute = .forceLeftToRight
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), for: .touchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsViewController.tabsButton"
        return tabsButton
    }()
    
    fileprivate lazy var newTab: UIButton = {
        let newTab = UIButton.newTabButton()
        newTab.semanticContentAttribute = .forceLeftToRight
        newTab.addTarget(self, action: #selector(TopTabsViewController.newTabTapped), for: .touchUpInside)
        return newTab
    }()
    
    lazy var privateModeButton: PrivateModeButton = {
        let privateModeButton = PrivateModeButton()
        privateModeButton.semanticContentAttribute = .forceLeftToRight
        privateModeButton.light = true
        privateModeButton.addTarget(self, action: #selector(TopTabsViewController.togglePrivateModeTapped), for: .touchUpInside)
        return privateModeButton
    }()
    
    fileprivate lazy var tabLayoutDelegate: TopTabsLayoutDelegate = {
        let delegate = TopTabsLayoutDelegate()
        delegate.tabSelectionDelegate = self
        return delegate
    }()

    fileprivate var tabsToDisplay: [Tab] {
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }

    // Handle animations.
    fileprivate var tabStore: [Tab] = [] //the actual datastore
    fileprivate var pendingUpdatesToTabs: [Tab] = [] //the datastore we are transitioning to
    fileprivate var needReloads: [Tab?] = [] // Tabs that need to be reloaded
    fileprivate var isUpdating = false
    fileprivate var pendingReloadData = false
    fileprivate var oldTabs: [Tab]? // The last state of the tabs before an animation
    fileprivate weak var oldSelectedTab: Tab? // Used to select the right tab when transitioning between private/normal tabs

    private var tabObservers: TabObservers!

    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        collectionView.dataSource = self
        collectionView.delegate = tabLayoutDelegate
        [UICollectionElementKindSectionHeader, UICollectionElementKindSectionFooter].forEach {
            collectionView.register(TopTabsHeaderFooter.self, forSupplementaryViewOfKind: $0, withReuseIdentifier: "HeaderFooter")
        }
        self.tabObservers = registerFor(.didLoadFavicon, .didChangeURL, queue: .main)
    }
    
    deinit {
        self.tabManager.removeDelegate(self)
        unregister(tabObservers)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.tabsToDisplay != self.tabStore {
            performTabUpdates()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabManager.addDelegate(self)
        self.tabStore = self.tabsToDisplay

        if #available(iOS 11.0, *) {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
        }

        let topTabFader = TopTabFader()
        topTabFader.semanticContentAttribute = .forceLeftToRight

        view.addSubview(topTabFader)
        topTabFader.addSubview(collectionView)
        view.addSubview(tabsButton)
        view.addSubview(newTab)
        view.addSubview(privateModeButton)

        // Setup UIDropInteraction to handle dragging and dropping
        // links onto the "New Tab" button.
        if #available(iOS 11, *) {
            let dropInteraction = UIDropInteraction(delegate: self)
            newTab.addInteraction(dropInteraction)
        }

        newTab.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(tabsButton.snp.leading).offset(-10)
            make.size.equalTo(view.snp.height)
        }
        tabsButton.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(view).offset(-10)
            make.size.equalTo(view.snp.height)
        }
        privateModeButton.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.leading.equalTo(view).offset(10)
            make.size.equalTo(view.snp.height)
        }
        topTabFader.snp.makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateModeButton.snp.trailing)
            make.trailing.equalTo(newTab.snp.leading)
        }
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(topTabFader)
        }

        view.backgroundColor = UIColor.Photon.Grey80
        tabsButton.applyTheme(.Normal)
        if let currentTab = tabManager.selectedTab {
            applyTheme(currentTab.isPrivate ? .Private : .Normal)
        }
        updateTabCount(tabStore.count, animated: false)
    }
    
    func switchForegroundStatus(isInForeground reveal: Bool) {
        // Called when the app leaves the foreground to make sure no information is inadvertently revealed
        if let cells = self.collectionView.visibleCells as? [TopTabCell] {
            let alpha: CGFloat = reveal ? 1 : 0
            for cell in cells {
                cell.titleText.alpha = alpha
                cell.favicon.alpha = alpha
            }
        }
    }
    
    func updateTabCount(_ count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }
    
    @objc func tabsTrayTapped() {
        delegate?.topTabsDidPressTabs()
    }
    
    @objc func newTabTapped() {
        if pendingReloadData {
            return
        }
        self.delegate?.topTabsDidPressNewTab(self.isPrivate)
    }

    @objc func togglePrivateModeTapped() {
        if isUpdating || pendingReloadData {
            return
        }
        let isPrivate = self.isPrivate
        delegate?.topTabsDidTogglePrivateMode()
        self.pendingReloadData = true // Stops animations from happening
        let oldSelectedTab = self.oldSelectedTab
        self.oldSelectedTab = tabManager.selectedTab
        self.privateModeButton.setSelected(!isPrivate, animated: true)

        //if private tabs is empty and we are transitioning to it add a tab
        if tabManager.privateTabs.isEmpty  && !isPrivate {
            tabManager.addTab(isPrivate: true)
        }

        //get the tabs from which we will select which one to nominate for tribute (selection)
        //the isPrivate boolean still hasnt been flipped. (It'll be flipped in the BVC didSelectedTabChange method)
        let tabs = !isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let tab = oldSelectedTab, tabs.index(of: tab) != nil {
            tabManager.selectTab(tab)
        } else {
            tabManager.selectTab(tabs.last)
        }
    }
    
    func scrollToCurrentTab(_ animated: Bool = true, centerCell: Bool = false) {
        assertIsMainThread("Only animate on the main thread")

        guard let currentTab = tabManager.selectedTab, let index = tabStore.index(of: currentTab), !collectionView.frame.isEmpty else {
            return
        }
        if let frame = collectionView.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.frame {
            if centerCell {
                collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
            } else {
                // Padding is added to ensure the tab is completely visible (none of the tab is under the fader)
                let padFrame = frame.insetBy(dx: -(TopTabsUX.TopTabsBackgroundShadowWidth+TopTabsUX.FaderPading), dy: 0)
                if animated {
                    UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: { 
                        self.collectionView.scrollRectToVisible(padFrame, animated: true)
                    })
                } else {
                    collectionView.scrollRectToVisible(padFrame, animated: false)
                }
            }
        }
    }
}

@available(iOS 11.0, *)
extension TopTabsViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        // Prevent tabs from being dragged and dropped onto the "New Tab" button.
        if let localDragSession = session.localDragSession, let item = localDragSession.items.first, let _ = item.localObject as? Tab {
            return false
        }

        return session.canLoadObjects(ofClass: URL.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        _ = session.loadObjects(ofClass: URL.self) { urls in
            guard let url = urls.first else {
                return
            }

            self.tabManager.addTab(URLRequest(url: url), isPrivate: self.isPrivate)
        }
    }
}

extension TopTabsViewController: Themeable {
    func applyTheme(_ theme: Theme) {
        tabsButton.applyTheme(theme)
        tabsButton.titleBackgroundColor = view.backgroundColor ?? UIColor.Photon.Grey80
        tabsButton.textColor = UIColor.Photon.Grey40

        isPrivate = (theme == Theme.Private)
        privateModeButton.applyTheme(theme)
        privateModeButton.tintColor = UIColor.TopTabs.PrivateModeTint.colorFor(theme)
        privateModeButton.imageView?.tintColor = privateModeButton.tintColor
        newTab.tintColor = UIColor.Photon.Grey40
        collectionView.backgroundColor = view.backgroundColor
    }
}

extension TopTabsViewController: TopTabCellDelegate {
    func tabCellDidClose(_ cell: TopTabCell) {
        // Trying to remove tabs while animating can lead to crashes as indexes change. If updates are happening don't allow tabs to be removed.
        guard let index = collectionView.indexPath(for: cell)?.item else {
            return
        }
        let tab = tabStore[index]
        if tabsToDisplay.index(of: tab) != nil {
            tabManager.removeTab(tab)
        }
    }
}

extension TopTabsViewController: UICollectionViewDataSource {
    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        let tabCell = collectionView.dequeueReusableCell(withReuseIdentifier: TopTabCell.Identifier, for: indexPath) as! TopTabCell
        tabCell.delegate = self
        
        let tab = tabStore[index]
        tabCell.style = tab.isPrivate ? .dark : .light
        tabCell.titleText.text = tab.displayTitle
        
        if tab.displayTitle.isEmpty {
            if tab.webView?.url?.isLocalUtility ?? true {
                tabCell.titleText.text = Strings.AppMenuNewTabTitleString
            } else {
                tabCell.titleText.text = tab.webView?.url?.absoluteDisplayString
            }
            tabCell.accessibilityLabel = tab.url?.aboutComponent ?? ""
            tabCell.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tabCell.titleText.text ?? "")
        } else {
            tabCell.accessibilityLabel = tab.displayTitle
            tabCell.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tab.displayTitle)
        }

        tabCell.selectedTab = (tab == tabManager.selectedTab)
        if let siteURL = tab.url?.displayURL {
            tabCell.favicon.setIcon(tab.displayFavicon, forURL: siteURL, completed: { (color, url) in
                if siteURL == url {
                    tabCell.favicon.image = tabCell.favicon.image?.createScaled(CGSize(width: 15, height: 15))
                    tabCell.favicon.backgroundColor = color == .clear ? .white : color
                    tabCell.favicon.contentMode = .center
                }
            })
        } else {
            tabCell.favicon.image = UIImage(named: "defaultFavicon")
            tabCell.favicon.contentMode = .scaleAspectFit
            tabCell.favicon.backgroundColor = .clear
        }
        
        return tabCell
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabStore.count
    }

    @objc func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderFooter", for: indexPath) as! TopTabsHeaderFooter
        view.arrangeLine(kind)
        return view
    }
}

@available(iOS 11.0, *)
extension TopTabsViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        isDragging = true
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        isDragging = false
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore

        let tab = tabStore[indexPath.item]

        // Get the tab's current URL. If it is `nil`, check the `sessionData` since
        // it may be a tab that has not been restored yet.
        var url = tab.url
        if url == nil, let sessionData = tab.sessionData {
            let urls = sessionData.urls
            let index = sessionData.currentPage + urls.count - 1
            if index < urls.count {
                url = urls[index]
            }
        }

        // Ensure we actually have a URL for the tab being dragged and that the URL is not local.
        // If not, just create an empty `NSItemProvider` so we can create a drag item with the
        // `Tab` so that it can at still be re-ordered.
        var itemProvider: NSItemProvider
        if url != nil, !(url?.isLocal ?? true) {
            itemProvider = NSItemProvider(contentsOf: url) ?? NSItemProvider()
        } else {
            itemProvider = NSItemProvider()
        }

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = tab
        return [dragItem]
    }
}

@available(iOS 11.0, *)
extension TopTabsViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath, let dragItem = coordinator.items.first?.dragItem, let tab = dragItem.localObject as? Tab, let sourceIndex = tabStore.index(of: tab) else {
            return
        }

        coordinator.drop(dragItem, toItemAt: destinationIndexPath)
        isDragging = false

        self.tabManager.moveTab(isPrivate: self.isPrivate, fromIndex: sourceIndex, toIndex: destinationIndexPath.item)
        self.performTabUpdates()
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let localDragSession = session.localDragSession, let item = localDragSession.items.first, let tab = item.localObject as? Tab else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        // If the `isDragging` is not `true` by the time we get here, we've had other
        // add/remove operations happen while the drag was going on. We must return a
        // `.cancel` operation continuously until `isDragging` can be reset.
        guard tabStore.index(of: tab) != nil, isDragging else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension TopTabsViewController: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        let tab = tabStore[index]
        if tabsToDisplay.index(of: tab) != nil {
            tabManager.selectTab(tab)
        }
    }
}

extension TopTabsViewController: TabEventHandler {
    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {
        assertIsMainThread("UICollectionView changes can only be performed from the main thread")

        if tabStore.index(of: tab) != nil {
            needReloads.append(tab)
            performTabUpdates()
        }
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        assertIsMainThread("UICollectionView changes can only be performed from the main thread")

        if tabStore.index(of: tab) != nil {
            needReloads.append(tab)
            performTabUpdates()
        }
    }
}

// Collection Diff (animations)
extension TopTabsViewController {
    struct TopTabMoveChange: Hashable {
        let from: IndexPath
        let to: IndexPath

        var hashValue: Int {
            return from.hashValue + to.hashValue
        }

        // Consider equality when from/to are equal as well as swapped. This is because
        // moving a tab from index 2 to index 1 will result in TWO changes: 2 -> 1 and 1 -> 2
        // We only need to keep *one* of those two changes when dealing with a move.
        static func ==(lhs: TopTabsViewController.TopTabMoveChange, rhs: TopTabsViewController.TopTabMoveChange) -> Bool {
            return (lhs.from == rhs.from && lhs.to == rhs.to) || (lhs.from == rhs.to && lhs.to == rhs.from)
        }
    }

    struct TopTabChangeSet {
        let reloads: Set<IndexPath>
        let inserts: Set<IndexPath>
        let deletes: Set<IndexPath>
        let moves: Set<TopTabMoveChange>

        init(reloadArr: [IndexPath], insertArr: [IndexPath], deleteArr: [IndexPath], moveArr: [TopTabMoveChange]) {
            reloads = Set(reloadArr)
            inserts = Set(insertArr)
            deletes = Set(deleteArr)
            moves = Set(moveArr)
        }

        var isEmpty: Bool {
            return reloads.isEmpty && inserts.isEmpty && deletes.isEmpty && moves.isEmpty
        }
    }

    // create a TopTabChangeSet which is a snapshot of updates to perfrom on a collectionView
    func calculateDiffWith(_ oldTabs: [Tab], to newTabs: [Tab], and reloadTabs: [Tab?]) -> TopTabChangeSet {
        let inserts: [IndexPath] = newTabs.enumerated().compactMap { index, tab in
            if oldTabs.index(of: tab) == nil {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }

        let deletes: [IndexPath] = oldTabs.enumerated().compactMap { index, tab in
            if newTabs.index(of: tab) == nil {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }

        let moves: [TopTabMoveChange] = newTabs.enumerated().compactMap { newIndex, tab in
            if let oldIndex = oldTabs.index(of: tab), oldIndex != newIndex {
                return TopTabMoveChange(from: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
            }
            return nil
        }

        // Create based on what is visibile but filter out tabs we are about to insert/delete.
        let reloads: [IndexPath] = reloadTabs.compactMap { tab in
            guard let tab = tab, newTabs.index(of: tab) != nil else {
                return nil
            }
            return IndexPath(row: newTabs.index(of: tab)!, section: 0)
        }.filter { return inserts.index(of: $0) == nil && deletes.index(of: $0) == nil }

        return TopTabChangeSet(reloadArr: reloads, insertArr: inserts, deleteArr: deletes, moveArr: moves)
    }

    func updateTabsFrom(_ oldTabs: [Tab]?, to newTabs: [Tab], on completion: (() -> Void)? = nil) {
        assertIsMainThread("Updates can only be performed from the main thread")
        guard let oldTabs = oldTabs, !self.isUpdating, !self.pendingReloadData, !self.isDragging else {
            return
        }

        // Lets create our change set
        let update = self.calculateDiffWith(oldTabs, to: newTabs, and: needReloads)
        flushPendingChanges()

        // If there are no changes. We have nothing to do
        if update.isEmpty {
            completion?()
            return
        }

        // The actual update block. We update the dataStore right before we do the UI updates.
        let updateBlock = {
            self.tabStore = newTabs

            // Only consider moves if no other operations are pending.
            if update.deletes.count == 0, update.inserts.count == 0, update.reloads.count == 0 {
                for move in update.moves {
                    self.collectionView.moveItem(at: move.from, to: move.to)
                }
            } else {
                self.collectionView.deleteItems(at: Array(update.deletes))
                self.collectionView.insertItems(at: Array(update.inserts))
                self.collectionView.reloadItems(at: Array(update.reloads))
            }
        }

        //Lets lock any other updates from happening.
        self.isUpdating = true
        self.isDragging = false
        self.pendingUpdatesToTabs = newTabs // This var helps other mutations that might happen while updating.

        let onComplete: () -> Void = {
            self.isUpdating = false
            self.pendingUpdatesToTabs = []
            // Sometimes there might be a pending reload. Lets do that.
            if self.pendingReloadData {
                return self.reloadData()
            }

            // There can be pending animations. Run update again to clear them.
            let tabs = self.oldTabs ?? self.tabStore
            self.updateTabsFrom(tabs, to: self.tabsToDisplay, on: {
                if !update.inserts.isEmpty || !update.reloads.isEmpty {
                    self.scrollToCurrentTab()
                }
            })
        }

        // The actual update. Only animate the changes if no tabs have moved
        // as a result of drag-and-drop.
        if update.moves.count == 0 {
            UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
                self.collectionView.performBatchUpdates(updateBlock)
            }) { (_) in
                onComplete()
            }
        } else {
            self.collectionView.performBatchUpdates(updateBlock) { _ in
                onComplete()
            }
        }
    }

    fileprivate func flushPendingChanges() {
        oldTabs = nil
        needReloads.removeAll()
    }

    func reloadData() {
        assertIsMainThread("reloadData must only be called from main thread")

        if self.isUpdating || self.collectionView.frame == CGRect.zero {
            self.pendingReloadData = true
            return
        }

        isUpdating = true
        isDragging = false
        self.tabStore = self.tabsToDisplay
        self.newTab.isUserInteractionEnabled = false
        self.flushPendingChanges()
        UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            self.scrollToCurrentTab(true, centerCell: true)
        }, completion: { (_) in
            self.isUpdating = false
            self.pendingReloadData = false
            self.performTabUpdates()
            self.newTab.isUserInteractionEnabled = true
        }) 
    }
}

extension TopTabsViewController: TabManagerDelegate {

    // Because we don't know when we are about to transition to private mode
    // check to make sure that the tab we are trying to add is being added to the right tab group
    fileprivate func tabsMatchDisplayGroup(_ a: Tab?, b: Tab?) -> Bool {
        if let a = a, let b = b, a.isPrivate == b.isPrivate {
            return true
        }
        return false
    }

    func performTabUpdates() {
        guard !isUpdating, view.window != nil else {
            return
        }

        let fromTabs = !self.pendingUpdatesToTabs.isEmpty ? self.pendingUpdatesToTabs : self.oldTabs
        self.oldTabs = fromTabs ?? self.tabStore
        if self.pendingReloadData && !isUpdating {
            self.reloadData()
        } else {
            self.updateTabsFrom(self.oldTabs, to: self.tabsToDisplay)
        }
    }

    // This helps make sure animations don't happen before the view is loaded.
    fileprivate var isRestoring: Bool {
        return self.tabManager.isRestoring || self.collectionView.frame == CGRect.zero
    }

    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        if isRestoring {
            return
        }
        if !tabsMatchDisplayGroup(selected, b: previous) {
            self.reloadData()
        } else {
            self.needReloads.append(selected)
            self.needReloads.append(previous)
            performTabUpdates()
            delegate?.topTabsDidChangeTab()
        }
    }

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        if isRestoring || (tabManager.selectedTab != nil && !tabsMatchDisplayGroup(tab, b: tabManager.selectedTab)) {
            return
        }
        performTabUpdates()
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        if isRestoring {
            return
        }
        // If we deleted the last private tab. We'll be switching back to normal browsing. Pause updates till then
        if self.tabsToDisplay.isEmpty {
            self.pendingReloadData = true
            return
        }

        // dont want to hold a ref to a deleted tab
        if tab === oldSelectedTab {
            oldSelectedTab = nil
        }

        performTabUpdates()
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        self.reloadData()
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        self.reloadData()
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        self.reloadData()
    }
}
