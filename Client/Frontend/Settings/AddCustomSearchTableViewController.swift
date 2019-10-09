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
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    fileprivate var successCallback: (() -> Void)?
    fileprivate var favicon: Favicon?
    
    private var showAutoAddSearchButton = false {
        didSet {
            manageURLHeaderView()
        }
    }
    private var urlText = ""
    private var titleText: String?
    
    private var loadRequest: Alamofire.DataRequest? {
        didSet {
            oldValue?.cancel()
        }
    }
    fileprivate var urlHeader: CustomSearchEngineURLHeader!
    private var host: URL? {
        didSet {
            if let host = host, oldValue != host {
                var request = URLRequest(url: host)
                request.timeoutInterval = 10.0
                showAutoAddSearchButton = false
                manageURLHeaderView()
                // TODO: Fix this request
//                loadRequest = alamofire.request(host)
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
    
    override init(style: UITableView.Style) {
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        tableView.register(TextInputCell.self, forCellReuseIdentifier: TextInputCell.identifier)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.CancelButtonTitle, style: .plain, target: self, action: #selector(cancel))
        title = Strings.AddSearchEngineNavTitle
        setSaveButton()
    }
    
    fileprivate func setSaveButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.addCustomSearchEngine))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineSaveButton"
    }
    
    fileprivate func showNavBarLoader() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinnerView)
        spinnerView.startAnimating()
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineActivityIndicator"
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return Strings.AddSearchFooterText
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = CustomSearchEngineURLHeader(frame: CGRect(x: 0, y: 0, width: 1, height: 44.0))
        switch section {
        case 0:
            header.titleLabel.text = Strings.URL
            header.delegate = self
            header.addEngineButton.state = showAutoAddSearchButton ? .enabled : .disabled
            urlHeader = header
        default:
            header.titleLabel.text = Strings.Title
        }
        return header
    }
    
    @objc fileprivate func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func manageURLHeaderView(loading: Bool = false) {
        urlHeader.addEngineButton.state = loading ? .loading : showAutoAddSearchButton ? .enabled : .disabled
    }
    
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
        present(alert, animated: true, completion: nil)
    }
}

//Manual add
extension AddCustomSearchTableViewController {
    fileprivate func addSearchEngine(_ searchQuery: String, title: String) {
        showNavBarLoader()
        
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        createEngine(forQuery: trimmedQuery, andName: trimmedTitle).uponQueue(.main) {[weak self] result in
            self?.setSaveButton()
            guard let weakSelf = self, let engine = result.successValue else {
                self?.handleError(error: result.failureValue ?? "")
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                return
            }
            try? weakSelf.profile.searchEngines.addSearchEngine(engine)
            CATransaction.begin() // Use transaction to call callback after animation has been completed
            CATransaction.setCompletionBlock(weakSelf.successCallback)
            weakSelf.cancel()
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
        view.endEditing(true)
        if let title = titleText, !title.isEmpty && !urlText.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
            addSearchEngine(urlText, title: title)
        } else {
            let alert = ThirdPartySearchAlerts.fillAllFields()
            present(alert, animated: true, completion: nil)
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
        urlText = textView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Hold the test for fututre.
        urlText = textView.text
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let accessoryView = AddSearchEngineAccessoryView(frame: CGRect(width: 0, height: 44.0))
        accessoryView.delegate = self
        textView.inputAccessoryView = accessoryView
        return true
    }
}

extension AddCustomSearchTableViewController: AddSearchEngineAccessoryViewDelegate {
    
    fileprivate func doneAction(sender: AddSearchEngineAccessoryView) {
        view.endEditing(true)
    }
}

extension AddCustomSearchTableViewController: CustomSearchEngineURLHeaderDelegate {
    fileprivate func addEngine(sender: CustomSearchEngineURLHeader) {
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
        }
    }
    
    func addSearchEngine(_ engine: OpenSearchEngine) {
        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine(title: engine.shortName, url: engine.searchTemplate) {[weak self] alert in
            do {
                try self?.profile?.searchEngines.addSearchEngine(engine)
                self?.cancel()
            } catch {
                self?.handleError(error: error)
            }
        }
        view.endEditing(true)
        present(alert, animated: true, completion: {})
    }
}

extension AddCustomSearchTableViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        //hold the text for future.
        titleText = textField.text
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
            openSearchLinkDict = nil
            return
        }
        openSearchLinkDict = dict
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
            textfield = UITextField(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
            textfield?.translatesAutoresizingMaskIntoConstraints = false
            textfield?.delegate = delegate
            contentView.addSubview(textfield!)
            textfield?.snp.makeConstraints({ make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().inset(-16)
                make.bottom.top.equalToSuperview()
                make.height.equalTo(TextInputCell.TitleCellHeight)
            })
        case .textView(let delegate):
            textfield?.removeFromSuperview()
            textfield = nil
            textview = UITextView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.white
        addSubview(contentView)
        contentView.addSubview(doneButton)
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConstraints() {
        contentView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
        
        doneButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.contentView.snp.trailing).inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc private func done() {
        delegate?.doneAction(sender: self)
    }
}

fileprivate protocol CustomSearchEngineURLHeaderDelegate: AnyObject {
    func addEngine(sender: CustomSearchEngineURLHeader)
}

fileprivate class CustomSearchEngineURLHeader: UIView {
    weak var delegate: CustomSearchEngineURLHeaderDelegate?
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.Photon.Grey50
        return label
    }()
    
    lazy var addEngineButton: SearchEnigneAddButton = {
        let searchButton = SearchEnigneAddButton(title: "Auto Add", hidesWhenDisabled: true)
        searchButton.loaderAlignment = .right
        searchButton.state = .disabled
        searchButton.addTarget(self, action: #selector(addEngine), for: .touchUpInside)
        searchButton.accessibilityIdentifier = "AddCustomSearchTableViewController.customSearchEngineButton"
        return searchButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(addEngineButton)
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(44.0)
        }
        addEngineButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.snp.trailing).inset(20)
            make.centerY.equalToSuperview()
            make.height.equalTo(self.snp.height)
        }
    }
    
    @objc private func addEngine() {
        delegate?.addEngine(sender: self)
    }
}
