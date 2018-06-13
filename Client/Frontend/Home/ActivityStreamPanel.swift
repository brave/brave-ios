/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Deferred
import Storage
import SDWebImage
import XCGLogger
import SnapKit

private let log = Logger.browserLogger
private let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"

// MARK: -  Lifecycle
struct ASPanelUX {
    static let backgroundColor = UIConstants.AppBackgroundColor
    static let rowSpacing: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20
    static let highlightCellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 200
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 14)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    static let SectionInsetsForIpad: CGFloat = 101
    static let SectionInsetsForIphone: CGFloat = 14
    static let MinimumInsets: CGFloat = 14
    static let BookmarkHighlights = 2

}
/*
 Size classes are the way Apple requires us to specify our UI.
 Split view on iPad can make a landscape app appear with the demensions of an iPhone app
 Use UXSizeClasses to specify things like offsets/itemsizes with respect to size classes
 For a primer on size classes https://useyourloaf.com/blog/size-classes/
 */
struct UXSizeClasses {
    var compact: CGFloat
    var regular: CGFloat
    var unspecified: CGFloat

    init(compact: CGFloat, regular: CGFloat, other: CGFloat) {
        self.compact = compact
        self.regular = regular
        self.unspecified = other
    }

    subscript(sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        switch sizeClass {
            case .compact:
                return self.compact
            case .regular:
                return self.regular
            case .unspecified:
                return self.unspecified
        }

    }
}

class ActivityStreamPanel: UICollectionViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    fileprivate let profile: Profile
    fileprivate let pocketAPI = Pocket()
    fileprivate let pocketVideoAPI = Pocket(endPoint: PocketVideoFeed)
    fileprivate let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()

    fileprivate let topSitesManager = ASHorizontalScrollCellManager()
    fileprivate var showHighlightIntro = false
    fileprivate var sessionStart: Timestamp?

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // Not used for displaying. Only used for calculating layout.
    lazy var topSiteCell: ASHorizontalScrollCell = {
        let customCell = ASHorizontalScrollCell(frame: CGRect(width: self.view.frame.size.width, height: 0))
        customCell.delegate = self.topSitesManager
        return customCell
    }()

    var highlights: [Site] = []
    var pocketStories: [PocketStory] = []
    var pocketVideoStories: [PocketStory] = []

    init(profile: Profile) {
        self.profile = profile

        super.init(collectionViewLayout: flowLayout)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self

        collectionView?.addGestureRecognizer(longPressRecognizer)

        let refreshEvents: [Notification.Name] = [.DynamicFontChanged, .HomePanelPrefsChanged]
        refreshEvents.forEach { NotificationCenter.default.addObserver(self, selector: #selector(reload), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Section.allValues.forEach { self.collectionView?.register(Section($0.rawValue).cellType, forCellWithReuseIdentifier: Section($0.rawValue).cellIdentifier) }
        self.collectionView?.register(ASHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        self.collectionView?.register(ASFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView?.backgroundColor = ASPanelUX.backgroundColor
        collectionView?.keyboardDismissMode = .onDrag
        
        self.profile.panelDataObservers.activityStream.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {context in
            //The AS context menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            self.collectionViewLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }, completion: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
    }

    @objc func reload(notification: Notification) {
        reloadAll()
    }
}

// MARK: -  Section management
extension ActivityStreamPanel {
    enum Section: Int {
        case topSites
        case pocketVideo
        case pocket
        case highlights
        case highlightIntro

        static let count = 5
        static let allValues = [topSites, pocketVideo, pocket, highlights, highlightIntro]

        var title: String? {
            switch self {
            case .highlights: return Strings.ASHighlightsTitle
            case .pocket: return Strings.ASPocketTitle
            case .pocketVideo: return Strings.ASPocketTitle
            case .topSites: return nil
            case .highlightIntro: return nil
            }
        }

        var headerHeight: CGSize {
            switch self {
            case .highlights, .pocket, .pocketVideo: return CGSize(width: 50, height: 40)
            case .topSites: return .zero
            case .highlightIntro: return CGSize(width: 50, height: 2)
            }
        }

        var footerHeight: CGSize {
            switch self {
            case .highlights, .highlightIntro, .pocket, .pocketVideo: return .zero
            case .topSites: return CGSize(width: 50, height: 5)
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .highlights, .pocket, .pocketVideo: return ASPanelUX.highlightCellHeight
            case .topSites: return 0 //calculated dynamically
            case .highlightIntro: return 200
            }
        }

        /*
         There are edge cases to handle when calculating section insets
        - An iPhone 7+ is considered regular width when in landscape
        - An iPad in 66% split view is still considered regular width
         */
        func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
            var currentTraits = traits
            if (traits.horizontalSizeClass == .regular && UIScreen.main.bounds.size.width != frameWidth) || UIDevice.current.userInterfaceIdiom == .phone {
                currentTraits = UITraitCollection(horizontalSizeClass: .compact)
            }
            switch self {
            case .highlights, .pocket, .pocketVideo:
                var insets = ASPanelUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]
                insets = insets + ASPanelUX.MinimumInsets
                return insets
            case .topSites:
                return ASPanelUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]
            case .highlightIntro:
                return ASPanelUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]
            }
        }

        func numberOfItemsForRow(_ traits: UITraitCollection) -> CGFloat {
            switch self {
            case .highlights, .pocket, .pocketVideo:
                var numItems: CGFloat = ASPanelUX.numberOfItemsPerRowForSizeClassIpad[traits.horizontalSizeClass]
                if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
                    numItems = numItems - 1
                }
                if traits.horizontalSizeClass == .compact && UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
                    numItems = numItems - 1
                }
                return numItems
            case .topSites, .highlightIntro:
                return 1
            }
        }

        func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
            let height = cellHeight(traits, width: frameWidth)
            let inset = sectionInsets(traits, frameWidth: frameWidth) * 2

            switch self {
            case .highlights, .pocket, .pocketVideo:
                let numItems = numberOfItemsForRow(traits)
                return CGSize(width: floor(((frameWidth - inset) - (ASPanelUX.MinimumInsets * (numItems - 1))) / numItems), height: height)
            case .topSites:
                return CGSize(width: frameWidth - inset, height: height)
            case .highlightIntro:
                return CGSize(width: frameWidth - inset - (ASPanelUX.MinimumInsets * 2), height: height)
            }
        }

        var headerView: UIView? {
            switch self {
            case .highlights, .highlightIntro, .pocket, .pocketVideo:
                let view = ASHeaderView()
                view.title = title
                return view
            case .topSites:
                return nil
            }
        }

        var cellIdentifier: String {
            switch self {
            case .topSites: return "TopSiteCell"
            case .highlights: return "HistoryCell"
            case .pocket, .pocketVideo: return "PocketCell"
            case .highlightIntro: return "HighlightIntroCell"
            }
        }

        var cellType: UICollectionViewCell.Type {
            switch self {
            case .topSites: return ASHorizontalScrollCell.self
            case .highlights, .pocket, .pocketVideo: return ActivityStreamHighlightCell.self
            case .highlightIntro: return HighlightIntroCell.self
            }
        }

        init(at indexPath: IndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        init(_ section: Int) {
            self.init(rawValue: section)!
        }
    }
}

