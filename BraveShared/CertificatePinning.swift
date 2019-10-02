// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

private let log = Logger.browserLogger

public class PinningCertificateEvaluator: NSObject, URLSessionDelegate {
    private let hosts: [String]
    private let certificates: [SecCertificate]
    
    public init(hosts: [String]) {
        self.hosts = hosts
        
        // Load certificates in the main bundle..
        self.certificates = {
            let paths = Set([".cer", ".CER", ".crt", ".CRT", ".der", ".DER"].map {
                Bundle.main.paths(forResourcesOfType: $0, inDirectory: nil)
            }.joined())
            
            return paths.compactMap({ path -> SecCertificate? in
                guard let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData else {
                    return nil
                }
                return SecCertificateCreateWithData(nil, certificateData)
            })
        }()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Certificate pinning
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                do {
                    let host = challenge.protectionSpace.host
                    if !canPinHost(host) {
                        throw error(reason: "Host not specified for pinning: \(host)")
                    }
                    
                    try evaluate(serverTrust, forHost: host)
                    return completionHandler(.useCredential, URLCredential(trust: serverTrust))
                } catch {
                    log.error(error)
                    return completionHandler(.cancelAuthenticationChallenge, nil)
                }
            }
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }
        return completionHandler(.performDefaultHandling, nil)
    }
    
    private func canPinHost(_ host: String) -> Bool {
        return hosts.contains(host)
    }
    
    private func error(reason: String) -> NSError {
        return NSError(domain: "com.brave.pinning-certificate-evaluator", code: -1, userInfo: [NSLocalizedDescriptionKey: reason])
    }
    
    private func evaluate(_ trust: SecTrust, forHost host: String) throws {
        // Certificate validation
        guard !certificates.isEmpty else {
            throw error(reason: "Empty Certificates")
        }
        
        // Default validation
        guard SecTrustSetPolicies(trust, SecPolicyCreateSSL(true, nil)) == errSecSuccess else {
            throw error(reason: "Trust Set Policies Failed")
        }
        
        var result: SecTrustResultType = .invalid
        guard SecTrustEvaluate(trust, &result) == errSecSuccess, result == .unspecified || result == .proceed else {
            throw error(reason: "Trust Evaluation Failed")
        }
        
        // Host validation
        guard SecTrustSetPolicies(trust, SecPolicyCreateSSL(true, host as CFString)) == errSecSuccess else {
            throw error(reason: "Trust Set Policies for Host Failed")
        }
        
        result = .invalid
        guard SecTrustEvaluate(trust, &result) == errSecSuccess, result == .unspecified || result == .proceed else {
            throw error(reason: "Trust Evaluation Failed")
        }
        
        // Certificate binary matching
        let serverCertificates = Set((0..<SecTrustGetCertificateCount(trust))
            .compactMap { SecTrustGetCertificateAtIndex(trust, $0) }
            .compactMap({ SecCertificateCopyData($0) as Data }))
        
        // Set Certificate validation
        let clientCertificates = Set(certificates.compactMap({ SecCertificateCopyData($0) as Data }))
        if serverCertificates.isDisjoint(with: clientCertificates) {
            throw error(reason: "Pinning Failed")
        }
    }
}
