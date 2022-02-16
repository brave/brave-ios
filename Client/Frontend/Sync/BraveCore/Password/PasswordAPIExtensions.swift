// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import BraveShared
import CoreData
import Shared

private var log = Logger.syncLogger

typealias Credential = (username: String, password: String)

extension PasswordForm {
    open func toDict(formSubmitURL: String, httpRealm: String = "") -> [String: String] {
        return [
            "hostname": signOnRealm ?? "",
            "formSubmitURL": formSubmitURL,
            "httpRealm": httpRealm,
            "username": usernameValue ?? "",
            "password": passwordValue ?? "",
            "usernameField": usernameElement ?? "",
            "passwordField": passwordElement ?? ""
        ]
    }
}

extension BravePasswordAPI {

    func fetchCredentialsFromScript(_ url: URL, script: [String: Any]) -> Credential? {
        guard let username = script["username"] as? String,
              let password = script["password"] as? String else {
                return nil
        }
        
       return (username, password)
    }
}
