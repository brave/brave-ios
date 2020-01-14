/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

enum ReaderModeBarButtonType {
    case settings

    fileprivate var localizedDescription: String {
        switch self {
        case .settings: return Strings.readerModeDisplaySettingsButtonTitle
        }
    }

    fileprivate var imageName: String {
        switch self {
        case .settings: return "SettingsSerif"
        }
    }

    fileprivate var image: UIImage? {
        let image = UIImage(imageLiteralResourceName: imageName)
        image.accessibilityLabel = localizedDescription
        return image
    }
}

protocol ReaderModeBarViewDelegate {
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

class ReaderModeBarView: UIView {
    var delegate: ReaderModeBarViewDelegate?

    var settingsButton: UIButton!

    @objc dynamic var buttonTintColor: UIColor = UIColor.clear {
        didSet {
            settingsButton.tintColor = self.buttonTintColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        settingsButton = createButton(.settings, action: #selector(tappedSettingsButton))
        settingsButton.accessibilityIdentifier = "ReaderModeBarView.settingsButton"
        settingsButton.snp.makeConstraints { (make) -> Void in
            make.height.centerX.centerY.equalTo(self)
            make.width.equalTo(80)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(0.5)
        context.setStrokeColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        context.setStrokeColor(UIColor.Photon.grey50.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: frame.height))
        context.addLine(to: CGPoint(x: frame.width, y: frame.height))
        context.strokePath()
    }

    fileprivate func createButton(_ type: ReaderModeBarButtonType, action: Selector) -> UIButton {
        let button = UIButton()
        addSubview(button)
        button.setImage(type.image, for: [])
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc func tappedSettingsButton(_ sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: .settings)
    }
}

extension ReaderModeBarView: Themeable {

    func applyTheme(_ theme: Theme) {
        styleChildren(theme: theme)
        
        backgroundColor = theme.colors.home
        buttonTintColor = theme.colors.tints.home
    }
}
