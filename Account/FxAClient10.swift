/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import Foundation
import FxA
import Deferred
import SwiftyJSON

public let FxAClientErrorDomain = "com.brave.fxa.error"
public let FxAClientUnknownError = NSError(domain: FxAClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])

let KeyLength: Int = 32

public struct FxALoginResponse {
    public let remoteEmail: String
    public let uid: String
    public let verified: Bool
    public let sessionToken: Data
    public let keyFetchToken: Data
}

public struct FxAccountRemoteError {
    static let AttemptToOperateOnAnUnverifiedAccount: Int32     = 104
    static let InvalidAuthenticationToken: Int32                = 110
    static let EndpointIsNoLongerSupported: Int32               = 116
    static let IncorrectLoginMethodForThisAccount: Int32        = 117
    static let IncorrectKeyRetrievalMethodForThisAccount: Int32 = 118
    static let IncorrectAPIVersionForThisAccount: Int32         = 119
    static let UnknownDevice: Int32                             = 123
    static let DeviceSessionConflict: Int32                     = 124
    static let UnknownError: Int32                              = 999
}

public struct FxAKeysResponse {
    let kA: Data
    let wrapkB: Data
}

public struct FxASignResponse {
    let certificate: String
}

public struct FxAStatusResponse {
    let exists: Bool
}

public struct FxADevicesResponse {
    let devices: [FxADevice]
}

public struct FxANotifyResponse {
    let success: Bool
}

public struct FxAOAuthResponse {
    let accessToken: String
}

public struct FxAProfileResponse {
    let email: String
    let uid: String
    let avatarURL: String?
    let displayName: String?
}

public struct FxADeviceDestroyResponse {
    let success: Bool
}

// fxa-auth-server produces error details like:
//        {
//            "code": 400, // matches the HTTP status code
//            "errno": 107, // stable application-level error number
//            "error": "Bad Request", // string description of the error type
//            "message": "the value of salt is not allowed to be undefined",
//            "info": "https://docs.dev.lcip.og/errors/1234" // link to more info on the error
//        }

public enum FxAClientError {
    case remote(RemoteError)
    case local(NSError)
}

// Be aware that string interpolation doesn't work: rdar://17318018, much good that it will do.
extension FxAClientError: MaybeErrorType {
    public var description: String {
        switch self {
        case let .remote(error):
            let errorString = error.error ?? NSLocalizedString("Missing error", comment: "Error for a missing remote error number")
            let messageString = error.message ?? NSLocalizedString("Missing message", comment: "Error for a missing remote error message")
            return "<FxAClientError.Remote \(error.code)/\(error.errno): \(errorString) (\(messageString))>"
        case let .local(error):
            return "<FxAClientError.Local Error Domain=\(error.domain) Code=\(error.code) \"\(error.localizedDescription)\">"
        }
    }
}

public struct RemoteError {
    let code: Int32
    let errno: Int32
    let error: String?
    let message: String?
    let info: String?

    var isUpgradeRequired: Bool {
        return errno == FxAccountRemoteError.EndpointIsNoLongerSupported
            || errno == FxAccountRemoteError.IncorrectLoginMethodForThisAccount
            || errno == FxAccountRemoteError.IncorrectKeyRetrievalMethodForThisAccount
            || errno == FxAccountRemoteError.IncorrectAPIVersionForThisAccount
    }

    var isInvalidAuthentication: Bool {
        return code == 401
    }

    var isUnverified: Bool {
        return errno == FxAccountRemoteError.AttemptToOperateOnAnUnverifiedAccount
    }
}

open class FxAClient10 {
    let authURL: URL
    let oauthURL: URL
    let profileURL: URL

    public init(authEndpoint: URL? = nil, oauthEndpoint: URL? = nil, profileEndpoint: URL? = nil) {
        self.authURL = authEndpoint ?? ProductionFirefoxAccountConfiguration().authEndpointURL as URL
        self.oauthURL = oauthEndpoint ?? ProductionFirefoxAccountConfiguration().oauthEndpointURL as URL
        self.profileURL = profileEndpoint ?? ProductionFirefoxAccountConfiguration().profileEndpointURL as URL
    }

    open class func KW(_ kw: String) -> Data {
        return ("identity.mozilla.com/picl/v1/" + kw).utf8EncodedData
    }

    /**
     * The token server accepts an X-Client-State header, which is the
     * lowercase-hex-encoded first 16 bytes of the SHA-256 hash of the
     * bytes of kB.
     */
    open class func computeClientState(_ kB: Data) -> String? {
        if kB.count != 32 {
            return nil
        }
        return kB.sha256.subdata(in: 0..<16).hexEncodedString
    }

