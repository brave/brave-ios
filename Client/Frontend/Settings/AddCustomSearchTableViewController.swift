// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import Shared
import WebKit
import SnapKit
import Fuzi
import Alamofire
import Storage
import Deferred

private let log = Logger.browserLogger

class AddCustomSearchTableViewController: UITableViewController {
    
    private weak var profile: Profile!
    fileprivate var openSearchLinkDict: [String: String]? {
        didSet {
            guard let openSearchLinkDict = openSearchLinkDict else {
                showAutoAddSearchButton = false
                favicon = nil
                return
            }
            let title = openSearchLinkDict["title"] ?? ""
            let matches = self.profile.searchEngines.orderedEngines.filter {$0.title == title}
            if !matches.isEmpty {
                showAutoAddSearchButton = false
            } else {
                showAutoAddSearchButton = true
            }
        }
    }
    
    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    fileprivate var successCallback: (() -> Void)?
    fileprivate var favicon: Favicon?
    
    lazy fileprivate var alamofire: SessionManager = {
        let configuration = URLSessionConfiguration.default
        var defaultHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = UserAgent.desktopUserAgent()
        configuration.httpAdditionalHeaders = defaultHeaders
        configuration.timeoutIntervalForRequest = 5
        return SessionManager(configuration: configuration)
    }()
    
    private var showAutoAddSearchButton = false {
        didSet {
            manageInputAccessporyView()
        }
    }
    private var urlText = ""
    private var titleText: String?
    
    private var loadRequest: Alamofire.DataRequest? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var host: URL? {
        didSet {
            if let host = host, oldValue != host {
                var request = URLRequest(url: host)
                request.timeoutInterval = 10.0
                manageInputAccessporyView(loading: true)
                loadRequest = alamofire.request(host)
                loadRequest?.response(queue: DispatchQueue.main) {[weak self] response in
                    guard let data = response.data, response.error == nil else {
                        self?.openSearchLinkDict = nil
                        return
                    }
                    self?.loadEngineMeta(from: data, url: host)
                }
            }
        }
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        view.addSubview(spinnerView)
        spinnerView.snp.makeConstraints { make in
            make.center.equalTo(self.view.snp.center)
        }
        self.tableView.register(TextInputCell.self, forCellReuseIdentifier: TextInputCell.identifier)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.CancelButtonTitle, style: .plain, target: self, action: #selector(cancel))
        self.title = Strings.AddSearchEngineNavTitle
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.addCustomSearchEngine))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineSaveButton"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TextInputCell.identifier) as? TextInputCell
        switch indexPath.section {
        case 0:
            cell?.type = .textView(self)
            cell?.textview?.autocapitalizationType = .none
            cell?.textview?.autocorrectionType = .no
            cell?.textview?.keyboardType = .URL
        case 1:
            cell?.type = .textField(self)
        default:
            break
        }
        return cell ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return Strings.URL
        default:
            return Strings.Title
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return Strings.AddSearchFooterText
        default:
            return nil
        }
    }
    
    @objc fileprivate func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func manageInputAccessporyView(loading: Bool = false) {
        
        guard let accessoryView = (tableView.cellForRow(at: IndexPath(row: 0, section: 0 )) as? TextInputCell)?.textview?.inputAccessoryView as? AddSearchEngineAccessoryView else {
            return
        }
        accessoryView.addEngineButton.state = loading ? .loading : showAutoAddSearchButton ? .enabled : .disabled
    }
}

//Manual add
extension AddCustomSearchTableViewController {
    fileprivate func addSearchEngine(_ searchQuery: String, title: String) {
        spinnerView.startAnimating()
        
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        createEngine(forQuery: trimmedQuery, andName: trimmedTitle).uponQueue(.main) { result in
            self.spinnerView.stopAnimating()
            guard let engine = result.successValue else {
                self.handleError(error: result.failureValue ?? "")
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                return
            }
            try! self.profile.searchEngines.addSearchEngine(engine)
            CATransaction.begin() // Use transaction to call callback after animation has been completed
            CATransaction.setCompletionBlock(self.successCallback)
            self.cancel()
            CATransaction.commit()
        }
    }
    
