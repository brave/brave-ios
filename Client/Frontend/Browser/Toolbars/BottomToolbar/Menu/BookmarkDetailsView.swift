// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit

class BookmarkDetailsView: UIView {
    
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
    }
    
    let textFieldsStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }
    
    let titleTextField = UITextField().then {
        $0.placeholder = "Title"
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let urlTextField = UITextField().then {
        $0.placeholder = "Address"
        $0.keyboardType = .webSearch
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.smartDashesType = .no
        $0.clearButtonMode = .whileEditing
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    var spacerLine: UIView {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5))

        return view
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(spacerLine)
        mainStackView.addArrangedSubview(contentStackView)
        mainStackView.addArrangedSubview(spacerLine)
        
        textFieldsStackView.addArrangedSubview(titleTextField)
        textFieldsStackView.addArrangedSubview(spacerLine)
        textFieldsStackView.addArrangedSubview(urlTextField)
        
        //urlTextField.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        
        contentStackView.addArrangedSubview(faviconImageView)
        contentStackView.addArrangedSubview(textFieldsStackView)
        
        faviconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        //backgroundColor = .red
        
        mainStackView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        
//        spacerLine.snp.makeConstraints {
//            $0.height.equalTo(0.3)
//        }
        
//        faviconImageView.snp.makeConstraints {
//            $0.width.equalTo(48)
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
