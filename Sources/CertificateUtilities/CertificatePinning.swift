// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveCore
import os.log

public class PinningCertificateEvaluator: NSObject, URLSessionDelegate {
  struct ExcludedPinningHostUrls {
    static let urls = [
      "laptop-updates.brave.com",
      "updates.bravesoftware.com",
      "updates-cdn.bravesoftware.com",
    ]
  }

  private let hosts: [String]

  public init(hosts: [String]) {
    self.hosts = hosts
  }
  
  nonisolated public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
      if let serverTrust = challenge.protectionSpace.serverTrust {
        let host = challenge.protectionSpace.host
        let port = challenge.protectionSpace.port
        
        if ExcludedPinningHostUrls.urls.contains(host) {
          return (.performDefaultHandling, nil)
        }
        
        if !self.canPinHost(host) {
          Logger.module.error("Host not specified for pinning: \(host)")
          self.fatalErrorInDebugModeIfPinningFailed()
          return (.cancelAuthenticationChallenge, nil)
        }
        
        let result = BraveCertificateUtility.verifyTrust(serverTrust,
                                                         host: host,
                                                         port: port)
        
        // Cert is valid and should be pinned
        if result == 0 {
          return (.useCredential, URLCredential(trust: serverTrust))
        }
        
        // Cert is valid and should not be pinned
        // Let the system handle it and we'll show an error if the system cannot validate it
        if result == Int32.min {
          return (.performDefaultHandling, nil)
        }
        
        // Cert is invalid and cannot be pinned
        let errorCode = Int32.min
        let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] ?? []
        
        let underlyingError = NSError(domain: kCFErrorDomainCFNetwork as String,
                                      code: Int(errorCode),
                                      userInfo: ["_kCFStreamErrorCodeKey": Int(errorCode)])
        
        let error = NSError(domain: kCFErrorDomainCFNetwork as String,
                            code: Int(errorCode),
                            userInfo: [NSURLErrorFailingURLErrorKey: challenge.protectionSpace.urlString() as Any,
                                       "NSErrorPeerCertificateChainKey": certificateChain,
                                               NSUnderlyingErrorKey: underlyingError])
        
        print(error)
        fatalErrorInDebugModeIfPinningFailed()
        return (.cancelAuthenticationChallenge, nil)
      }
    }
    
    return (.performDefaultHandling, nil)
  }

  private func canPinHost(_ host: String) -> Bool {
    return hosts.contains(host)
  }

  private func error(reason: String) -> NSError {
    return NSError(domain: "com.brave.pinning-certificate-evaluator", code: -1, userInfo: [NSLocalizedDescriptionKey: reason])
  }

  func evaluate(_ trust: SecTrust, forHost host: String) throws {
    if ExcludedPinningHostUrls.urls.contains(host) {
      return
    }
    
    if !self.canPinHost(host) {
      Logger.module.error("Host not specified for pinning: \(host)")
      self.fatalErrorInDebugModeIfPinningFailed()
      throw self.error(reason: "Host not specified for pinning: \(host)")
    }
    
    let result = BraveCertificateUtility.verifyTrust(trust,
                                                     host: host,
                                                     port: 443)
    
    // Cert is valid and should be pinned
    if result == 0 {
      return
    }
    
    // Cert is valid and should not be pinned
    // Let the system handle it and we'll show an error if the system cannot validate it
    if result == Int32.min {
      // Trust also the built in system certificates (false)
      guard SecTrustSetAnchorCertificatesOnly(trust, false) == errSecSuccess else {
        throw error(reason: "Certificate Anchor Only Failed")
      }
      
      // Validate Host
      guard SecTrustSetPolicies(trust, SecPolicyCreateSSL(true, host as CFString)) == errSecSuccess else {
        throw error(reason: "Trust Set Policies for Host Failed")
      }

      var err: CFError?
      if !SecTrustEvaluateWithError(trust, &err) {
        if let err = err as Error? {
          throw error(reason: "Trust Evaluation Failed: \(err)")
        }

        throw error(reason: "Unable to Evaluate Trust")
      }
      
      return
    }
    
    // Cert is invalid and cannot be pinned
    let errorCode = Int32.min
    let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] ?? []
    
    let underlyingError = NSError(domain: kCFErrorDomainCFNetwork as String,
                                  code: Int(errorCode),
                                  userInfo: ["_kCFStreamErrorCodeKey": Int(errorCode)])
    
    let error = NSError(domain: kCFErrorDomainCFNetwork as String,
                        code: Int(errorCode),
                        userInfo: [NSURLErrorFailingURLErrorKey: host as Any,
                                   "NSErrorPeerCertificateChainKey": certificateChain,
                                           NSUnderlyingErrorKey: underlyingError])
    
    fatalErrorInDebugModeIfPinningFailed()
    throw self.error(reason: error.localizedDescription)
  }

  private func fatalErrorInDebugModeIfPinningFailed() {
    if !AppConstants.buildChannel.isPublic {
      assertionFailure("An SSL Pinning error has occurred")
    }
  }
}