    open class func quickStretchPW(_ email: Data, password: Data) -> Data {
        var salt = KW("quickStretch")
        salt.append(":".utf8EncodedData)
        salt.append(email)
        return (password as NSData).derivePBKDF2HMACSHA256Key(withSalt: salt as Data?, iterations: 1000, length: 32)
    }

    open class func computeUnwrapKey(_ stretchedPW: Data) -> Data {
        let salt: Data = Data()
        let contextInfo: Data = KW("unwrapBkey")
        let bytes = (stretchedPW as NSData).deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(KeyLength))
        return bytes!
    }

    fileprivate class func remoteError(fromJSON json: JSON, statusCode: Int) -> RemoteError? {
        if json.error != nil || 200 <= statusCode && statusCode <= 299 {
            return nil
        }

        if let code = json["code"].int32 {
            if let errno = json["errno"].int32 {
                return RemoteError(code: code, errno: errno,
                                   error: json["error"].string,
                                   message: json["message"].string,
                                   info: json["info"].string)
            }
        }
        return nil
    }

    fileprivate class func loginResponse(fromJSON json: JSON) -> FxALoginResponse? {
        guard json.error == nil,
            let uid = json["uid"].string,
            let verified = json["verified"].bool,
            let sessionToken = json["sessionToken"].string,
            let keyFetchToken = json["keyFetchToken"].string else {
                return nil
        }

        return FxALoginResponse(remoteEmail: "", uid: uid, verified: verified,
            sessionToken: sessionToken.hexDecodedData, keyFetchToken: keyFetchToken.hexDecodedData)
    }

    fileprivate class func keysResponse(fromJSON keyRequestKey: Data, json: JSON) -> FxAKeysResponse? {
        guard json.error == nil,
            let bundle = json["bundle"].string else {
                return nil
        }

        let data = bundle.hexDecodedData
        guard data.count == 3 * KeyLength else {
            return nil
        }

        let ciphertext = data.subdata(in: 0..<(2 * KeyLength))
        let MAC = data.subdata(in: (2 * KeyLength)..<(3 * KeyLength))

        let salt: Data = Data()
        let contextInfo: Data = KW("account/keys")
        let bytes = (keyRequestKey as NSData).deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
        let respHMACKey = bytes?.subdata(in: 0..<KeyLength)
        let respXORKey = bytes?.subdata(in: KeyLength..<(3 * KeyLength))

        guard let hmacKey = respHMACKey,
            ciphertext.hmacSha256WithKey(hmacKey) == MAC else {
            NSLog("Bad HMAC in /keys response!")
            return nil
        }

        guard let xorKey = respXORKey,
            let xoredBytes = ciphertext.xoredWith(xorKey) else {
            return nil
        }

        let kA = xoredBytes.subdata(in: 0..<KeyLength)
        let wrapkB = xoredBytes.subdata(in: KeyLength..<(2 * KeyLength))
        return FxAKeysResponse(kA: kA, wrapkB: wrapkB)
    }

    fileprivate class func signResponse(fromJSON json: JSON) -> FxASignResponse? {
        guard json.error == nil,
            let cert = json["cert"].string else {
                return nil
        }

        return FxASignResponse(certificate: cert)
    }

    fileprivate class func statusResponse(fromJSON json: JSON) -> FxAStatusResponse? {
        guard json.error == nil,
            let exists = json["exists"].bool else {
                return nil
        }

        return FxAStatusResponse(exists: exists)
    }

    fileprivate class func devicesResponse(fromJSON json: JSON) -> FxADevicesResponse? {
        guard json.error == nil,
            let jsonDevices = json.array else {
                return nil
        }

        let devices = jsonDevices.flatMap { (jsonDevice) -> FxADevice? in
            return FxADevice.fromJSON(jsonDevice)
        }

        return FxADevicesResponse(devices: devices)
    }
    
    fileprivate class func notifyResponse(fromJSON json: JSON) -> FxANotifyResponse {
        return FxANotifyResponse(success: json.error == nil)
    }
    
    fileprivate class func deviceDestroyResponse(fromJSON json: JSON) -> FxADeviceDestroyResponse {
        return FxADeviceDestroyResponse(success: json.error == nil)
    }

    fileprivate class func oauthResponse(fromJSON json: JSON) -> FxAOAuthResponse? {
        guard json.error == nil,
            let accessToken = json["access_token"].string else {
                return nil
        }
        
        return FxAOAuthResponse(accessToken: accessToken)
    }
    
    fileprivate class func profileResponse(fromJSON json: JSON) -> FxAProfileResponse? {
        guard json.error == nil,
            let uid = json["uid"].string,
            let email = json["email"].string else {
                return nil
        }
        
        let avatarURL = json["avatar"].string
        let displayName = json["displayName"].string
        
        return FxAProfileResponse(email: email, uid: uid, avatarURL: avatarURL, displayName: displayName)
    }

    lazy fileprivate var alamofire: SessionManager = {
        let ua = UserAgent.fxaUserAgent
        let configuration = URLSessionConfiguration.ephemeral
        var defaultHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = ua
        configuration.httpAdditionalHeaders = defaultHeaders
        return SessionManager(configuration: configuration)
    }()

    open func login(_ emailUTF8: Data, quickStretchedPW: Data, getKeys: Bool) -> Deferred<Maybe<FxALoginResponse>> {
        let authPW = (quickStretchedPW as NSData).deriveHKDFSHA256Key(withSalt: Data(), contextInfo: FxAClient10.KW("authPW"), length: 32) as NSData

        let parameters = [
            "email": NSString(data: emailUTF8, encoding: String.Encoding.utf8.rawValue)!,
            "authPW": authPW.base16EncodedString(options: NSDataBase16EncodingOptions.lowerCase) as NSString,
        ]

        var URL: URL = self.authURL.appendingPathComponent("/account/login")
        if getKeys {
            var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)!
            components.query = "keys=true"
            URL = components.url!
        }
        var mutableURLRequest = URLRequest(url: URL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.httpBody = JSON(parameters).stringValue()?.utf8EncodedData

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.loginResponse)
    }

    open func status(forUID uid: String) -> Deferred<Maybe<FxAStatusResponse>> {
        let statusURL = self.authURL.appendingPathComponent("/account/status").withQueryParam("uid", value: uid)
        var mutableURLRequest = URLRequest(url: statusURL)
        mutableURLRequest.httpMethod = HTTPMethod.get.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.statusResponse)
    }

    open func devices(withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxADevicesResponse>> {
        let URL = self.authURL.appendingPathComponent("/account/devices")
        var mutableURLRequest = URLRequest(url: URL)
        mutableURLRequest.httpMethod = HTTPMethod.get.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))!
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.devicesResponse)
    }
    
    open func notify(deviceIDs: [GUID], collectionsChanged collections: [String], reason: String, withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxANotifyResponse>> {
        let httpBody = JSON([
            "to": deviceIDs,
            "payload": [
                "version": 1,
                "command": "sync:collection_changed",
                "data": [
                    "collections": collections,
                    "reason": reason
                ]
            ]
        ])
        return self.notify(httpBody: httpBody, withSessionToken: sessionToken)
    }

    open func notifyAll(ownDeviceId: GUID, collectionsChanged collections: [String], reason: String, withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxANotifyResponse>> {
        let httpBody = JSON([
            "to": "all",
            "excluded": [ownDeviceId],
            "payload": [
                "version": 1,
                "command": "sync:collection_changed",
                "data": [
                    "collections": collections,
                    "reason": reason
                ]
            ]
        ])
        return self.notify(httpBody: httpBody, withSessionToken: sessionToken)
    }

    fileprivate func notify(httpBody: JSON, withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxANotifyResponse>> {
        let URL = self.authURL.appendingPathComponent("/account/devices/notify")
        var mutableURLRequest = URLRequest(url: URL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.httpBody = httpBody.stringValue()?.utf8EncodedData

        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))!
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.notifyResponse)
    }

    open func destroyDevice(ownDeviceId: GUID, withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxADeviceDestroyResponse>> {
        let URL = self.authURL.appendingPathComponent("/account/device/destroy")
        var mutableURLRequest = URLRequest(url: URL)
        let httpBody: JSON = JSON(["id": ownDeviceId])
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.httpBody = httpBody.stringValue()?.utf8EncodedData

        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))!
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.deviceDestroyResponse)
    }

    open func registerOrUpdate(device: FxADevice, withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxADevice>> {
        let URL = self.authURL.appendingPathComponent("/account/device")
        var mutableURLRequest = URLRequest(url: URL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.httpBody = device.toJSON().stringValue()?.utf8EncodedData

        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))!
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxADevice.fromJSON)
    }
    
    open func oauthAuthorize(withSessionToken sessionToken: NSData, keyPair: RSAKeyPair, certificate: String) -> Deferred<Maybe<FxAOAuthResponse>> {
        let audience = self.getAudience(forURL: self.oauthURL)
        
        let assertion = JSONWebTokenUtils.createAssertionWithPrivateKeyToSign(with: keyPair.privateKey,
                                                                              certificate: certificate,
                                                                              audience: audience)
        
        let oauthAuthorizationURL = self.oauthURL.appendingPathComponent("/authorization")
        var mutableURLRequest = URLRequest(url: oauthAuthorizationURL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "assertion": assertion,
            "client_id": AppConstants.FxAiOSClientId,
            "response_type": "token",
            "scope": "profile",
            "ttl": "300"
        ]
        
        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))!
        
        guard let httpBody = JSON(parameters as NSDictionary).stringValue()?.utf8EncodedData else {
            return deferMaybe(FxAClientError.local(FxAClientUnknownError))
        }
        
        mutableURLRequest.httpBody = httpBody
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)
        
        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.oauthResponse)
    }
    
    open func getProfile(withSessionToken sessionToken: NSData) -> Deferred<Maybe<FxAProfileResponse>> {
        let keyPair = RSAKeyPair.generate(withModulusSize: 1024)!
        return self.sign(sessionToken as Data, publicKey: keyPair.publicKey) >>== { signResult in
            return self.oauthAuthorize(withSessionToken: sessionToken, keyPair: keyPair, certificate: signResult.certificate) >>== { oauthResult in
                
                let profileURL = self.profileURL.appendingPathComponent("/profile")
                var mutableURLRequest = URLRequest(url: profileURL)
                mutableURLRequest.httpMethod = HTTPMethod.get.rawValue
                
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.setValue("Bearer " + oauthResult.accessToken, forHTTPHeaderField: "Authorization")
                
                return self.makeRequest(mutableURLRequest, responseHandler: FxAClient10.profileResponse)
            }
        }
    }
    
    open func getAudience(forURL URL: URL) -> String {
        if let port = URL.port {
            return "\(URL.scheme!)://\(URL.host!):\(port)"
        } else {
            return "\(URL.scheme!)://\(URL.host!)"
        }
    }

    fileprivate func makeRequest<T>(_ request: URLRequest, responseHandler: @escaping (JSON) -> T?) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        alamofire.request(request)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                withExtendedLifetime(self.alamofire) {
                    if let error = response.result.error {
                        deferred.fill(Maybe(failure: FxAClientError.local(error as NSError)))
                        return
                    }

                    if let data = response.result.value {
                        let json = JSON(data)
                        if let remoteError = FxAClient10.remoteError(fromJSON: json, statusCode: response.response!.statusCode) {
                            deferred.fill(Maybe(failure: FxAClientError.remote(remoteError)))
                            return
                        }

                        if let response = responseHandler(json) {
                            deferred.fill(Maybe(success: response))
                            return
                        }
                    }

                    deferred.fill(Maybe(failure: FxAClientError.local(FxAClientUnknownError)))
                }
        }

        return deferred
    }
}

