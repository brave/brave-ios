// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, *)
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
let viewController: ViewController
init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
// MARK: - UIViewControllerRepresentable
func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<UIViewControllerPreview<ViewController>>) {
return
    }
}
#endif
