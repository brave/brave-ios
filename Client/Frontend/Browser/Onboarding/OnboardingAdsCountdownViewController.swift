// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UserNotifications

class OnboardingAdsCountdownViewController: OnboardingViewController, UNUserNotificationCenterDelegate {
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.countdownText = "3"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        contentView.animate(from: 0.0, to: 1.0, duration: 5.0) { [weak self] in
            self?.generateNotification()
        }
    }
    
    private func generateNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    let content = UNMutableNotificationContent()
                    content.title = "This is your first Brave ad"
                    content.body = "Tap here to learn more."
                    content.sound = .default
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
                    
                    let notification = UNNotificationRequest(identifier: UUID().uuidString,
                                                             content: content,
                                                             trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(notification)
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        defer { center.delegate = nil }
        completionHandler([.alert])
    }
}
