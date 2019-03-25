// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import Shared
import WebKit
import SnapKit

private let log = Logger.browserLogger

class AddCustomSearchTableViewController: UITableViewController {
    
    private weak var profile = (UIApplication.shared.delegate as? AppDelegate)?.profile
    fileprivate var openSearchLinkDict: [String: String]? {
        didSet {
            guard let openSearchLinkDict = openSearchLinkDict else {
                showAutoAddSearchButton = false
                return
            }
            let title = openSearchLinkDict["title"] ?? ""
            let matches = self.profile?.searchEngines.orderedEngines.filter {$0.title == title} ?? []
            if !matches.isEmpty {
                showAutoAddSearchButton = false
            } else {
                showAutoAddSearchButton = true
            }
        }
    }
    private var showAutoAddSearchButton = false {
        didSet {
            manageInputAccessporyView()
        }
    }
    private var urlText = ""
    private var titleText: String?
    private var host: URL? {
        didSet {
            if let host = host, oldValue != host {
                var request = URLRequest(url: host)
                request.timeoutInterval = 10.0
                manageInputAccessporyView(loading: true)
                webViewInternal.load(request)
            }
        }
    }
    
    fileprivate var schemesAllowed = ["http", "https"]
    
    fileprivate lazy var webViewInternal: WKWebView = {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: WKWebViewConfiguration())
        self.view.addSubview(webView)
        webView.isHidden = true
        return webView
    }()
    
    override init(style: UITableViewStyle) {
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webViewInternal.navigationDelegate = self
        webViewInternal.customUserAgent = UserAgent.desktopUserAgent()
        self.tableView.register(TextInputCell.self, forCellReuseIdentifier: TextInputCell.identifier)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.CancelButtonTitle, style: .plain, target: self, action: #selector(cancel))
        self.title = Strings.AddSearchEngineNavTitle
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
            return "URL"
        default:
            return "Title"
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

extension AddCustomSearchTableViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Identify host if possible.
        if let text = textView.text,
            let url = URL(string: text),
            url.host != nil,
            schemesAllowed.contains(url.scheme ?? "") {
            host = url.getBaseURL()
        }
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
        log.error(error.localizedDescription)
        let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func doneAction(sender: AddSearchEngineAccessoryView) {
        self.view.endEditing(true)
    }
    
    fileprivate func addEngine(sender: AddSearchEngineAccessoryView) {
        guard let urlString = openSearchLinkDict?["href"],
            let title = openSearchLinkDict?["title"],
            var url = URL(string: urlString) else {
                handleError(error: "Failed to add Search Engine")
                return
        }
        if let webViewBaseURL = webViewInternal.url?.getBaseURL(), url.host == nil {
            let component = url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            url = webViewBaseURL.appendingPathComponent(component)
        }
        sender.addEngineButton.state = .loading
        OpenSearchXMLDownloader(url: url, title: title).uponQueue(.main) {[weak self] (engine, error) in
            sender.addEngineButton.state = .enabled
            guard let engine = engine, error == nil else {
                log.error(error)
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self?.present(alert, animated: true, completion: nil)
                return
            }
            self?.addSearchEngine(engine)
            sender.addEngineButton.state = .disabled
        }
    }
    
    func addSearchEngine(_ engine: OpenSearchEngine) {
        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine { alert in
            self.profile?.searchEngines.addSearchEngine(engine)
            let Toast = SimpleToast()
            Toast.showAlertWithText(Strings.ThirdPartySearchEngineAdded, bottomContainer: self.tableView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.cancel()
            })
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

extension AddCustomSearchTableViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(OpenSearchEngine.fetchOpenSearchLinkScript) { result, _ in
            if let dict = (result as? String)?.jsonObject() as? [String: String] {
                self.openSearchLinkDict = dict
            } else {
                self.openSearchLinkDict = nil
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.openSearchLinkDict = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.openSearchLinkDict = nil
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.openSearchLinkDict = nil
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
