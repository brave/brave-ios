// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

class FolderDetailsViewTableViewCell: UIView, BookmarkFormFieldsProtocol {
    
    // MARK: BookmarkFormFieldsProtocol
    
    weak var delegate: BookmarkDetailsViewDelegate?
    
    let titleTextField = UITextField().then {
        $0.placeholder = Strings.BookmarkTitlePlaceholderText
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 16))
        $0.leftViewMode = .always
        $0.leftView = spacerView
    }

    private let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }
    
    convenience init(title: String?, viewHeight: CGFloat) {
        self.init(frame: .zero)
        
        [UIView.separatorLine, titleTextField, UIView.separatorLine].forEach {
            mainStackView.addArrangedSubview($0)
        }

        titleTextField.text = title ?? Strings.NewFolderDefaultName
        
        mainStackView.snp.makeConstraints {
            $0.edges.equalTo(self)
            $0.height.equalTo(viewHeight)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addSubview(mainStackView)
        
        titleTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.correctValues(validationPassed: validateFields())
    }
}
