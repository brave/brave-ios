// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class OnboardingAdsCountdownViewController: OnboardingViewController {
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            (self.view as! View).countdownView.animate(from: 0.0, to: 1.0, duration: 3.0) // swiftlint:disable:this force_cast
            
            var secondsPast = 0
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
                DispatchQueue.main.async {
                    (self.view as! View).countdownLabel.text = "\(3 - secondsPast)"
                    secondsPast += 1
                    
                    if secondsPast == 3 {
                        timer.invalidate()
                    }
                }
            })
        }
    }
}
