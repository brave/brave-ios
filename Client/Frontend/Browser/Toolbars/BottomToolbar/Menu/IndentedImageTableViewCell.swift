// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

class IndentedImageTableViewCell: UITableViewCell {
    
    let mainStackView = UIStackView().then {
        $0.spacing = 8
        $0.alignment = .fill
    }
    
    let folderNameStackView = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .equalSpacing
    }
    
    let folderImage = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "bookmarks_folder_hollow")
        $0.contentMode = .scaleAspectFit
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    let folderName = UILabel().then {
        $0.textAlignment = .left
    }
    
    var spacerLine: UIView {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5))
        
        return view
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        indentationWidth = 20
        mainStackView.addArrangedSubview(folderImage)
        
        let transparentLine = spacerLine
        transparentLine.backgroundColor = .clear
        folderNameStackView.addArrangedSubview(transparentLine)
        folderNameStackView.addArrangedSubview(folderName)
        folderNameStackView.addArrangedSubview(spacerLine)
        
        mainStackView.addArrangedSubview(folderNameStackView)
        
        // Hide UITableViewCells separator, a custom one will be used.
        // This separator inset was problematic to update based on indentation.
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints {
            $0.top.bottom.equalTo(self)
            $0.leading.trailing.equalTo(self).inset(8)
            $0.centerY.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let indentation = (CGFloat(indentationLevel) * indentationWidth)

        mainStackView.snp.remakeConstraints {
            $0.leading.equalTo(self).inset(indentation + 8)
            $0.top.bottom.equalTo(self)
            $0.trailing.equalTo(self).inset(8)
            $0.centerY.equalTo(self)
        }

    }

}