// MARK: -  Tableview Delegate
extension ActivityStreamPanel: UICollectionViewDelegateFlowLayout {

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
            case UICollectionElementKindSectionHeader:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
                let title = Section(indexPath.section).title
                switch Section(indexPath.section) {
                case .highlights, .highlightIntro:
                    view.title = title
                    return view
                case .pocketVideo:
                    if !self.pocketVideoStories.isEmpty {
                        view.title = title
                        view.moreButton.isHidden = false
                        view.moreButton.addTarget(self, action: #selector(showMorePocketStories), for: .touchUpInside)
                    }
                    return view
                case .pocket:
                    if self.pocketVideoStories.isEmpty {
                        view.title = title
                        view.moreButton.isHidden = false
                        view.moreButton.addTarget(self, action: #selector(showMorePocketStories), for: .touchUpInside)
                    }
                    return view
                case .topSites:
                    return UICollectionReusableView()
            }
            case UICollectionElementKindSectionFooter:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "Footer", for: indexPath) as! ASFooterView
                switch Section(indexPath.section) {
                case .highlights, .highlightIntro:
                    return UICollectionReusableView()
                case .topSites, .pocket, .pocketVideo:
                    return view
            }
            default:
                return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.longPressRecognizer.isEnabled = false
        selectItemAtIndex(indexPath.item, inSection: Section(indexPath.section))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = Section(indexPath.section).cellSize(for: self.traitCollection, frameWidth: self.view.frame.width)

        switch Section(indexPath.section) {
        case .highlights:
            if highlights.isEmpty {
                return .zero
            }
            return cellSize
        case .topSites:
            // Create a temporary cell so we can calculate the height.
            let layout = topSiteCell.collectionView.collectionViewLayout as! HorizontalFlowLayout
            let estimatedLayout = layout.calculateLayout(for: CGSize(width: cellSize.width, height: 0))
            return CGSize(width: cellSize.width, height: estimatedLayout.size.height)
        case .highlightIntro, .pocket, .pocketVideo:
            return cellSize
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch Section(section) {
        case .highlights:
            return highlights.isEmpty ? .zero : CGSize(width: self.view.frame.size.width, height: Section(section).headerHeight.height)
        case .highlightIntro:
            return !highlights.isEmpty ? .zero : CGSize(width: self.view.frame.size.width, height: Section(section).headerHeight.height)
        case .pocketVideo:
            return pocketVideoStories.isEmpty ? .zero : Section(section).headerHeight
        case .pocket:
            return (pocketStories.isEmpty || !pocketVideoStories.isEmpty) ? .zero : Section(section).headerHeight
        case .topSites:
            return Section(section).headerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch Section(section) {
        case .highlights, .highlightIntro, .pocket, .pocketVideo:
            return .zero
        case .topSites:
            return Section(section).footerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return ASPanelUX.rowSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let insets = Section(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
        return UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)
    }

    fileprivate func showSiteWithURLHandler(_ url: URL) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(self, didSelectURL: url, visitType: visitType)
    }
}

// MARK: - Tableview Data Source
extension ActivityStreamPanel {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numItems: CGFloat = ASPanelUX.numberOfItemsPerRowForSizeClassIpad[self.traitCollection.horizontalSizeClass]
        if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
            numItems = numItems - 1
        }
        if self.traitCollection.horizontalSizeClass == .compact && UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            numItems = numItems - 1
        }
        switch Section(section) {
        case .topSites:
            return topSitesManager.content.isEmpty ? 0 : 1
        case .highlights:
            return self.highlights.count
        case .pocket:
            return pocketStories.isEmpty ? 0 : Int(numItems)
        case .pocketVideo:
            return pocketVideoStories.isEmpty ? 0 : Int(numItems)
        case .highlightIntro:
            return self.highlights.isEmpty && showHighlightIntro && isHighlightsEnabled() ? 1 : 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)

