// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

extension OnboardingSearchEnginesViewController {
    
    private struct UX {
        static let topInset: CGFloat = 64
        static let contentInset: CGFloat = 16
        
        struct SearchEngineCell {
            static let rowHeight: CGFloat = 64
            static let imageSize: CGFloat = 32
            static let cornerRadius: CGFloat = 15
            static let selectedBackgroundColor = #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8965459466, alpha: 1)
            static let deselectedBackgroundColor: UIColor = .white
        }
    }
    
    class View: UIView {
        
        let searchEnginesTable = UITableView().then {
            $0.separatorStyle = .none
            $0.allowsMultipleSelection = false
            $0.alwaysBounceVertical = false
        }
        
        let continueButton = CommonViews.primaryButton().then {
            $0.accessibilityIdentifier = "OnboardingSearchEnginesViewController.ContinueButton"
        }
        
        let skipButton = CommonViews.secondaryButton().then {
            $0.accessibilityIdentifier = "OnboardingSearchEnginesViewController.SkipButton"
        }
        
        private let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.alignment = .fill
            $0.spacing = 16
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        private let braveLogo = UIImageView(image: #imageLiteral(resourceName: "browser_lock_popup")).then {
            $0.contentMode = .scaleAspectFit
        }
        
        private let titleStackView = UIStackView().then { stackView in
            stackView.axis = .vertical
            
            let titlePrimary = CommonViews.primaryText(Strings.OBSearchEngineTitle)
            let titleSecondary = CommonViews.secondaryText(Strings.OBSearchEngineDetail)
            
            [titlePrimary, titleSecondary].forEach(stackView.addArrangedSubview(_:))
        }
        
        private let buttonsStackView = UIStackView().then {
            $0.distribution = .equalCentering
        }
        
        init() {
            super.init(frame: .zero)
            backgroundColor = .white
            
            [skipButton, continueButton, UIView.spacer(.horizontal, amount: 0)]
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
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let size = UX.SearchEngineCell.imageSize
            imageView?.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        }
    }
}
