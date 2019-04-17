// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit

protocol BookmarkDetailsViewDelegate: class {
    func correctValues(validationPassed: Bool)
}

class BookmarkDetailsView: UIView, BookmarkFormFieldsProtocol {
    
    let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }
    
    let contentStackView = UIStackView().then {
        $0.spacing = 8
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        $0.alignment = .center
    }
    
    let faviconImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "defaultTopSiteIcon")
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints {
            $0.size.equalTo(64)
        }
    }
    
    let textFieldsStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }
    
    let titleTextField = UITextField().then {
        $0.placeholder = "Title"
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        $0.tag = 22
    }
    
    let urlTextField: UITextField? = UITextField().then {
        $0.placeholder = "Address"
        $0.keyboardType = .webSearch
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.smartDashesType = .no
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        $0.tag = 33
    }
    
    var spacerLine: UIView {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5))

        return view
    }
    
    weak var delegate: BookmarkDetailsViewDelegate?
    
    convenience init(title: String?, url: String?) {
        self.init(frame: .zero)
        
        guard let urlTextField = urlTextField else { fatalError() }
        
        mainStackView.addArrangedSubview(spacerLine)
        mainStackView.addArrangedSubview(contentStackView)
        mainStackView.addArrangedSubview(spacerLine)
        
        textFieldsStackView.addArrangedSubview(titleTextField)
        textFieldsStackView.addArrangedSubview(spacerLine)
        textFieldsStackView.addArrangedSubview(urlTextField)
        
        // Adding spacer view with zero width, UIStackView's spacing will take care
        // about adding a left margin.
        contentStackView.addArrangedSubview(UIView.spacer(.horizontal, amount: 0))
        contentStackView.addArrangedSubview(faviconImageView)
        contentStackView.addArrangedSubview(textFieldsStackView)
        
        faviconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        if let url = url, let favUrl = URL(string: url) {
            faviconImageView.setIcon(nil, forURL: favUrl)
        }
        
        titleTextField.text = title ?? "New bookmark"
        urlTextField.text = url ?? "New folder"
        
        mainStackView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addSubview(mainStackView)
        
        setupTextFieldTargets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupTextFieldTargets() {
        [titleTextField, urlTextField].forEach {
            $0?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.correctValues(validationPassed: validateFields())
    }
}
