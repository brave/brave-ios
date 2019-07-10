/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import XCGLogger
import BraveShared

private let log = Logger.browserLogger

protocol TabLocationViewDelegate {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView)
    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressReload(_ tabLocationView: TabLocationView, from button: UIButton)
    func tabLocationViewDidTapStop(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapShieldsButton(_ urlBar: TabLocationView)
    func tabLocationViewDidTapRewardsButton(_ urlBar: TabLocationView)
    
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    @discardableResult func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

private struct TabLocationViewUX {
    static let HostFontColor = UIColor.black
    static let BaseURLFontColor = UIColor.Photon.Grey50
    static let Spacing: CGFloat = 8
    static let StatusIconSize: CGFloat = 18
    static let TPIconSize: CGFloat = 24
    static let ButtonSize = CGSize(width: 44, height: 34.0)
    static let URLBarPadding = 4
}

class TabLocationView: UIView {
    var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!
    var contentView: UIStackView!
    private var tabObservers: TabObservers!

    @objc dynamic var baseURLFontColor: UIColor = TabLocationViewUX.BaseURLFontColor {
        didSet { updateTextWithURL() }
    }

    var url: URL? {
        didSet {
            updateLockImageView()
            updateTextWithURL()
            setNeedsUpdateConstraints()
        }
    }

    var contentIsSecure = false {
        didSet {
            updateLockImageView()
        }
    }
    
    var loading: Bool = false {
        didSet {
            if loading {
                reloadButton.setImage(#imageLiteral(resourceName: "nav-stop").template, for: .normal)
                reloadButton.accessibilityLabel = Strings.TabToolbarStopButtonAccessibilityLabel
            } else {
                reloadButton.setImage(#imageLiteral(resourceName: "nav-refresh").template, for: .normal)
                reloadButton.accessibilityLabel = Strings.TabToolbarReloadButtonAccessibilityLabel
            }
        }
    }
    
    private func updateLockImageView() {
        let wasHidden = lockImageView.isHidden
        lockImageView.isHidden = !contentIsSecure

        if wasHidden != lockImageView.isHidden {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        unregister(tabObservers)
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                let wasHidden = readerModeButton.isHidden
                self.readerModeButton.readerModeState = newReaderModeState
                readerModeButton.isHidden = (newReaderModeState == ReaderModeState.unavailable)
                if wasHidden != readerModeButton.isHidden {
                    UIAccessibility.post(notification: .layoutChanged, argument: nil)
                    if !readerModeButton.isHidden {
                        // Delay the Reader Mode accessibility announcement briefly to prevent interruptions.
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            UIAccessibility.post(notification: .announcement, argument: Strings.ReaderModeAvailableVoiceOverAnnouncement)
                        }
                    }
                }
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.readerModeButton.alpha = newReaderModeState == .unavailable ? 0 : 1
                })
            }
        }
    }

    lazy var placeholder: NSAttributedString = {
        return NSAttributedString(string: Strings.TabToolbarSearchAddressPlaceholderText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.Photon.Grey40])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = DisplayTextField()

        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        urlTextField.backgroundColor = .clear

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }

        return urlTextField
    }()

    fileprivate lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: #imageLiteral(resourceName: "lock_verified").template)
        lockImageView.isHidden = true // Hidden by default
        lockImageView.tintColor = #colorLiteral(red: 0.3764705882, green: 0.3843137255, blue: 0.4, alpha: 1)
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = .center
        lockImageView.accessibilityLabel = Strings.TabToolbarLockImageAccessibilityLabel
        lockImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return lockImageView
    }()

    fileprivate lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: .zero)
        readerModeButton.addTarget(self, action: #selector(tapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressReaderModeButton)))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.isHidden = true
        readerModeButton.imageView?.contentMode = .scaleAspectFit
        readerModeButton.contentHorizontalAlignment = .center
        readerModeButton.accessibilityLabel = Strings.TabToolbarReaderViewButtonAccessibilityLabel
        readerModeButton.accessibilityIdentifier = "TabLocationView.readerModeButton"
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: Strings.TabToolbarReaderViewButtonTitle, target: self, selector: #selector(readerModeCustomAction))]
        return readerModeButton
    }()
    
    lazy var reloadButton = ToolbarButton().then {
        $0.accessibilityIdentifier = "TabToolbar.stopReloadButton"
        $0.accessibilityLabel = Strings.TabToolbarReloadButtonAccessibilityLabel
        $0.setImage(#imageLiteral(resourceName: "nav-refresh").template, for: .normal)
        $0.tintColor = UIColor.Photon.Grey30
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressStopReload(_:)))
        $0.addGestureRecognizer(longPressGestureStopReloadButton)
        $0.addTarget(self, action: #selector(didClickStopReload), for: .touchUpInside)
    }

    lazy var shieldsButton: ToolbarButton = {
        let button = ToolbarButton()
        button.setImage(UIImage(imageLiteralResourceName: "shields-menu-icon"), for: .normal)
        button.addTarget(self, action: #selector(didClickBraveShieldsButton), for: .touchUpInside)
        button.imageView?.contentMode = .center
        button.accessibilityLabel = Strings.Brave_Panel
        button.accessibilityIdentifier = "urlBar-shieldsButton"
        return button
    }()
    
    lazy var rewardsButton: RewardsButton = {
        let button = RewardsButton()
        button.addTarget(self, action: #selector(didClickBraveRewardsButton), for: .touchUpInside)
        button.isDisabled = PrivateBrowsingManager.shared.isPrivateBrowsing
        return button
    }()
    
    lazy var separatorLine: UIView = {
        let line = UIView()
        line.layer.cornerRadius = 2
        return line
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.tabObservers = registerFor(.didChangeContentBlocking, .didGainFocus, queue: .main)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressLocation))
        longPressRecognizer.delegate = self

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapLocation))
        tapRecognizer.delegate = self

        addGestureRecognizer(longPressRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        let buttonContentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        
        #if NO_REWARDS
        [readerModeButton, reloadButton, separatorLine, shieldsButton].forEach {
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }
        
        let buttonsStackview = UIStackView(arrangedSubviews: [shieldsButton])
        
        shieldsButton.contentEdgeInsets = buttonContentEdgeInsets
        #else
        [readerModeButton, reloadButton, separatorLine, shieldsButton, rewardsButton].forEach {
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }
        
        let buttonsStackview = UIStackView(arrangedSubviews: [shieldsButton, rewardsButton])
        
        shieldsButton.contentEdgeInsets = buttonContentEdgeInsets
        rewardsButton.contentEdgeInsets = buttonContentEdgeInsets
        
        #endif
        
        urlTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let subviews = [lockImageView, urlTextField, readerModeButton, reloadButton, separatorLine, buttonsStackview]
        contentView = UIStackView(arrangedSubviews: subviews)
        contentView.distribution = .fill
        contentView.alignment = .center
        contentView.layoutMargins = UIEdgeInsets(top: 0, left: TabLocationViewUX.Spacing, bottom: 0, right: 0)
        contentView.isLayoutMarginsRelativeArrangement = true
        contentView.insetsLayoutMarginsFromSafeArea = false
        contentView.spacing = 10
        addSubview(contentView)
        
        // Reduce spacing after separator to make space for shields button tappable area.
        contentView.setCustomSpacing(2, after: separatorLine)

        contentView.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(self)
            make.trailing.equalTo(self).inset(6)
        }
        
        lockImageView.snp.makeConstraints { make in
            make.height.equalTo(TabLocationViewUX.ButtonSize)
        }
        
        separatorLine.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(26)
        }
        
        readerModeButton.snp.makeConstraints { make in
            make.size.width.equalTo(TabLocationViewUX.ButtonSize.width)
            make.size.height.equalTo(TabLocationViewUX.ButtonSize.height)
        }

        // Setup UIDragInteraction to handle dragging the location
        // bar for dropping its URL into other apps.
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        self.addInteraction(dragInteraction)
        
        NotificationCenter.default.addObserver(self, selector: #selector(privateBrowsingModeChanged), name: Notification.Name.PrivacyModeChanged, object: nil)
    }
    
    @objc private func privateBrowsingModeChanged() {
        #if !NO_REWARDS
        rewardsButton.isDisabled = PrivateBrowsingManager.shared.isPrivateBrowsing
        #endif
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityElements: [Any]? {
        get {
            return [lockImageView, urlTextField, readerModeButton].filter { !$0.isHidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    @objc func tapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    @objc func longPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }
    
    @objc func didClickStopReload() {
        if loading {
            delegate?.tabLocationViewDidTapStop(self)
        } else {
            delegate?.tabLocationViewDidTapReload(self)
        }
    }
    
    @objc func didLongPressStopReload(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began && !loading {
            delegate?.tabLocationViewDidLongPressReload(self, from: reloadButton)
        }
    }
    
    @objc func longPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    @objc func tapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    @objc func readerModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }
    
    @objc func didClickBraveShieldsButton() {
        delegate?.tabLocationViewDidTapShieldsButton(self)
    }
    
    @objc func didClickBraveRewardsButton() {
        delegate?.tabLocationViewDidTapRewardsButton(self)
    }

    fileprivate func updateTextWithURL() {
        if let host = url?.host, AppConstants.MOZ_PUNYCODE {
            urlTextField.text = url?.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        } else {
            urlTextField.text = url?.absoluteString
        }
        // remove https:// (the scheme) from the url when displaying
        if let scheme = url?.scheme, let range = url?.absoluteString.range(of: "\(scheme)://") {
            urlTextField.text = url?.absoluteString.replacingCharacters(in: range, with: "")
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // When long pressing a button make sure the textfield's long press gesture is not triggered
        return !(otherGestureRecognizer.view is UIButton)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail the tap recognizer to avoid conflicts.
        return gestureRecognizer == longPressRecognizer && otherGestureRecognizer == tapRecognizer
    }
}

// MARK: - UIDragInteractionDelegate

extension TabLocationView: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        // Ensure we actually have a URL in the location bar and that the URL is not local.
        guard let url = self.url, !url.isLocal, let itemProvider = NSItemProvider(contentsOf: url),
            !reloadButton.isHighlighted else {
            return []
        }

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        delegate?.tabLocationViewDidBeginDragInteraction(self)
    }
}

