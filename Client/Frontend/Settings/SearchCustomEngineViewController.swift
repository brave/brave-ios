// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import Shared
import WebKit
import SnapKit
import Fuzi
import Storage
import Data

private let log = Logger.browserLogger

// MARK: - SearchCustomEngineViewController

class SearchCustomEngineViewController: UIViewController {
    
    // MARK: SaveButtonType
    
    private enum SaveButtonType {
        case enabled
        case loading
    }
    
    // MARK: Section
    
    private enum Section: Int, CaseIterable {
        case url
        case title
    }
    
    // MARK: Constants
    
    struct Constants {
        static let textInputRowIdentifier = "textInputRowIdentifier"
        static let urlInputRowIdentifier = "urlInputRowIdentifier"
        static let titleInputRowIdentifier = "titleInputRowIdentifier"
        static let searchEngineHeaderIdentifier = "searchEngineHeaderIdentifier"
    }
    
    // MARK: Properties
    
    private var profile: Profile
    
    private var showAutoAddSearchButton = false
    
    private var urlText: String?
    
    private var titleText: String?
    
    private var urlHeader: SearchEngineTableViewHeader?
    
    private lazy var spinnerView = UIActivityIndicatorView(style: .gray).then {
        $0.hidesWhenStopped = true
    }
    
    private var tableView = UITableView(frame: .zero, style: .grouped)
    
    // MARK: Lifecycle
    
    init(profile: Profile) {
        self.profile = profile
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Search Engine"
        
        setup()
        doLayout()
        setSaveButton(for: .enabled)
    }
    
    // MARK: Internal
    
    private func setup() {
        tableView.do {
            $0.register(URLInputTableViewCell.self, forCellReuseIdentifier: Constants.urlInputRowIdentifier)
            $0.register(TitleInputTableViewCell.self, forCellReuseIdentifier: Constants.titleInputRowIdentifier)
            $0.register(SearchEngineTableViewHeader.self, forHeaderFooterViewReuseIdentifier: Constants.searchEngineHeaderIdentifier)
            $0.dataSource = self
            $0.delegate = self
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
    }
    
    private func doLayout() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }
    
    private func setSaveButton(for type: SaveButtonType) {
        switch type {
            case .enabled:
                navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .save, target: self, action: #selector(self.addCustomSearchEngine))
            case .loading:
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinnerView)
                spinnerView.startAnimating()
        }
    }
    
    private func handleError(error: Error) {
        let alert: UIAlertController
        
        if let searchError = error as? SearchEngineError {
            switch searchError {
                case .duplicate:
                    alert = ThirdPartySearchAlerts.duplicateCustomEngine()
                case .invalidQuery:
                    alert = ThirdPartySearchAlerts.incorrectCustomEngineForm()
                case .failedToSave:
                    alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
            }
        } else {
            alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
        }
        
        log.error(error)
        present(alert, animated: true, completion: nil)
    }

    // MARK: Actions
    
    @objc func addCustomSearchEngine(_ nav: UINavigationController?) {
        view.endEditing(true)
        
        // TODO: Add Logic
    }
    
    @objc func cancel() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDelegate UITableViewDataSource

extension SearchCustomEngineViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case Section.url.rawValue:
                guard let cell =
                        tableView.dequeueReusableCell(withIdentifier: Constants.urlInputRowIdentifier) as? URLInputTableViewCell else {
                    return UITableViewCell()
                }
                
                cell.delegate = self
                return cell
            default:
                guard let cell =
                        tableView.dequeueReusableCell(withIdentifier: Constants.titleInputRowIdentifier) as? TitleInputTableViewCell else {
                    return UITableViewCell()
                }
                
                cell.delegate = self
                return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == Section.url.rawValue else { return nil }
        
        return "Write the search url and replace the query with %s.\nFor example: https://youtube.com/search?q=%s \n(If the site supports OpenSearch an option to add automatically will be provided while editing this field.)"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: Constants.searchEngineHeaderIdentifier) as? SearchEngineTableViewHeader else {
            return nil
        }

        switch section {
            case Section.url.rawValue:
                headerView.titleLabel.text = Strings.URL
                headerView.addEngineButton.state = showAutoAddSearchButton ? .enabled : .disabled
                urlHeader = headerView
            default:
                headerView.titleLabel.text = "Title"
                headerView.addEngineButton.isHidden = true
        }
        
        return headerView
    }
}