        switch Section(indexPath.section) {
        case .topSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .highlights:
            return configureHistoryItemCell(cell, forIndexPath: indexPath)
        case .pocket:
            return configurePocketItemCell(cell, forIndexPath: indexPath)
        case .pocketVideo:
            return configurePocketVideoItemCell(cell, forIndexPath: indexPath)
        case .highlightIntro:
            return configureHighlightIntroCell(cell, forIndexPath: indexPath)
        }
    }

    //should all be collectionview
    func configureTopSitesCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        topSiteCell.setNeedsLayout()
        topSiteCell.collectionView.reloadData()
        topSiteCell.moveToInitialPage()
        return cell
    }

    func configureHistoryItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let site = highlights[indexPath.row]
        let simpleHighlightCell = cell as! ActivityStreamHighlightCell
        simpleHighlightCell.configureWithSite(site)
        return simpleHighlightCell
    }
    
    func configurePocketItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let pocketStory = pocketStories[indexPath.row]
        let pocketItemCell = cell as! ActivityStreamHighlightCell
        pocketItemCell.configureWithPocketStory(pocketStory)
        return pocketItemCell
    }

    func configurePocketVideoItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let pocketStory = pocketVideoStories[indexPath.row]
        let pocketItemCell = cell as! ActivityStreamHighlightCell
        pocketItemCell.configureWithPocketVideoStory(pocketStory)
        return pocketItemCell
    }

    func configureHighlightIntroCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let introCell = cell as! HighlightIntroCell
        //The cell is configured on creation. No need to configure. But leave this here in case we need it.
        return introCell
    }
}