// MARK: - AccessibilityActionsSource

extension TabLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
            return delegate?.tabLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

// MARK: - Themeable

extension TabLocationView: Themeable {
    func applyTheme(_ theme: Theme) {
        switch theme {
        case .regular:
            backgroundColor = BraveUX.LocationBarBackgroundColor
        case .private:
            backgroundColor = BraveUX.LocationBarBackgroundColor_PrivateMode
        }

        urlTextField.textColor = UIColor.Browser.Tint.colorFor(theme)
        readerModeButton.selectedTintColor = UIColor.TextField.ReaderModeButtonSelected.colorFor(theme)
        readerModeButton.unselectedTintColor = UIColor.TextField.ReaderModeButtonUnselected.colorFor(theme)
        
        reloadButton.applyTheme(theme)
        separatorLine.backgroundColor = UIColor.TextField.Separator.colorFor(theme)
    }
}

// MARK: - TabEventHandler

extension TabLocationView: TabEventHandler {
    func tabDidGainFocus(_ tab: Tab) {
    }

    func tabDidChangeContentBlockerStatus(_ tab: Tab) {
    }
}

private class DisplayTextField: UITextField {
    weak var accessibilityActionsSource: AccessibilityActionsSource?

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    fileprivate override var canBecomeFirstResponder: Bool {
        return false
    }
}