extension FxAClient10: FxALoginClient {

    func keyPair() -> Deferred<Maybe<KeyPair>> {
        let result = RSAKeyPair.generate(withModulusSize: 2048)! // TODO: debate key size and extract this constant.
        return Deferred(value: Maybe(success: result))
    }

    open func keys(_ keyFetchToken: Data) -> Deferred<Maybe<FxAKeysResponse>> {
        let URL = self.authURL.appendingPathComponent("/account/keys")
        var mutableURLRequest = URLRequest(url: URL)
        mutableURLRequest.httpMethod = HTTPMethod.get.rawValue

        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("keyFetchToken")
        let key = (keyFetchToken as NSData).deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))!
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        let rangeStart = 2 * KeyLength
        let keyRequestKey = key.subdata(in: rangeStart..<(rangeStart + KeyLength))

        return makeRequest(mutableURLRequest) { FxAClient10.keysResponse(fromJSON: keyRequestKey, json: $0) }
    }

    open func sign(_ sessionToken: Data, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let parameters = [
            "publicKey": publicKey.jsonRepresentation() as NSDictionary,
            "duration": NSNumber(value: OneDayInMilliseconds), // The maximum the server will allow.
        ]
        
        let url = self.authURL.appendingPathComponent("/certificate/sign")
        var mutableURLRequest = URLRequest(url: url)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.httpBody = JSON(parameters as NSDictionary).stringValue()?.utf8EncodedData

        let salt: Data = Data()
        let contextInfo: Data = FxAClient10.KW("sessionToken")
        let key = (sessionToken as NSData).deriveHKDFSHA256Key(withSalt: salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))!
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.signResponse)
    }
}
