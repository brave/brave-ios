// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

class FolderDetailsViewTableViewCell: UIView, BookmarkFormFieldsProtocol {

    let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }
    
    let titleTextField = UITextField().then {
        $0.placeholder = "Title"
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        $0.tag = 22
        
        let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 16))
        $0.leftViewMode = .always
        $0.leftView = spacerView
    }
    
    var spacerLine: UIView {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5))
        
        return view
    }
    
    weak var delegate: BookmarkDetailsViewDelegate?
    
    convenience init(title: String?, viewHeight: CGFloat) {
        self.init(frame: .zero)
        
        mainStackView.addArrangedSubview(spacerLine)
        mainStackView.addArrangedSubview(titleTextField)
        mainStackView.addArrangedSubview(spacerLine)
        
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.correctValues(validationPassed: validateFields())
    }
}
