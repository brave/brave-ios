// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

protocol BookmarkFormFieldsProtocol where Self: UIView {
    var titleTextField: UITextField { get }
    /// Nil by default
    var urlTextField: UITextField? { get }
    
    var delegate: BookmarkDetailsViewDelegate? { get set }
    
    func validateFields() -> Bool
}

extension BookmarkFormFieldsProtocol {
    var urlTextField: UITextField? { return nil }
    
    func validateFields() -> Bool {
        // Only title field is implemented
        if urlTextField == nil {
            guard let titleText = titleTextField.text else { return false }
            return validateTitle(titleText)
        }
        
        guard let title = titleTextField.text, let url = urlTextField?.text else { return false }
        
        return validateTitle(title) && validateUrl(url)
    }
    
    private func validateTitle(_ title: String) -> Bool {
        return !title.isEmpty
    }
    
    private func validateUrl(_ urlString: String) -> Bool {
        return URL(string: urlString)?.schemeIsValid == true
    }
}