// MARK: - Data Management
extension ActivityStreamPanel: DataObserverDelegate {

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    func reloadAll() {
        // If the pocket stories are not availible for the Locale the PocketAPI will return nil
        // So it is okay if the default here is true
        self.getPocketSites().both(self.getPocketVideos()).uponQueue(.main) { _ in
            if !self.pocketStories.isEmpty {
                self.collectionView?.reloadData()
            }
        }

        accumulate([self.getHighlights, self.getTopSites]).uponQueue(.main) { _ in
            // If there is no pending cache update and highlights are empty. Show the onboarding screen
            self.showHighlightIntro = self.highlights.isEmpty
            self.collectionView?.reloadData()

            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: false, forceTopSites: false)
        }
    }

    func getBookmarksForHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let count = ASPanelUX.BookmarkHighlights // Fetch 2 bookmarks
        return self.profile.recommendations.getRecentBookmarks(count)
    }

    // Used to check if the entire section is turned off
    // when it is we shouldnt show the emtpy state
    func isHighlightsEnabled() -> Bool {
        let bookmarks = profile.prefs.boolForKey(PrefsKeys.ASBookmarkHighlightsVisible) ?? false
        let history = profile.prefs.boolForKey(PrefsKeys.ASRecentHighlightsVisible) ?? false
        return history && bookmarks
    }

    func getHighlights() -> Success {
        var queries: [() -> Deferred<Maybe<Cursor<Site>>>] = []
        if profile.prefs.boolForKey(PrefsKeys.ASBookmarkHighlightsVisible) ?? true {
            queries.append(getBookmarksForHighlights)
        }

        if profile.prefs.boolForKey(PrefsKeys.ASRecentHighlightsVisible) ?? true {
            queries.append(self.profile.recommendations.getHighlights)
        }

        guard !queries.isEmpty else {
            self.highlights = []
            return succeed()
        }

        return accumulate(queries).bindQueue(.main) { result in
            guard let resultArr = result.successValue else {
                return succeed()
            }
            let sites = resultArr.reduce([]) { $0 + $1.asArray() }

            self.highlights = sites
            return succeed()
        }
    }

    func getPocketSites() -> Success {
        let showPocket = (profile.prefs.boolForKey(PrefsKeys.ASPocketStoriesVisible) ?? Pocket.IslocaleSupported(Locale.current.identifier))
        guard showPocket else {
            self.pocketStories = []
            return succeed()
        }

        return pocketAPI.globalFeed(items: 4).bindQueue(.main) { pStory in
            self.pocketStories = pStory
            return succeed()
        }
    }

    func getPocketVideos() -> Success {
        let showPocket = (profile.prefs.boolForKey(PrefsKeys.ASPocketStoriesVisible) ?? Pocket.IslocaleSupported(Locale.current.identifier))
        guard showPocket else {
            self.pocketVideoStories = []
            return succeed()
        }

        return pocketVideoAPI.globalFeed(items: 4).bindQueue(.main) { pStory in
            self.pocketVideoStories = pStory
            return succeed()
        }
    }

    @objc func showMorePocketStories() {
        showSiteWithURLHandler(Pocket.MoreStoriesURL)
    }

    func getTopSites() -> Success {
        return self.profile.history.getTopSitesWithLimit(16).both(self.profile.history.getPinnedTopSites()).bindQueue(.main) { (topsites, pinnedSites) in
            guard let mySites = topsites.successValue?.asArray(), let pinned = pinnedSites.successValue?.asArray() else {
                return succeed()
            }

            // How sites are merged together. We compare against the url's base domain. example m.youtube.com is compared against `youtube.com`
            let unionOnURL = { (site: Site) -> String in
                return URL(string: site.url)?.baseDomain ?? ""
            }

            // Fetch the default sites
            let defaultSites = self.defaultTopSites()
            // create PinnedSite objects. used by the view layer to tell topsites apart
            let pinnedSites: [Site] = pinned.map({ PinnedSite(site: $0) })

            // Merge default topsites with a user's topsites.
            let mergedSites = mySites.union(defaultSites, f: unionOnURL)
            // Merge pinnedSites with sites from the previous step
            let allSites = pinnedSites.union(mergedSites, f: unionOnURL)

            // Favour topsites from defaultSites as they have better favicons. But keep PinnedSites
            let newSites = allSites.map { site -> Site in
                if let _ = site as? PinnedSite {
                    return site
                }
                let domain = URL(string: site.url)?.hostSLD
                return defaultSites.find { $0.title.lowercased() == domain } ?? site
            }

            self.topSitesManager.currentTraits = self.view.traitCollection

            if newSites.count > Int(ActivityStreamTopSiteCacheSize) {
                self.topSitesManager.content = Array(newSites[0..<Int(ActivityStreamTopSiteCacheSize)])
            } else {
                self.topSitesManager.content = newSites
            }

            self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
                self.longPressRecognizer.isEnabled = false
                self.showSiteWithURLHandler(url as URL)
            }

            return succeed()
        }
    }

    // Invoked by the ActivityStreamDataObserver when highlights/top sites invalidation is complete.
    func didInvalidateDataSources(refresh forced: Bool, highlightsRefreshed: Bool, topSitesRefreshed: Bool) {
        // Do not reload panel unless we're currently showing the highlight intro or if we
        // force-reloaded the highlights or top sites. This should prevent reloading the
        // panel after we've invalidated in the background on the first load.
        if showHighlightIntro || forced {
            reloadAll()
        }
    }

    func hideURLFromTopSites(_ site: Site) {
        guard let host = site.tileURL.normalizedHost else {
            return
        }
        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if defaultTopSites().filter({$0.url == url}).isEmpty == false {
            deleteTileForSuggestedSite(url)
        }
        profile.history.removeHostFromTopSites(host).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: false, forceTopSites: true)
        }
    }

    func pinTopSite(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: false, forceTopSites: true)
        }
    }

    func removePinTopSite(_ site: Site) {
        profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: false, forceTopSites: true)
        }
    }

    func hideFromHighlights(_ site: Site) {
        profile.recommendations.removeHighlightForURL(site.url).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: true, forceTopSites: false)
        }
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.index(of: $0.url) == .none})
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: self.collectionView)
        guard let indexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        switch Section(indexPath.section) {
        case .highlights, .pocket, .pocketVideo:
            presentContextMenu(for: indexPath)
        case .topSites:
            let topSiteCell = self.collectionView?.cellForItem(at: indexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            presentContextMenu(for: topSiteIndexPath)
        case .highlightIntro:
            break
        }
    }

    fileprivate func fetchBookmarkStatus(for site: Site, with indexPath: IndexPath, forSection section: Section, completionHandler: @escaping () -> Void) {
        profile.bookmarks.modelFactory >>== {
            $0.isBookmarked(site.url).uponQueue(.main) { result in
                guard let isBookmarked = result.successValue else {
                    log.error("Error getting bookmark status: \(result.failureValue ??? "nil").")
                    return
                }
                site.setBookmarked(isBookmarked)
                completionHandler()
            }
        }
    }

    func selectItemAtIndex(_ index: Int, inSection section: Section) {
        let site: Site?
        switch section {
        case .highlights:
            site = self.highlights[index]
        case .pocket:
            site = Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
            let params = ["Source": "Activity Stream", "StoryType": "Article"]
        case .pocketVideo:
            site = Site(url: pocketVideoStories[index].url.absoluteString, title: pocketVideoStories[index].title)
            let params = ["Source": "Activity Stream", "StoryType": "Video"]
        case .topSites, .highlightIntro:
            return
        }
        if let site = site {
            showSiteWithURLHandler(URL(string: site.url)!)
        }
    }
}

