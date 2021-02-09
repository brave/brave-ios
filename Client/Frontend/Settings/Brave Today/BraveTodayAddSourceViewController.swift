// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveUI
import Fuzi
import FeedKit

class BraveTodayAddSourceViewController: UITableViewController {
    
    let feedDataSource: FeedDataSource
    var sourcesAdded: ((Set<RSSFeedLocation>) -> Void)?
    
    private var isLoading: Bool = false
    
    init(dataSource: FeedDataSource) {
        self.feedDataSource = dataSource
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Source"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(tappedCancel))
        
        textField.addTarget(self, action: #selector(textFieldTextChanged), for: .editingChanged)
        textField.delegate = self
        
        tableView.register(FeedSearchCellClass.self)
        tableView.register(CenteredButtonCell.self)
        tableView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 0, height: 10))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    @objc private func tappedCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func textFieldTextChanged() {
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? CenteredButtonCell {
            // Update the color of the search row when text field is non empty
            cell.tintColor = isSearchEnabled && !isLoading ? BraveUX.braveOrange : Colors.grey500
        }
    }
    
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
    }()
    
    private func displayError(_ error: FindFeedsError) {
        let alert = UIAlertController(title: Strings.BraveToday.addSourceFailureTitle, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: Strings.OKString, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    private func searchPageForFeeds() {
        guard var text = textField.text else { return }
        if text.hasPrefix("feed:"), let range = text.range(of: "feed:") {
            text.replaceSubrange(range, with: [])
        }
        guard let url = URIFixup.getURL(text) else { return }
        downloadPageData(for: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let resultsController = BraveTodayAddSourceResultsViewController(
                    dataSource: self.feedDataSource,
                    searchedURL: url,
                    rssFeedLocations: data,
                    sourcesAdded: self.sourcesAdded
                )
                self.navigationController?.pushViewController(resultsController, animated: true)
            case .failure(let error):
                self.displayError(error)
            }
        }
    }
    
    private enum FindFeedsError: Error {
        /// An error occured while attempting to download the page
        case dataTaskError(Error)
        /// The data was either not received or is in the incorrect format
        case invalidData
        /// The data downloaded did not match a
        case parserError(ParserError)
        /// No feeds were found at the given URL
        case noFeedsFound
        
        var localizedDescription: String {
            switch self {
            case .dataTaskError(let error as URLError) where error.code == .notConnectedToInternet:
                return error.localizedDescription
            case .dataTaskError:
                return Strings.BraveToday.addSourceNetworkFailureMessage
            case .invalidData, .parserError:
                return Strings.BraveToday.addSourceInvalidDataMessage
            case .noFeedsFound:
                return Strings.BraveToday.addSourceNoFeedsFoundMessage
            }
        }
    }
    
    private var pageTask: URLSessionDataTask?
    private func downloadPageData(for url: URL, _ completion: @escaping (Result<[RSSFeedLocation], FindFeedsError>) -> Void) {
        pageTask = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error as? URLError, error.code == .cancelled {
                return
            }
            if let error = error {
                completion(.failure(.dataTaskError(error)))
                return
            }
            guard let data = data, let root = try? HTMLDocument(data: data) else {
                completion(.failure(.invalidData))
                return
            }
            let parser = FeedParser(data: data)
            if case .success(let feed) = parser.parse() {
                // User provided a direct feed
                var title: String?
                switch feed {
                case .atom(let atom):
                    title = atom.title
                case .json(let json):
                    title = json.title
                case .rss(let rss):
                    title = rss.title
                }
                completion(.success([.init(title: title, url: url)]))
            }
            // Ensure page is reloaded to final landing page before looking for
            // favicons
            var reloadUrl: URL?
            for meta in root.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                   let content = meta["content"],
                   let index = content.range(of: "URL="),
                   let url = NSURL(string: String(content.suffix(from: index.upperBound))) {
                    reloadUrl = url as URL
                }
            }
            
            if let url = reloadUrl {
                self.downloadPageData(for: url, completion)
                return
            }
            
            var feeds: [RSSFeedLocation] = []
            let xpath = "//head//link[contains(@type, 'application/rss+xml') or contains(@type, 'application/atom+xml') or contains(@type, 'application/json')]"
            for link in root.xpath(xpath) {
                guard let href = link["href"], let url = URL(string: href, relativeTo: url) else { continue }
                feeds.append(.init(title: link["title"], url: url))
            }
            if feeds.isEmpty {
                completion(.failure(.noFeedsFound))
            } else {
                completion(.success(feeds))
            }
        }
        pageTask?.resume()
    }
    
    private let textField = UITextField().then {
        $0.attributedPlaceholder = NSAttributedString(
            string: "Feed or Site URL",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        $0.font = .preferredFont(forTextStyle: .body)
        $0.keyboardType = .URL
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.returnKeyType = .search
    }
    
    private var isSearchEnabled: Bool {
        if let text = textField.text {
            return URIFixup.getURL(text) != nil
        }
        return false
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 1, isSearchEnabled, !isLoading {
            searchPageForFeeds()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 1 {
            return isSearchEnabled && !isLoading
        }
        return false
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(for: indexPath) as FeedSearchCellClass
            cell.textField = textField
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(for: indexPath) as CenteredButtonCell
            cell.textLabel?.text = "Search"
            cell.tintColor = isSearchEnabled && !isLoading ? BraveUX.braveOrange : Colors.grey500
            return cell
        default:
            fatalError("No cell available for index path: \(indexPath)")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
}

extension BraveTodayAddSourceViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isSearchEnabled {
            textField.resignFirstResponder()
            searchPageForFeeds()
            return true
        }
        return false
    }
}

private class FeedSearchCellClass: UITableViewCell, TableViewReusable {
    var textField: UITextField? {
        willSet {
            textField?.removeFromSuperview()
        }
        didSet {
            if let textField = textField {
                contentView.addSubview(textField)
                textField.snp.makeConstraints {
                    $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
                    $0.height.greaterThanOrEqualTo(44)
                }
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
}
