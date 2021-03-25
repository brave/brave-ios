// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Intents
import CoreSpotlight
import MobileCoreServices

private let log = Logger.browserLogger

public class OpenWebsiteIntentHandler: NSObject, OpenWebsiteIntentHandling {

    public func handle(intent: OpenWebsiteIntent, completion: @escaping (OpenWebsiteIntentResponse) -> Void) {
        
    }
    
    public func confirm(intent: OpenWebsiteIntent, completion: @escaping (OpenWebsiteIntentResponse) -> Void) {
        guard let urlString = intent.websiteURL, let websiteURL = URL(string: urlString) else {
            
            completion(OpenWebsiteIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        log.debug("URL generated from Intent's website URL Text \(websiteURL)")

        completion(OpenWebsiteIntentResponse(code: .ready, userActivity: nil))
    }
}