extension ActivityStreamPanel: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {

        fetchBookmarkStatus(for: site, with: indexPath, forSection: Section(indexPath.section)) {
            guard let contextMenu = completionHandler() else { return }
            self.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        switch Section(indexPath.section) {
        case .highlights:
            return highlights[indexPath.row]
        case .pocket:
            return Site(url: pocketStories[indexPath.row].dedupeURL.absoluteString, title: pocketStories[indexPath.row].title)
        case .pocketVideo:
            return Site(url: pocketVideoStories[indexPath.row].dedupeURL.absoluteString, title: pocketVideoStories[indexPath.row].title)
        case .topSites:
            return topSitesManager.content[indexPath.item]
        case .highlightIntro:
            return nil
        }
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let index: Int
        var sourceView: UIView?
        
        switch Section(indexPath.section) {
        case .topSites:
            index = indexPath.item
            if let topSiteCell = self.collectionView?.cellForItem(at: IndexPath(row: 0, section: 0)) as? ASHorizontalScrollCell {
                sourceView = topSiteCell.collectionView.cellForItem(at: indexPath)
            }
        case .highlights:
            index = indexPath.row
            sourceView = self.collectionView?.cellForItem(at: indexPath)
        case .pocket, .pocketVideo:
            index = indexPath.item
            sourceView = self.collectionView?.cellForItem(at: indexPath)
        case .highlightIntro:
            return nil
        }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { action in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            let source = ["Source": "Activity Stream Long Press Context Menu"]
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { action in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }
        
        let bookmarkAction: PhotonActionSheetItem
        if site.bookmarked ?? false {
            bookmarkAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { action in
                self.profile.bookmarks.modelFactory >>== {
                    $0.removeByURL(siteURL.absoluteString).uponQueue(.main) {_ in
                        self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: true, forceTopSites: false)
                    }
                    site.setBookmarked(false)
                }
            })
        } else {
            bookmarkAction = PhotonActionSheetItem(title: Strings.BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { action in
                let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
                _ = self.profile.bookmarks.shareItem(shareItem)
                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                    withUserData: userData,
                                                                                    toApplication: .shared)
                site.setBookmarked(true)
                self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: true, forceTopSites: true)
            })
        }

        let deleteFromHistoryAction = PhotonActionSheetItem(title: Strings.DeleteFromHistoryContextMenuTitle, iconString: "action_delete", handler: { action in
            self.profile.history.removeHistoryForURL(site.url).uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceHighlights: true, forceTopSites: true)
            }
        })

        let shareAction = PhotonActionSheetItem(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { action in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil)
            let controller = helper.createActivityViewController { completed, activityType in
            }
            if UI_USER_INTERFACE_IDIOM() == .pad, let popoverController = controller.popoverPresentationController {
                let cellRect = sourceView?.frame ?? .zero
                let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width/2, y: cellFrameInSuperview.height/2), size: .zero)
                popoverController.permittedArrowDirections = [.up, .down, .left]
                popoverController.delegate = self
            }
            self.present(controller, animated: true, completion: nil)
        })

        let removeTopSiteAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "action_remove", handler: { action in
            self.hideURLFromTopSites(site)
        })

        let dismissHighlightAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "action_remove", handler: { action in
            self.hideFromHighlights(site)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { action in
            self.pinTopSite(site)
        })

        let removePinTopSite = PhotonActionSheetItem(title: Strings.RemovePinTopsiteActionTitle, iconString: "action_unpin", handler: { action in
            self.removePinTopSite(site)
        })

        let topSiteActions: [PhotonActionSheetItem]
        if let _ = site as? PinnedSite {
            topSiteActions = [removePinTopSite]
        } else {
            topSiteActions = [pinTopSite, removeTopSiteAction]
        }

        var actions = [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]

        switch Section(indexPath.section) {
            case .highlights: actions.append(contentsOf: [dismissHighlightAction, deleteFromHistoryAction])
            case .pocket, .pocketVideo: break
            case .topSites: actions.append(contentsOf: topSiteActions)
            case .highlightIntro: break
        }
        return actions
    }
}

