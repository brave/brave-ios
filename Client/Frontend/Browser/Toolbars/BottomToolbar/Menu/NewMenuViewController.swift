// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import PanModal
import Static
import Shared
import BraveShared
import BraveUI

#if canImport(SwiftUI)
import SwiftUI
#endif

struct TableButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle()) // Needed or taps don't activate on empty space
            .background(
                Color(colorScheme == .dark ? .white : .black)
                    .opacity(configuration.isPressed ? 0.1 : 0.0)
            )
    }
}

struct MenuItemHeaderView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var icon: UIImage
    var title: String
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(Theme.of(nil).colors.addressBar))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(6)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            Text(verbatim: title)
        }
        .foregroundColor(Color(Theme.of(nil).colors.tints.home))
    }
}

struct NewMenuView<Content: View>: View {
    var content: Content
    @ObservedObject var themeNormalMode = Preferences.General.themeNormalMode
    var body: some View {
        ScrollView(.vertical) {
            content
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
    }
}

@available(iOS 13.0, *)
struct MenuItemButton: View {
    var icon: UIImage
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            MenuItemHeaderView(icon: icon, title: title)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 48.0, alignment: .leading)
        }
        .buttonStyle(TableButtonStyle())
        .accentColor(Color(Theme.of(nil).colors.tints.home))
    }
}


class NewMenuController: UINavigationController, PanModalPresentable, UIPopoverPresentationControllerDelegate {
    
    private var menuNavigationDelegate: MenuNavigationControllerDelegate?
    
    init<MenuContent: View>(@ViewBuilder content: (NewMenuController) -> MenuContent) {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [NewMenuHostingController(content: content(self))]
        menuNavigationDelegate = MenuNavigationControllerDelegate(panModal: self)
        delegate = menuNavigationDelegate
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    func presentInnerMenu(_ viewController: UIViewController,
                          expandToLongForm: Bool = true) {
        let container = NewMenuNavigationController(rootViewController: viewController)
        container.delegate = menuNavigationDelegate
        container.modalPresentationStyle = .overCurrentContext // over to fix the dismiss animation
        container.innerMenuDismissed = {
            if !self.isDismissing {
                self.panModalSetNeedsLayoutUpdate()
            }
        }
        present(container, animated: true) {
            self.panModalSetNeedsLayoutUpdate()
        }
        if expandToLongForm {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.panModalTransition(to: .longForm)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // Bug with pan modal + hidden nav bar causes safe area insets to zero out
        if view.safeAreaInsets == .zero, isPanModalPresented,
           var insets = view.window?.safeAreaInsets {
            // When that happens we re-set them via additionalSafeAreaInsets to the windows safe
            // area insets. Since the pan modal appears over the entire screen we can safely use
            // the windows safe area. Top will stay 0 since we are using non-translucent nav bar
            // and the top never reachs the safe area (handled by pan modal)
            insets.top = 0
            additionalSafeAreaInsets = insets
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override var shouldAutorotate: Bool {
        // Due to a bug in PanModal, the presenting controller does not receive safe area updates
        // while a pan modal is presented, therefore for the time being, do not allow rotation
        // while this menu is open.
        //
        // Issue: https://github.com/slackhq/PanModal/issues/139
        false
    }
    
    private var isDismissing: Bool = false
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let _ = presentedViewController as? NewMenuNavigationController,
           presentingViewController?.presentedViewController === self {
            isDismissing = true
            presentingViewController?.dismiss(animated: flag, completion: completion)
        } else {
            super.dismiss(animated: flag, completion: completion)
        }
    }
    
    private var isPresentingInnerMenu: Bool {
        if let _ = presentedViewController as? NewMenuNavigationController {
            return true
        }
        return false
    }
    
    var panScrollable: UIScrollView? {
        // For SwiftUI:
        //  - in iOS 13, ScrollView will exist within a host view
        //  - in iOS 14, it will be a direct subview
        // For UIKit:
        //  - UITableViewController's view is a UITableView, thus the view itself is a UIScrollView
        //  - For our non-UITVC's, the scroll view is a usually a subview of the main view
        func _scrollViewChild(in parentView: UIView, depth: Int = 0) -> UIScrollView? {
            if depth > 2 { return nil }
            if let scrollView = parentView as? UIScrollView {
                return scrollView
            }
            for view in parentView.subviews {
                if let scrollView = view as? UIScrollView {
                    return scrollView
                }
                if !view.subviews.isEmpty, let childScrollView = _scrollViewChild(in: view, depth: depth + 1) {
                    return childScrollView
                }
            }
            return nil
        }
        if let vc = presentedViewController, !vc.isBeingPresented {
            if let nc = vc as? UINavigationController, let vc = nc.topViewController {
                let scrollView = _scrollViewChild(in: vc.view)
                return scrollView
            }
            let scrollView = _scrollViewChild(in: vc.view)
            return scrollView
        }
        guard let topVC = topViewController else { return nil }
        topVC.view.layoutIfNeeded()
        return _scrollViewChild(in: topVC.view)
    }
    var longFormHeight: PanModalHeight {
        .maxHeight
    }
    var shortFormHeight: PanModalHeight {
        isPresentingInnerMenu ? .maxHeight : .contentHeight(340)
    }
    var allowsExtendedPanScrolling: Bool {
        true
    }
    var cornerRadius: CGFloat {
        10.0
    }
    var anchorModalToLongForm: Bool {
        isPresentingInnerMenu
    }
    var panModalBackgroundColor: UIColor {
        UIColor(white: 0.0, alpha: 0.5)
    }
    var dragIndicatorBackgroundColor: UIColor {
        UIColor(white: 0.95, alpha: 1.0)
    }
    var transitionDuration: Double {
        0.35
    }
    var springDamping: CGFloat {
        0.85
    }
}

private class NewMenuHostingController<MenuContent: View>: UIHostingController<NewMenuView<MenuContent>>, PreferencesObserver {
    init(content: MenuContent) {
        super.init(rootView: NewMenuView(content: content))
        Preferences.General.themeNormalMode.observe(from: self)
    }
    
    func preferencesDidChange(for key: String) {
        view.backgroundColor = Theme.of(nil).colors.home
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let animateNavBar = (navigationController?.isBeingPresented == false ? animated : false)
        navigationController?.setNavigationBarHidden(true, animated: animateNavBar)
        view.backgroundColor = Theme.of(nil).colors.home
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.isBeingDismissed == false {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            view.backgroundColor = Theme.of(nil).colors.home
        }
    }
}

private class MenuNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    weak var panModal: (UIViewController & PanModalPresentable)?
    init(panModal: UIViewController & PanModalPresentable) {
        self.panModal = panModal
        super.init()
    }
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        panModal?.panModalSetNeedsLayoutUpdate()
    }
}

private class NewMenuNavigationController: UINavigationController {
    var innerMenuDismissed: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Needed or else pan modal top scroll insets are messed up for some reason
        navigationBar.isTranslucent = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        innerMenuDismissed?()
    }
}
