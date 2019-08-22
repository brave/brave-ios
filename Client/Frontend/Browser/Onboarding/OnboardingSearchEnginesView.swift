// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import pop

extension OnboardingSearchEnginesViewController {
    
    private struct UX {
        static let topInset: CGFloat = 48
        static let contentInset: CGFloat = 25
        static let logoSize: CGFloat = 100
        
        struct SearchEngineCell {
            static let rowHeight: CGFloat = 54
            static let imageSize: CGFloat = 32
            static let cornerRadius: CGFloat = 8
            static let selectedBackgroundColor = #colorLiteral(red: 0.9411764706, green: 0.9450980392, blue: 1, alpha: 1)
            static let deselectedBackgroundColor: UIColor = .white
        }
    }
    
    class View: UIView {
        
        let searchEnginesTable = UITableView().then {
            $0.separatorStyle = .none
            $0.allowsMultipleSelection = false
            $0.alwaysBounceVertical = false
        }
        
        let continueButton = CommonViews.primaryButton(text: Strings.OBSaveButton).then {
            $0.accessibilityIdentifier = "OnboardingSearchEnginesViewController.SaveButton"
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        }
        
        let skipButton = CommonViews.secondaryButton().then {
            $0.accessibilityIdentifier = "OnboardingSearchEnginesViewController.SkipButton"
        }
        
        private let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.alignment = .fill
            $0.spacing = 20
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        private let braveLogo = UIImageView(image: #imageLiteral(resourceName: "browser_lock_popup")).then { logo in
            logo.contentMode = .scaleAspectFit
            
            POPBasicAnimation(propertyNamed: kPOPLayerTranslationY)?.do {
                $0.fromValue = -5
                $0.toValue = 5
                $0.repeatForever = true
                $0.autoreverses = true
                $0.duration = 2
                logo.layer.pop_add($0, forKey: "translateY")
            }
        }
        
        private let titleStackView = UIStackView().then { stackView in
            stackView.axis = .vertical
            
            let titlePrimary = CommonViews.primaryText(Strings.OBSearchEngineTitle).then {
                $0.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
            }
            
            let titleSecondary = CommonViews.secondaryText(Strings.OBSearchEngineDetail).then {
                $0.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
            }
            
            [titlePrimary, titleSecondary].forEach(stackView.addArrangedSubview(_:))
        }
        
        private let buttonsStackView = UIStackView().then {
            $0.distribution = .equalCentering
            $0.alignment = .center
        }
        
        init() {
            super.init(frame: .zero)
            backgroundColor = .white
            
            let spacer = UIView()
            
            [skipButton, continueButton, spacer]
                .forEach(buttonsStackView.addArrangedSubview(_:))
            
            [braveLogo, titleStackView, searchEnginesTable, buttonsStackView]
                .forEach(mainStackView.addArrangedSubview(_:))
            
            addSubview(mainStackView)
            
            mainStackView.snp.makeConstraints {
                $0.top.equalTo(self.safeArea.top).inset(UX.topInset)
                
                $0.leading.equalTo(self.safeArea.leading).inset(UX.contentInset)
                $0.trailing.equalTo(self.safeArea.trailing).inset(UX.contentInset)
                $0.bottom.equalTo(self.safeArea.bottom).inset(UX.contentInset)
            }
            
            braveLogo.snp.makeConstraints {
                $0.height.equalTo(UX.logoSize)
            }
            
            // Make width the same as skip button to make save button always centered.
            spacer.snp.makeConstraints {
                $0.width.equalTo(skipButton)
            }
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError() }
    }
    
    class SearchEngineCell: UITableViewCell {
        
        static let preferredHeight = UX.SearchEngineCell.rowHeight
        
        var searchEngineName: String? {
            set { textLabel?.text = newValue }
            get { return textLabel?.text }
        }
        
        var searchEngineImage: UIImage? {
            set { imageView?.image = newValue }
            get { return imageView?.image }
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            imageView?.contentMode = .scaleAspectFit
            layer.cornerRadius = UX.SearchEngineCell.cornerRadius
            selectionStyle = .none
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError() }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            
            backgroundColor = selected ?
                UX.SearchEngineCell.selectedBackgroundColor : UX.SearchEngineCell.deselectedBackgroundColor
            
            textLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let size = UX.SearchEngineCell.imageSize
            imageView?.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        }
    }
}