extension ActivityStreamPanel: UIPopoverPresentationControllerDelegate {

    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }
}

// MARK: - Section Header View
private struct ASHeaderViewUX {
    static let SeperatorColor =  UIColor.Photon.Grey20
    static let TextFont = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
    static let SeperatorHeight = 1
    static let Insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? ASPanelUX.SectionInsetsForIpad + ASPanelUX.MinimumInsets : ASPanelUX.MinimumInsets
    static let TitleTopInset: CGFloat = 5
}

class ASFooterView: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        let seperatorLine = UIView()
        seperatorLine.backgroundColor = ASHeaderViewUX.SeperatorColor
        self.backgroundColor = UIColor.clear
        addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints { make in
            make.height.equalTo(ASHeaderViewUX.SeperatorHeight)
            make.leading.equalTo(self.snp.leading)
            make.trailing.equalTo(self.snp.trailing)
            make.top.equalTo(self.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ASHeaderView: UICollectionReusableView {
    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.Photon.Grey50
        titleLabel.font = ASHeaderViewUX.TextFont
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.PocketMoreStoriesText, for: .normal)
        button.isHidden = true
        button.titleLabel?.font = ASHeaderViewUX.TextFont
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        return button
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var leftConstraint: Constraint?
    var rightConstraint: Constraint?

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? ASHeaderViewUX.Insets : ASPanelUX.MinimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(self).inset(ASHeaderViewUX.TitleTopInset)
            make.bottom.equalTo(self)
            self.rightConstraint = make.trailing.equalTo(self).inset(-titleInsets).constraint
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            self.leftConstraint = make.leading.equalTo(self).inset(titleInsets).constraint
            make.trailing.equalTo(moreButton.snp.leading).inset(-ASHeaderViewUX.TitleTopInset)
            make.top.equalTo(self).inset(ASHeaderViewUX.TitleTopInset)
            make.bottom.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftConstraint?.update(offset: titleInsets)
        rightConstraint?.update(offset: -titleInsets)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class PinnedSite: Site {
    let isPinnedSite = true

    init(site: Site) {
        super.init(url: site.url, title: site.title, bookmarked: site.bookmarked)
        self.icon = site.icon
        self.metadata = site.metadata
    }

}
