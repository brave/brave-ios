/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import BraveShared

private enum SearchListSection: Int, CaseIterable {
    case searchSuggestions
    case findInPage
    case bookmarksAndHistory
}

private struct SearchViewControllerUX {
    static let searchEngineScrollViewBackgroundColor = UIColor.Photon.white100.withAlphaComponent(0.8).cgColor
    static let searchEngineScrollViewBorderColor = UIColor.black.withAlphaComponent(0.2).cgColor

    // TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
    static let engineButtonHeight: Float = 44
    static let engineButtonWidth = engineButtonHeight * 1.4
    static let engineButtonBackgroundColor = UIColor.clear.cgColor

    static let searchEngineTopBorderWidth = 0.5
    static let searchImageHeight: Float = 44
    static let searchImageWidth: Float = 24

    static let suggestionBackgroundColor = UIColor.Photon.white100
    static let suggestionBorderColor = UIConstants.highlightBlue
    static let suggestionBorderWidth: CGFloat = 1
    static let suggestionCornerRadius: CGFloat = 4
    static let suggestionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    static let suggestionMargin: CGFloat = 8
    static let suggestionCellVerticalPadding: CGFloat = 10
    static let suggestionCellMaxRows = 2

    static let iconSize: CGFloat = 23
    static let faviconSize: CGFloat = 29
    static let iconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let iconBorderWidth: CGFloat = 0.5
}