// MARK: - UITextViewDelegate

extension SearchCustomEngineViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text.rangeOfCharacter(from: .newlines) == nil else {
            textView.resignFirstResponder()
            return false
        }

        return textView.text.count + (text.count - range.length) <= 150
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encodedText),
           url.host != nil,
           url.isWebPage() {
            
            // TODO: Identify the host
        }
        
        urlText = textView.text
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        urlText = textView.text
    }
}

// MARK: - UITextFieldDelegate

extension SearchCustomEngineViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        
        let currentString: NSString = text as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        
        return newString.length <= 50
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        titleText = textField.text
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        
        return true
    }
}

// MARK: - SearchEngineTableViewHeader

fileprivate class SearchEngineTableViewHeader: UITableViewHeaderFooterView {
    
    // MARK: Design
    
    struct Design {
        static let headerHeight: CGFloat = 44
        static let headerInset: CGFloat = 20
    }
    
    // MARK: Properties
    
    var titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = UIColor.Photon.grey50
    }

    lazy var addEngineButton = OpenSearchEngineButton(title: "Auto Add", hidesWhenDisabled: false).then {
        $0.addTarget(self, action: #selector(addEngine), for: .touchUpInside)
    }

    // MARK: Lifecycle
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        addSubview(titleLabel)
        addSubview(addEngineButton)
        
        setConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal
    
    func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Design.headerInset)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(Design.headerHeight)
        }
        
        addEngineButton.snp.makeConstraints { make in
            make.trailing.equalTo(snp.trailing).inset(Design.headerInset)
            make.centerY.equalToSuperview()
            make.height.equalTo(snp.height)
        }
    }
    
    // MARK: Actions

    @objc private func addEngine() {
        // TODO: Add Engine URL
    }
}

// MARK: URLInputTableViewCell

fileprivate class URLInputTableViewCell: UITableViewCell {

    // MARK: Design
    
    struct Design {
        static let cellHeight: CGFloat = 88
        static let cellInset: CGFloat = 16
    }
    
    // MARK: Properties
    
    var textview = UITextView(frame: .zero)
    
    weak var delegate: UITextViewDelegate? {
        didSet {
            textview.delegate = delegate
        }
    }
    // MARK: Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Internal
    
    private func setup() {
        textview = UITextView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)).then {
            $0.backgroundColor = .clear
            $0.backgroundColor = .clear
            $0.font = UIFont.systemFont(ofSize: Design.cellInset)
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
            $0.spellCheckingType = .no
            $0.keyboardType = .URL
        }
        
        contentView.addSubview(textview)
        
        textview.snp.makeConstraints({ make in
            make.leading.trailing.equalToSuperview().inset(Design.cellInset)
            make.bottom.top.equalToSuperview()
            make.height.equalTo(Design.cellHeight)
        })
    }
}

// MARK: TitleInputTableViewCell

fileprivate class TitleInputTableViewCell: UITableViewCell {

    // MARK: Design
    
    struct Design {
        static let cellHeight: CGFloat = 44
        static let cellInset: CGFloat = 16
    }
    
    // MARK: Properties
    
    var textfield: UITextField = UITextField(frame: .zero)
    
    weak var delegate: UITextFieldDelegate? {
        didSet {
            textfield.delegate = delegate
        }
    }

    // MARK: Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Internal
    
    private func setup() {
        textfield = UITextField(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
                
        contentView.addSubview(textfield)
        
        textfield.snp.makeConstraints({ make in
            make.leading.trailing.equalToSuperview().inset(Design.cellInset)
            make.bottom.top.equalToSuperview()
            make.height.equalTo(Design.cellHeight)
        })
    }
}
