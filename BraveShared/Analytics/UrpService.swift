/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SafariServices
import Shared
import SwiftyJSON

private let log = Logger.browserLogger

enum UrpError {
    case networkError, downloadIdNotFound, ipNotFound, endpointError
}

private class PinningCertificateEvaluator: NSObject, URLSessionDelegate {
    private let hosts: [String]
    private let certificates: [SecCertificate]
    
    init(hosts: [String]) {
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
                } catch let error {
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


/// Api endpoints for user referral program.
struct UrpService {
    private static let apiKeyParam = "api_key"
    private static let downLoadIdKeyParam = "download_id"

    let host: String
    private let apiKey: String
    let sessionManager: URLSession
    private let certificateEvaluator: PinningCertificateEvaluator

    init?(host: String, apiKey: String) {
        self.host = host
        self.apiKey = apiKey

        guard let hostUrl = URL(string: host), let normalizedHost = hostUrl.normalizedHost else { return nil }

        // Certificate pinning
        certificateEvaluator = PinningCertificateEvaluator(hosts: [normalizedHost])
        
        sessionManager = URLSession(configuration: .default, delegate: certificateEvaluator, delegateQueue: nil)
    }

    func referralCodeLookup(completion: @escaping (ReferralData?, UrpError?) -> Void) {
        guard var endPoint = URL(string: host) else {
            completion(nil, .endpointError)
            UrpLog.log("Host not a url: \(host)")
            return
        }
        endPoint.appendPathComponent("promo/initialize/ua")

        let params = [UrpService.apiKeyParam: apiKey]

        sessionManager.urpApiRequest(endPoint: endPoint, params: params) { response in
            switch response {
            case .success(let data):
                log.debug("Referral code lookup response: \(data)")
                UrpLog.log("Referral code lookup response: \(data)")
                
                let json = JSON(data)
                let referral = ReferralData(json: json)
                completion(referral, nil)
                
            case .failure(let error):
                log.error("Referral code lookup response: \(error)")
                UrpLog.log("Referral code lookup response: \(error)")
                
                completion(nil, .endpointError)
            }
        }
    }
    
    func checkIfAuthorizedForGrant(with downloadId: String, completion: @escaping (Bool?, UrpError?) -> Void) {
        guard var endPoint = URL(string: host) else {
            completion(nil, .endpointError)
            return
        }
        endPoint.appendPathComponent("promo/activity")

        let params = [
            UrpService.apiKeyParam: apiKey,
            UrpService.downLoadIdKeyParam: downloadId
        ]

        sessionManager.urpApiRequest(endPoint: endPoint, params: params) { response in
            switch response {
            case .success(let data):
                log.debug("Check if authorized for grant response: \(data)")
                let json = JSON(data)
                completion(json["finalized"].boolValue, nil)
                
            case .failure(let error):
                log.error("Check if authorized for grant response: \(error)")
                completion(nil, .endpointError)
            }
        }
    }

    func fetchCustomHeaders(completion: @escaping ([CustomHeaderData], UrpError?) -> Void) {
        guard var endPoint = URL(string: host) else {
            completion([], .endpointError)
            return
        }
        endPoint.appendPathComponent("promo/custom-headers")

        let params = [UrpService.apiKeyParam: apiKey]

        sessionManager.request(endPoint, parameters: params) { response in
            switch response {
            case .success(let data):
                let json = JSON(data)
                let customHeaders = CustomHeaderData.customHeaders(from: json)
                completion(customHeaders, nil)
                
            case .failure(let error):
                log.error(error)
                completion([], .endpointError)
            }
        }
    }
}

extension URLSession {
    /// All requests to referral api use PUT method, accept and receive json.
    func urpApiRequest(endPoint: URL, params: [String: String], completion: @escaping (Result<Any, Error>) -> Void) {
        
        self.request(endPoint, method: .put, parameters: params, encoding: .json) { response in
            completion(response)
        }
    }
    
    @discardableResult
    func request(_ url: URL, method: HTTPMethod = .get, parameters: [String: Any], encoding: ParameterEncoding = .query, _ completion: @escaping (Result<Any, Error>) -> Void) -> URLSessionDataTask! {
        do {
            let request = try buildRequest(url, method: method, parameters: parameters, encoding: encoding)
            
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    return completion(.failure(error))
                }
                
                guard let data = data else {
                    return completion(.failure(NSError(domain: "com.brave.url.session.build-request", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from the server"])))
                }
                
                do {
                    completion(.success(try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
            return task
        } catch {
            log.error(error)
            return nil
        }
    }
}

extension URLSession {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case head = "HEAD"
        case delete = "DELETE"
    }
    
    enum ParameterEncoding {
        case json
        case query
    }
    
    func buildRequest(_ url: URL, method: HTTPMethod, headers: [String: String] = [:], parameters: [String: Any], encoding: ParameterEncoding) throws -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers.forEach({ request.setValue($0.value, forHTTPHeaderField: $0.key) })
        switch encoding {
        case .json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        case .query:
            var queryParameters = [URLQueryItem]()
            for item in parameters {
                if let value = item.value as? String {
                    queryParameters.append(URLQueryItem(name: item.key, value: value))
                }
                throw NSError(domain: "com.brave.url.session.build-request", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid Parameter cannot be serialized to query url: \(item.key)"
                ])
            }
            
            var urlComponents = URLComponents()
            urlComponents.scheme = request.url?.scheme
            urlComponents.host = request.url?.host
            urlComponents.path = request.url?.path ?? ""
            urlComponents.queryItems = queryParameters
            request.url = urlComponents.url
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = nil
        }
        
        return request
    }
}