    func createEngine(forQuery query: String, andName name: String) -> Deferred<Maybe<OpenSearchEngine>> {
        let deferred = Deferred<Maybe<OpenSearchEngine>>()
        guard let template = getSearchTemplate(withString: query),
            let url = URL(string: template.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!), url.isWebPage() else {
                deferred.fill(Maybe(failure: SearchEngineError.invalidQuery))
                return deferred
        }
        
        // ensure we haven't already stored this template
        guard engineExists(name: name, template: template) == false else {
            deferred.fill(Maybe(failure: SearchEngineError.duplicate))
            return deferred
        }
        
        FaviconFetcher.fetchFavImageForURL(forURL: url, profile: profile).uponQueue(.main) { result in
            let image = result.successValue ?? FaviconFetcher.getDefaultFavicon(url)
            let engine = OpenSearchEngine(engineID: nil, shortName: name, image: image, searchTemplate: template, suggestTemplate: nil, isCustomEngine: true)
            
            //Make sure a valid scheme is used
            let url = engine.searchURLForQuery("test")
            let maybe = (url == nil) ? Maybe(failure: SearchEngineError.invalidQuery) : Maybe(success: engine)
            deferred.fill(maybe)
        }
        return deferred
    }
    
    private func engineExists(name: String, template: String) -> Bool {
        return profile.searchEngines.orderedEngines.contains { (engine) -> Bool in
            return engine.shortName == name || engine.searchTemplate == template
        }
    }
    
    func getSearchTemplate(withString query: String) -> String? {
        let SearchTermComponent = "%s"      //Placeholder in User Entered String
        let placeholder = "{searchTerms}"   //Placeholder looked for when using Custom Search Engine in OpenSearch.swift
        if query.contains(SearchTermComponent) {
            return query.replacingOccurrences(of: SearchTermComponent, with: placeholder)
        }
        return nil
    }
    
    @objc func addCustomSearchEngine(_ nav: UINavigationController?) {
        self.view.endEditing(true)
        if let title = titleText, !title.isEmpty && !urlText.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
            addSearchEngine(urlText, title: title)
        } else {
            let alert = ThirdPartySearchAlerts.fillAllFields()
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension AddCustomSearchTableViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Identify host if possible.
        if let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let url = URL(string: text.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!),
            url.host != nil,
            url.isWebPage() {
            host = url.getBaseURL()
        }
        self.urlText = textView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Hold the test for fututre.
        self.urlText = textView.text
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let accessoryView = AddSearchEngineAccessoryView(frame: CGRect(width: 0, height: 44.0))
        accessoryView.delegate = self
        textView.inputAccessoryView = accessoryView
        accessoryView.addEngineButton.state = showAutoAddSearchButton ? .enabled : .disabled
        return true
    }
}

extension AddCustomSearchTableViewController: AddSearchEngineAccessoryViewDelegate {
    func handleError(error: Error) {
        let alert: UIAlertController
        if let searchError = error as? SearchEngineError {
            switch searchError {
            case .duplicate:
                alert = ThirdPartySearchAlerts.duplicateCustomEngine()
            case .invalidQuery:
                alert = ThirdPartySearchAlerts.incorrectCustomEngineForm()
            }
        } else {
            alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
        }
        log.error(error)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func doneAction(sender: AddSearchEngineAccessoryView) {
        self.view.endEditing(true)
    }
    
    fileprivate func addEngine(sender: AddSearchEngineAccessoryView) {
        guard let urlString = openSearchLinkDict?["href"],
            let title = openSearchLinkDict?["title"],
            var url = URL(string: urlString),
            let faviconURLString = favicon?.url,
            let faviconURL = URL(string: faviconURLString) else {
                handleError(error: "Failed to add Search Engine")
                return
        }
        if let baseURL = host?.getBaseURL(), url.host == nil {
            if url.absoluteString.hasPrefix("//"), let _url = URL(string: "\(baseURL.scheme!):\(url.absoluteString)" ) {
                url = _url
            } else if url.absoluteString.hasPrefix("/") {
                let component: String = url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                url = baseURL.appendingPathComponent(component)
            }
        }
        sender.addEngineButton.state = .loading
        OpenSearchXMLDownloader(url: url, title: title, imageURL: faviconURL).uponQueue(.main) {[weak self] (engine, error) in
            sender.addEngineButton.state = .enabled
            guard let engine = engine, error == nil else {
                self?.handleError(error: error!)
                return
            }
            self?.addSearchEngine(engine)
            sender.addEngineButton.state = .disabled
        }
    }
    
    func addSearchEngine(_ engine: OpenSearchEngine) {
        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine { alert in
            do {
                try self.profile?.searchEngines.addSearchEngine(engine)
                self.cancel()
            } catch {
                self.handleError(error: error)
            }
        }
        self.view.endEditing(true)
        self.present(alert, animated: true, completion: {})
    }
}

extension AddCustomSearchTableViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        //hold the text for future.
        self.titleText = textField.text
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

extension AddCustomSearchTableViewController {
    