protocol SearchViewControllerDelegate: class {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL)
    func searchViewController(_ searchViewController: SearchViewController, didLongPressSuggestion suggestion: String)
    func presentSearchSettingsController()
    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool)
    func searchViewController(_ searchViewController: SearchViewController, shouldFindInPage query: String)
    func searchViewControllerAllowFindInPage() -> Bool
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener {
    var searchDelegate: SearchViewControllerDelegate?

    private let tabType: TabType
    private var suggestClient: SearchSuggestClient?

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    private let searchEngineScrollView = ButtonScrollView()
    private let searchEngineScrollViewContent = UIView()

    private lazy var bookmarkedBadge: UIImage = {
        return #imageLiteral(resourceName: "bookmarked_passive")
    }()

    // Cell for the suggestion flow layout. Since heightForHeaderInSection is called *before*
    // cellForRowAtIndexPath, we create the cell to find its height before it's added to the table.
    private let suggestionCell = SuggestionCell(style: .default, reuseIdentifier: nil)
    private var suggestionPrompt: SearchSuggestionPromptView?
    
    static var userAgent: String?

    init(forTabType tabType: TabType) {
        self.tabType = tabType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blur)

        super.viewDidLoad()
        setupSearchEngineScrollViewIfNeeded()

        KeyboardHelper.defaultHelper.addDelegate(self)

        blur.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        suggestionCell.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .dynamicFontChanged, object: nil)
    }

    @objc func dynamicFontChanged(_ notification: Notification) {
        if notification.name == .dynamicFontChanged {
            reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSearchEngines()
        reloadData()
    }
    
    private func setupSearchEngineScrollViewIfNeeded() {
        if !hasQuickSearchEngines { return }

        searchEngineScrollView.layer.shadowRadius = 0
        searchEngineScrollView.layer.shadowOpacity = 100
        searchEngineScrollView.layer.shadowOffset = CGSize(width: 0, height: -SearchViewControllerUX.searchEngineTopBorderWidth)
        searchEngineScrollView.layer.shadowColor = SearchViewControllerUX.searchEngineScrollViewBorderColor
        searchEngineScrollView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        view.addSubview(searchEngineScrollView)

        searchEngineScrollViewContent.layer.backgroundColor = UIColor.clear.cgColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        layoutTable()
        layoutSearchEngineScrollView()

        searchEngineScrollViewContent.snp.makeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priority(10)
            // Left-align the engines on iphones, center on ipad
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                make.left.equalTo(self.searchEngineScrollView).priority(1000)
            } else {
                make.left.greaterThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            }
            make.bottom.right.top.equalTo(self.searchEngineScrollView)
        }
    }

    private func layoutSearchEngineScrollView() {
        if !hasQuickSearchEngines { return }
        
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
        searchEngineScrollView.snp.remakeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-keyboardHeight)
            make.height.equalTo(SearchViewControllerUX.engineButtonHeight)
        }
    }
    
    var searchEngines: SearchEngines! {
        didSet {
            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            // Show the default search engine first.
            if !tabType.isPrivate {
                let ua = SearchViewController.userAgent ?? "FxSearch"
                suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine(), userAgent: ua)
            }

            // Reload the footer list of search engines.
            reloadSearchEngines()
            
            layoutSuggestionsOptInPrompt()
        }
    }

    private var quickSearchEngines: [OpenSearchEngine] {
        var engines = searchEngines.quickSearchEngines

        // If we're not showing search suggestions, the default search engine won't be visible
        // at the top of the table. Show it with the others in the bottom search bar.
        if tabType.isPrivate || !searchEngines.shouldShowSearchSuggestions {
            engines?.insert(searchEngines.defaultEngine(), at: 0)
        }

        return engines!
    }
    
    // If the user only has a single quick search engine, it is also their default one.
    // In that case, we count it as if there are no quick suggestions to show.
    private var hasQuickSearchEngines: Bool {
        return quickSearchEngines.count > 1
    }
    
    private func layoutSuggestionsOptInPrompt() {
        if tabType.isPrivate || !searchEngines.shouldShowSearchSuggestionsOptIn {
            // Make sure any pending layouts are drawn so they don't get coupled
            // with the "slide up" animation below.
            view.layoutIfNeeded()
            
            // Set the prompt to nil so layoutTable() aligns the top of the table
            // to the top of the view. We still need a reference to the prompt so
            // we can remove it from the controller after the animation is done.
            let prompt = suggestionPrompt
            suggestionPrompt = nil
            layoutTable()
            
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.view.layoutIfNeeded()
                            prompt?.alpha = 0
            },
                           completion: { _ in
                            prompt?.removeFromSuperview()
                            return
            })
            return
        }
        
        let prompt = SearchSuggestionPromptView() { [unowned self] option in
            self.searchEngines.shouldShowSearchSuggestions = option
            self.searchEngines.shouldShowSearchSuggestionsOptIn = false
            if option {
                self.querySuggestClient()
            }
            self.layoutSuggestionsOptInPrompt()
            self.reloadSearchEngines()
        }
        // Insert behind the tableView so the tableView slides on top of it
        // when the prompt is dismissed.
        view.addSubview(prompt)
        suggestionPrompt = prompt
        
        prompt.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailing)
        }
        
        layoutTable()
    }

    var searchQuery: String = "" {
        didSet {
            // Reload the tableView to show the updated text in each engine.
            reloadData()
        }
    }

    override func reloadData() {
        querySuggestClient()
    }

    private func layoutTable() {
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(self.suggestionPrompt?.snp.bottom ?? self.view.snp.top)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(hasQuickSearchEngines ? self.searchEngineScrollView.snp.top : self.view)
        }
    }

    private func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.snp.left

        //search settings icon
        let searchButton = UIButton()
        searchButton.setImage(#imageLiteral(resourceName: "quickSearch"), for: [])
        searchButton.imageView?.contentMode = .center
        searchButton.layer.backgroundColor = SearchViewControllerUX.engineButtonBackgroundColor
        searchButton.addTarget(self, action: #selector(didClickSearchButton), for: .touchUpInside)
        searchButton.accessibilityLabel = Strings.searchSettingsButtonTitle

        searchButton.imageView?.snp.makeConstraints { make in
            make.width.height.equalTo(SearchViewControllerUX.searchImageWidth)
            return
        }

        searchEngineScrollViewContent.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.size.equalTo(SearchViewControllerUX.faviconSize)
            //offset the left edge to align with search results
            make.left.equalTo(leftEdge).offset(SearchViewControllerUX.suggestionMargin * 2)
            make.top.equalTo(self.searchEngineScrollViewContent).offset(SearchViewControllerUX.suggestionMargin)
            make.bottom.equalTo(self.searchEngineScrollViewContent).offset(-SearchViewControllerUX.suggestionMargin)
        }

        //search engines
        leftEdge = searchButton.snp.right
        for engine in quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, for: [])
            engineButton.imageView?.contentMode = .scaleAspectFit
            engineButton.layer.backgroundColor = SearchViewControllerUX.engineButtonBackgroundColor
            engineButton.addTarget(self, action: #selector(didSelectEngine), for: .touchUpInside)
            engineButton.accessibilityLabel = String(format: Strings.searchEngineFormatText, engine.shortName)

            engineButton.imageView?.snp.makeConstraints { make in
                make.width.height.equalTo(SearchViewControllerUX.faviconSize)
                return
            }

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp.makeConstraints { make in
                make.width.equalTo(SearchViewControllerUX.engineButtonWidth)
                make.left.equalTo(leftEdge)
                make.top.equalTo(self.searchEngineScrollViewContent)
                make.bottom.equalTo(self.searchEngineScrollViewContent)
                if engine === self.searchEngines.quickSearchEngines.last {
                    make.right.equalTo(self.searchEngineScrollViewContent)
                }
            }
            leftEdge = engineButton.snp.right
        }
    }

    @objc func didSelectEngine(_ sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines.
        // Subtract 1 from index to account for magnifying glass accessory.
        guard let index = searchEngineScrollViewContent.subviews.firstIndex(of: sender) else {
            assertionFailure()
            return
        }

        let engine = quickSearchEngines[index - 1]

        guard let url = engine.searchURLForQuery(searchQuery) else {
            assertionFailure()
            return
        }

        searchDelegate?.searchViewController(self, didSelectURL: url)
    }

    @objc func didClickSearchButton() {
        self.searchDelegate?.presentSearchSettingsController()  
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // The height of the suggestions row may change, so call reloadData() to recalculate cell heights.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        }, completion: nil)
    }

    private func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
        layoutSearchEngineScrollView()

        UIView.animate(withDuration: keyboardState.animationDuration, animations: {
            UIView.setAnimationCurve(keyboardState.animationCurve)
            self.view.layoutIfNeeded()
        })
    }

    private func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty || !searchEngines.shouldShowSearchSuggestions || searchQuery.looksLikeAURL() {
            suggestionCell.suggestions = []
            return
        }

        suggestClient?.query(searchQuery, callback: { suggestions, error in
            if let error = error {
                let isSuggestClientError = error.domain == SearchSuggestClientErrorDomain

                switch error.code {
                case NSURLErrorCancelled where error.domain == NSURLErrorDomain:
                    // Request was cancelled. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidEngine where isSuggestClientError:
                    // Engine does not support search suggestions. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidResponse where isSuggestClientError:
                    print("Error: Invalid search suggestion data")
                default:
                    print("Error: \(error.description)")
                }
            } else {
                self.suggestionCell.suggestions = suggestions!
            }

            // If there are no suggestions, just use whatever the user typed.
            if suggestions?.isEmpty ?? true {
                self.suggestionCell.suggestions = [self.searchQuery]
            }

            // Reload the tableView to show the new list of search suggestions.
            self.tableView.reloadData()
        })
    }

    func loader(dataLoaded data: [Site]) {
        self.data = Array(data.prefix(5))
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = SearchListSection(rawValue: indexPath.section)!
        if section == SearchListSection.bookmarksAndHistory {
            let site = data[indexPath.row]
            if let url = URL(string: site.url) {
                searchDelegate?.searchViewController(self, didSelectURL: url)
            }
        } else if section == SearchListSection.findInPage {
            searchDelegate?.searchViewController(self, shouldFindInPage: searchQuery)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let currentSection = SearchListSection(rawValue: indexPath.section) {
            switch currentSection {
            case .searchSuggestions:
                // heightForRowAtIndexPath is called *before* the cell is created, so to get the height,
                // force a layout pass first.
                suggestionCell.layoutIfNeeded()
                return suggestionCell.frame.height
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }

        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let searchSection = SearchListSection(rawValue: section) else { return nil }
        
        switch searchSection {
        case .searchSuggestions: return nil
        case .findInPage: return Strings.findOnPageSectionHeader
        case .bookmarksAndHistory: return Strings.searchHistorySectionHeader
        }
        
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let searchSection = SearchListSection(rawValue: section) else { return 0 }
        let headerHeight: CGFloat = 22
        
        switch searchSection {
        case .findInPage:
            if let sd = searchDelegate, sd.searchViewControllerAllowFindInPage() {
                return headerHeight
            }
            return 0
        case .bookmarksAndHistory: return data.isEmpty ? 0 : headerHeight
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SearchListSection(rawValue: indexPath.section)! {
        case .searchSuggestions:
            suggestionCell.imageView?.image = searchEngines.defaultEngine().image
            suggestionCell.imageView?.isAccessibilityElement = true
            suggestionCell.imageView?.accessibilityLabel = String(format: Strings.searchSuggestionFromFormatText, searchEngines.defaultEngine().shortName)
            return suggestionCell
            
        case .findInPage:
            let cell = TwoLineTableViewCell()
            cell.textLabel?.text = String(format: Strings.findInPageFormat, searchQuery)
            cell.imageView?.image = #imageLiteral(resourceName: "search_bar_find_in_page_icon")
            cell.imageView?.contentMode = .center
            
            return cell

        case .bookmarksAndHistory:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            let site = data[indexPath.row]
            if let cell = cell as? TwoLineTableViewCell {
                let isBookmark = site.bookmarked ?? false
                cell.setLines(site.title, detailText: site.url)
                cell.setRightBadge(isBookmark ? self.bookmarkedBadge : nil)
                cell.imageView?.contentMode = .scaleAspectFit
                cell.imageView?.layer.borderColor = SearchViewControllerUX.iconBorderColor.cgColor
                cell.imageView?.layer.borderWidth = SearchViewControllerUX.iconBorderWidth
                cell.imageView?.image = UIImage()
                cell.imageView?.loadFavicon(for: site.tileURL)
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            return searchEngines.shouldShowSearchSuggestions && !searchQuery.looksLikeAURL() && !tabType.isPrivate ? 1 : 0
        case .bookmarksAndHistory:
            return data.count
        case .findInPage:
            if let sd = searchDelegate, sd.searchViewControllerAllowFindInPage() {
                return 1
            }
            return 0
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return SearchListSection.allCases.count
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let section = SearchListSection(rawValue: indexPath.section) else {
            return
        }

        if section == .bookmarksAndHistory {
            let suggestion = data[indexPath.item]
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url, search: false)
        }
    }
}

extension SearchViewController {
    func handleKeyCommands(sender: UIKeyCommand) {
        let initialSection = SearchListSection.bookmarksAndHistory.rawValue
        guard let current = tableView.indexPathForSelectedRow else {
            let count = tableView(tableView, numberOfRowsInSection: initialSection)
            if sender.input == UIKeyCommand.inputDownArrow, count > 0 {
                let next = IndexPath(item: 0, section: initialSection)
                self.tableView(tableView, didHighlightRowAt: next)
                tableView.selectRow(at: next, animated: false, scrollPosition: .top)
            }
            return
        }

        let nextSection: Int
        let nextItem: Int
        guard let input = sender.input else { return }
        switch input {
        case UIKeyCommand.inputUpArrow:
            // we're going down, we should check if we've reached the first item in this section.
            if current.item == 0 {
                // We have, so check if we can decrement the section.
                if current.section == initialSection {
                    // We've reached the first item in the first section.
                    searchDelegate?.searchViewController(self, didHighlightText: searchQuery, search: false)
                    return
                } else {
                    nextSection = current.section - 1
                    nextItem = tableView(tableView, numberOfRowsInSection: nextSection) - 1
                }
            } else {
                nextSection = current.section
                nextItem = current.item - 1
            }
        case UIKeyCommand.inputDownArrow:
            let currentSectionItemsCount = tableView(tableView, numberOfRowsInSection: current.section)
            if current.item == currentSectionItemsCount - 1 {
                if current.section == tableView.numberOfSections - 1 {
                    // We've reached the last item in the last section
                    return
                } else {
                    // We can go to the next section.
                    nextSection = current.section + 1
                    nextItem = 0
                }
            } else {
                nextSection = current.section
                nextItem = current.item + 1
            }
        default:
            return
        }
        guard nextItem >= 0 else {
            return
        }
        let next = IndexPath(item: nextItem, section: nextSection)
        self.tableView(tableView, didHighlightRowAt: next)
        tableView.selectRow(at: next, animated: false, scrollPosition: .middle)
    }
}

extension SearchViewController: SuggestionCellDelegate {
    fileprivate func suggestionCell(_ suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String) {
        // Assume that only the default search engine can provide search suggestions.
        let engine = searchEngines.defaultEngine()

        var url = URIFixup.getURL(suggestion)
        if url == nil {
            url = engine.searchURLForQuery(suggestion)
        }

        if let url = url {
            searchDelegate?.searchViewController(self, didSelectURL: url)
        }
    }

    fileprivate func suggestionCell(_ suggestionCell: SuggestionCell, didLongPressSuggestion suggestion: String) {
        searchDelegate?.searchViewController(self, didLongPressSuggestion: suggestion)
    }
}

/**
 * Private extension containing string operations specific to this view controller
 */
private extension String {
    func looksLikeAURL() -> Bool {
        // The assumption here is that if the user is typing in a forward slash and there are no spaces
        // involved, it's going to be a URL. If we type a space, any url would be invalid.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1192155 for additional details.
        return self.contains("/") && !self.contains(" ")
    }
}

/**
 * UIScrollView that prevents buttons from interfering with scroll.
 */
private class ButtonScrollView: UIScrollView {
    fileprivate override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}

private protocol SuggestionCellDelegate: class {
    func suggestionCell(_ suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String)
    func suggestionCell(_ suggestionCell: SuggestionCell, didLongPressSuggestion suggestion: String)
}

/**
 * Cell that wraps a list of search suggestion buttons.
 */
private class SuggestionCell: UITableViewCell {
    weak var delegate: SuggestionCellDelegate?
    let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = false
        accessibilityLabel = nil
        layoutMargins = .zero
        separatorInset = .zero
        selectionStyle = .none

        container.backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        contentView.addSubview(container)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var suggestions: [String] = [] {
        didSet {
            for view in container.subviews {
                view.removeFromSuperview()
            }

            for suggestion in suggestions {
                let button = SuggestionButton()
                button.setTitle(suggestion, for: [])
                button.addTarget(self, action: #selector(didSelectSuggestion), for: .touchUpInside)
                button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressSuggestion)))

                // If this is the first image, add the search icon.
                if container.subviews.isEmpty {
                    button.setImage(#imageLiteral(resourceName: "search"), for: [])
                    if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
                        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                    } else {
                        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
                    }
                }

                container.addSubview(button)
            }

            setNeedsLayout()
        }
    }

    @objc
    func didSelectSuggestion(_ sender: UIButton) {
        delegate?.suggestionCell(self, didSelectSuggestion: sender.titleLabel!.text!)
    }

    @objc
    func didLongPressSuggestion(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let button = recognizer.view as? UIButton {
                delegate?.suggestionCell(self, didLongPressSuggestion: button.titleLabel!.text!)
            }
        }
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        // The left bounds of the suggestions, aligned with where text would be displayed.
        let textLeft: CGFloat = 61

        // The maximum width of the container, after which suggestions will wrap to the next line.
        let maxWidth = contentView.frame.width

        let imageSize = CGFloat(SearchViewControllerUX.faviconSize)

        // The height of the suggestions container (minus margins), used to determine the frame.
        // We set it to imageSize.height as a minimum since we don't want the cell to be shorter than the icon
        var height: CGFloat = imageSize

        var currentLeft = textLeft
        var currentTop = SearchViewControllerUX.suggestionCellVerticalPadding
        var currentRow = 0

        for view in container.subviews.compactMap({ $0 as? UIButton }) {
            let button = view
            var buttonSize = button.intrinsicContentSize

            // Update our base frame height by the max size of either the image or the button so we never
            // make the cell smaller than any of the two
            if height == imageSize {
                height = max(buttonSize.height, imageSize)
            }

            var width = currentLeft + buttonSize.width + SearchViewControllerUX.suggestionMargin
            if width > maxWidth {
                // Only move to the next row if there's already a suggestion on this row.
                // Otherwise, the suggestion is too big to fit and will be resized below.
                if currentLeft > textLeft {
                    currentRow += 1
                    if currentRow >= SearchViewControllerUX.suggestionCellMaxRows {
                        // Don't draw this button if it doesn't fit on the row.
                        button.frame = .zero
                        continue
                    }

                    currentLeft = textLeft
                    currentTop += buttonSize.height + SearchViewControllerUX.suggestionMargin
                    height += buttonSize.height + SearchViewControllerUX.suggestionMargin
                    width = currentLeft + buttonSize.width + SearchViewControllerUX.suggestionMargin
                }

                // If the suggestion is too wide to fit on its own row, shrink it.
                if width > maxWidth {
                    buttonSize.width = maxWidth - currentLeft - SearchViewControllerUX.suggestionMargin
                }
            }

            button.frame = CGRect(x: currentLeft, y: currentTop, width: buttonSize.width, height: buttonSize.height)
            currentLeft += buttonSize.width + SearchViewControllerUX.suggestionMargin
        }

        frame.size.height = height + 2 * SearchViewControllerUX.suggestionCellVerticalPadding
        contentView.frame = bounds
        container.frame = bounds

        let imageX = (textLeft - imageSize) / 2
        let imageY = (frame.size.height - imageSize) / 2
        imageView!.frame = CGRect(x: imageX, y: imageY, width: imageSize, height: imageSize)
    }
}

/**
 * Rounded search suggestion button that highlights when selected.
 */
private class SuggestionButton: InsetButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setTitleColor(UIConstants.highlightBlue, for: [])
        titleLabel?.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        layer.borderWidth = SearchViewControllerUX.suggestionBorderWidth
        layer.cornerRadius = SearchViewControllerUX.suggestionCornerRadius
        layer.borderColor = UIConstants.highlightBlue.cgColor
        contentEdgeInsets = SearchViewControllerUX.suggestionInsets

        accessibilityHint = Strings.searchesForSuggestionButtonAccessibilityText
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.6 : 1.0
        }
    }
}
