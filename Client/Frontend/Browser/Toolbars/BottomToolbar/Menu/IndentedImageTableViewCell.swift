// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

class IndentedImageTableViewCell: UITableViewCell {
    
    let mainStackView = UIStackView().then {
        $0.spacing = 8
        $0.alignment = .center
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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        indentationWidth = 20
        mainStackView.addArrangedSubview(folderImage)
        mainStackView.addArrangedSubview(folderName)
        
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

        print("\(folderName.text!): \(indentation + 36)")
        var sepInsets = separatorInset
        sepInsets.left = indentation + 36
        separatorInset = sepInsets
    }

}


// FIXME

/*
override func layoutSubviews() {
    // Call super
    super.layoutSubviews()
    
    let indentation = (CGFloat(indentationLevel) * indentationWidth)
    
    // Update the separator
    separatorInset = UIEdgeInsets(top: 0, left: indentation + 15, bottom: 0, right: 0)
    
    guard let imageView = imageView else { return }
    
    
    var imageFrame = imageView.frame
    imageFrame.origin.x += indentation
    
    imageView.frame = imageFrame
    
    guard let textLabel = textLabel else { return }
    
    var textLabelFrame = textLabel.frame
    //textLabelFrame.origin.x += indentation
    textLabelFrame.size.width -= imageView.frame.origin.x
    
    textLabel.frame = textLabelFrame
    
    guard let detailTextLabel = detailTextLabel else { return }
    var detailTextFrame = detailTextLabel.frame
    detailTextFrame.origin.x += 40
    detailTextFrame.size.width  = imageView.frame.origin.x + 60
    
    detailTextLabel.frame = detailTextFrame
    
    
    // Update the frame of the image view
    //        imageView.frame = CGRectMake(self.imageView.frame.origin.x + (self.indentationLevel * self.indentationWidth), self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height);
    //
    //        // Update the frame of the text label
    //        self.textLabel.frame = CGRectMake(self.imageView.frame.origin.x + 40, self.textLabel.frame.origin.y, self.frame.size.width - (self.imageView.frame.origin.x + 60), self.textLabel.frame.size.height);
    //
    //        // Update the frame of the subtitle label
    //        self.detailTextLabel.frame = CGRectMake(self.imageView.frame.origin.x + 40, self.detailTextLabel.frame.origin.y, self.frame.size.width - (self.imageView.frame.origin.x + 60), self.detailTextLabel.frame.size.height);
    
    
    
    return
    
    
    
    
    
    
    
    //        if let imageView = imageView {
    //            var frame = imageView.frame
    //            frame.origin.x = indentation + 40
    //imageView.frame = frame
    //        }
    
    //separatorInset = UIEdgeInsetsMake(0, indentation + 15, 0, 0)
    
    
}
*/