    func loadEngineMeta(from data: Data, url: URL) {
        guard let root = try? HTMLDocument(data: data as Data),
            let dict = getOpenSearchLinkAttr(document: root) else {
            self.openSearchLinkDict = nil
            return
        }
        self.openSearchLinkDict = dict
        favicon = FaviconFetcher().getIcons(document: root, url: url).first
    }
    
    func getOpenSearchLinkAttr(document: HTMLDocument) -> [String: String]? {
        for link in document.xpath("//head//link[contains(@type, 'application/opensearchdescription+xml')]") {
            guard let href = link["href"], let title = link["title"] else {
                continue //Skip the rest of the loop. But don't stop the loop
            }
            return ["href": href, "title": title]
        }
        return nil
    }
}

class TextInputCell: UITableViewCell {
    fileprivate static let URLCellHeight = 88.0
    fileprivate static let TitleCellHeight = 44.0
    enum CellType {
        case textField(UITextFieldDelegate?)
        case textView(UITextViewDelegate?)
    }
    static let identifier: String = "TextInputCell"
    var textfield: UITextField?
    var textview: UITextView?
    
    var type = CellType.textView(nil) {
        didSet {
            setup()
        }
    }
    
    private func setup() {
        switch type {
        case .textField(let delegate):
            textview?.removeFromSuperview()
            textview = nil
            textfield = UITextField(frame: CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height))
            textfield?.translatesAutoresizingMaskIntoConstraints = false
            textfield?.delegate = delegate
            self.contentView.addSubview(textfield!)
            textfield?.snp.makeConstraints({ make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().inset(-16)
                make.bottom.top.equalToSuperview()
                make.height.equalTo(TextInputCell.TitleCellHeight)
            })
        case .textView(let delegate):
            textfield?.removeFromSuperview()
            textfield = nil
            textview = UITextView(frame: CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height))
            textview?.translatesAutoresizingMaskIntoConstraints = false
            textview?.font = UIFont.systemFont(ofSize: 16)
            textview?.delegate = delegate
            self.contentView.addSubview(textview!)
            textview?.snp.makeConstraints({ make in
                make.leading.equalToSuperview().offset(14)
                make.trailing.equalToSuperview().inset(-14)
                make.bottom.top.equalToSuperview()
                make.height.equalTo(TextInputCell.URLCellHeight)
            })
        }
    }    
}

fileprivate protocol AddSearchEngineAccessoryViewDelegate: AnyObject {
    func doneAction(sender: AddSearchEngineAccessoryView)
    func addEngine(sender: AddSearchEngineAccessoryView)
}

fileprivate class AddSearchEngineAccessoryView: UIView {
    fileprivate weak var delegate: AddSearchEngineAccessoryViewDelegate?
    private let contentView = UIView()
    lazy var doneButton: UIButton = {
        let doneButton = UIButton()
        doneButton.setTitle(Strings.Done, for: .normal)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        doneButton.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        doneButton.accessibilityIdentifier = "AddCustomSearchTableViewController.doneButton"
        return doneButton
    }()
    
    lazy var addEngineButton: SearchEnigneAddButton = {
        let searchButton = SearchEnigneAddButton()
        searchButton.state = .disabled
        searchButton.addTarget(self, action: #selector(addEngine), for: .touchUpInside)
        searchButton.accessibilityIdentifier = "AddCustomSearchTableViewController.customSearchEngineButton"
        return searchButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.white
        self.addSubview(contentView)
        self.contentView.addSubview(addEngineButton)
        self.contentView.addSubview(doneButton)
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConstraints() {
        self.contentView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
        self.addEngineButton.snp.makeConstraints { make in
            make.leading.equalTo(self.contentView.snp.leading).offset(20)
            make.width.equalTo(self.contentView.snp.height)
            make.centerY.equalToSuperview()
            make.height.equalTo(self.contentView.snp.height)
        }
        self.doneButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.contentView.snp.trailing).inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc private func done() {
        delegate?.doneAction(sender: self)
    }
    
    @objc private func addEngine() {
        delegate?.addEngine(sender: self)
    }
}
