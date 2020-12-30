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

class SearchCustomEngineViewController: UITableViewController {
    
    // MARK: Properties
    
    private var profile: Profile
    
    private var showAutoAddSearchButton = false {
        didSet {
            manageURLHeaderView()
        }
    }
    
    private var urlText = ""
    
    private var titleText: String?
    
    private var urlHeader: CustomSearchEngineURLHeader!
    
    private lazy var spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: Lifecycle
    
    init(profile: Profile) {
        self.profile = profile
        
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        
        tableView.register(TextInputCell.self, forCellReuseIdentifier: TextInputCell.identifier)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        
        title = "Add Search Engine"
        
        setSaveButton()
    }
    
    // MARK: UITableViewDelegate / UITableViewDataSource
    
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
                return "Write the search url and replace the query with %s.\nFor example: https://youtube.com/search?q=%s \n(If the site supports OpenSearch an option to add automatically will be provided while editing this field.)"
            default:
                return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = CustomSearchEngineURLHeader(frame: CGRect(x: 0, y: 0, width: 1, height: 44.0))
        
        switch section {
            case 0:
                header.titleLabel.text = Strings.URL
                header.addEngineButton.state = showAutoAddSearchButton ? .enabled : .disabled
                urlHeader = header
            default:
                header.addEngineButton.isHidden = true
                header.titleLabel.text = "Title"

        }
        
        return header
    }
    
    // MARK: Internal
    
    fileprivate func setSaveButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.addCustomSearchEngine))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineSaveButton"
    }
    
    fileprivate func showNavBarLoader() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinnerView)
        spinnerView.startAnimating()
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "customEngineActivityIndicator"
    }
    
    private func manageURLHeaderView(loading: Bool = false) {
        //urlHeader.addEngineButton.state = loading ? .loading : showAutoAddSearchButton ? .enabled : .disabled
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
    
    @objc fileprivate func cancel() {
        navigationController?.popViewController(animated: true)
    }
}

extension SearchCustomEngineViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Identify host if possible.
        if let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let url = URL(string: text.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!),
            url.host != nil,
            url.isWebPage() {
            
           // Identify the host
        }
        
        urlText = textView.text
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        urlText = textView.text
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let accessoryView = AddSearchEngineAccessoryView(frame: CGRect(width: 0, height: 44.0))
        textView.inputAccessoryView = accessoryView
        
        return true
    }
}

extension SearchCustomEngineViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        //hold the text for future.
        titleText = textField.text
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

fileprivate class CustomSearchEngineURLHeader: UIView {

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.Photon.grey50
        return label
    }()

    lazy var addEngineButton: OpenSearchEngineButton = {
        let searchButton = OpenSearchEngineButton(title: "Auto Add", hidesWhenDisabled: false)
        searchButton.addTarget(self, action: #selector(addEngine), for: .touchUpInside)
        searchButton.accessibilityIdentifier = "BrowserViewController.customSearchEngineButton"
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
        // TODO: Add Engine URL
    }
}

fileprivate class AddSearchEngineAccessoryView: UIView {
    private let contentView = UIView()
    
    lazy var doneButton: UIButton = {
        let doneButton = UIButton()
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        doneButton.setTitleColor(UIConstants.systemBlueColor, for: .normal)
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
        //TODO: Done
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
        
        //contentView.backgroundColor = .white
        
        switch type {
        case .textField(let delegate):
            textview?.removeFromSuperview()
            textview = nil
            textfield = UITextField(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
            textfield?.delegate = delegate
            contentView.addSubview(textfield!)
            
            textfield?.snp.makeConstraints({ make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.top.equalToSuperview()
                make.height.equalTo(TextInputCell.TitleCellHeight)
            })
        case .textView(let delegate):
            textfield?.removeFromSuperview()
            textfield = nil
            textview = UITextView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
            textview?.backgroundColor = .clear
            textview?.font = UIFont.systemFont(ofSize: 16)
            textview?.delegate = delegate
            self.contentView.addSubview(textview!)
            
            textview?.snp.makeConstraints({ make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.top.equalToSuperview()
                make.height.equalTo(TextInputCell.URLCellHeight)
            })
        }
    }
}
