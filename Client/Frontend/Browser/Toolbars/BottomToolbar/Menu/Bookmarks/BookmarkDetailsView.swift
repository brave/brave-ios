// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit
import Shared

class BookmarkDetailsView: AddEditHeaderView, BookmarkFormFieldsProtocol {
    
    // MARK: BookmarkFormFieldsProtocol
    
    weak var delegate: BookmarkDetailsViewDelegate?
    
    let titleTextField = UITextField().then {
        $0.placeholder = Strings.BookmarkTitlePlaceholderText
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let urlTextField: UITextField? = UITextField().then {
        $0.placeholder = Strings.BookmarkUrlPlaceholderText
        $0.keyboardType = .URL
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.smartDashesType = .no
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - View setup
    
    private let contentStackView = UIStackView().then {
        $0.spacing = UX.defaultSpacing
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        $0.alignment = .center
    }
    
    private let faviconImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "defaultTopSiteIcon")
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints {
            $0.size.equalTo(UX.faviconSize)
        }
    }
    
    private let textFieldsStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = UX.defaultSpacing
    }
    
    // MARK: - Initialization
    
    convenience init(title: String?, url: String?) {
        self.init(frame: .zero)
        
        guard let urlTextField = urlTextField else { fatalError("Url text field must be set up") }
        
        [UIView.separatorLine, contentStackView, UIView.separatorLine]
            .forEach(mainStackView.addArrangedSubview)
        
        [titleTextField, UIView.separatorLine, urlTextField]
            .forEach(textFieldsStackView.addArrangedSubview)

        // Adding spacer view with zero width, UIStackView's spacing will take care
        // about adding a left margin to the content stack view.
        let emptySpacer = UIView.spacer(.horizontal, amount: 0)
        
        [emptySpacer, faviconImageView, textFieldsStackView]
            .forEach(contentStackView.addArrangedSubview)
        
        if let url = url, let favUrl = URL(string: url) {
            faviconImageView.setIcon(nil, forURL: favUrl)
        }
        
        titleTextField.text = title ?? Strings.NewBookmarkDefaultName
        urlTextField.text = url ?? Strings.NewFolderDefaultName
        
        setupTextFieldTargets()
    }
    
    private func setupTextFieldTargets() {
        [titleTextField, urlTextField].forEach {
            $0?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    // MARK: - Delegate actions
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.correctValues(validationPassed: validateFields())
    }
}
