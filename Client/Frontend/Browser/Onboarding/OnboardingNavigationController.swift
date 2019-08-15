// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

private let log = Logger.browserLogger

protocol Onboardable: class {
    /// Show next on boarding screen if possible.
    /// If last screen is currently presenting, the view is dimissed instead(onboarding finished).
    func presentNextScreen(current: OnboardingViewController)
    /// Skip all onboarding screens, onboarding is considered as completed.
    func skip()
}

protocol OnboardingControllerDelegate: class {
    func onboardingCompleted(_ onboardingController: OnboardingNavigationController)
}

class OnboardingNavigationController: UINavigationController {
    
    private struct UX {
        /// The onboarding screens are showing as a modal on iPads.
        static let preferredModalSize = CGSize(width: 375, height: 667)
    }
    
    weak var onboardingDelegate: OnboardingControllerDelegate?
    
    enum Screens: CaseIterable {
        case searchEnginePicker
        case shieldsInfo
        
        func viewController(with profile: Profile) -> OnboardingViewController {
            switch self {
            case .searchEnginePicker:
                return OnboardingSearchEnginesViewController(profile: profile)
            case .shieldsInfo:
                return OnboardingShieldsViewController(profile: profile)
            }
        }
        
        var type: AnyClass {
            switch self {
            case .searchEnginePicker: return OnboardingSearchEnginesViewController.self
            case .shieldsInfo: return OnboardingShieldsViewController.self
            }
        }
    }
    
    init?(profile: Profile) {
        guard let firstScreen = Screens.allCases.first else { return nil }
        
        let firstViewController = firstScreen.viewController(with: profile)
        super.init(rootViewController: firstViewController)
        firstViewController.delegate = self
        
        isNavigationBarHidden = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            modalPresentationStyle = .fullScreen
        } else {
            modalPresentationStyle = .formSheet
        }
        
        if #available(iOS 13.0, *) {
            // Prevent dismissing the modal by swipe
            isModalInPresentation = true
        }
        preferredContentSize = UX.preferredModalSize
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}

extension OnboardingNavigationController: Onboardable {
    
    func presentNextScreen(current: OnboardingViewController) {
        let allScreens = Screens.allCases
        let index = allScreens.map { $0.type }.firstIndex(where: { $0 == type(of: current) })
        
        guard let nextIndex = index?.advanced(by: 1),
            let nextScreen = allScreens[safe: nextIndex]?.viewController(with: current.profile) else {
                log.info("Last screen reached, onboarding is complete")
                onboardingDelegate?.onboardingCompleted(self)
                return
        }
        
        nextScreen.delegate = self
        
        pushViewController(nextScreen, animated: true)
    }
    
    func skip() {
        onboardingDelegate?.onboardingCompleted(self)
    }
}

// Disabling orientation changes
extension OnboardingNavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}
