// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import DeviceCheck

/// A structure used to register a device for Brave's DeviceCheck enrollment
public struct DeviceCheckRegistration: Codable {
  // The enrollment blob is a Base64 Encoded `DeviceCheckEnrollment` structure
  let enrollmentBlob: DeviceCheckEnrollment
  
  /// The signature is base64(token) + the base64(publicKey) signed using the privateKey.
  let signature: String
  
  public init(enrollmentBlob: DeviceCheckEnrollment, signature: String) {
    self.enrollmentBlob = enrollmentBlob
    self.signature = signature
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    guard let data = Data(base64Encoded: try container.decode(String.self, forKey: .enrollmentBlob)) else {
      throw NSError(domain: "com.brave.device.check.enrollment", code: -1, userInfo: [
        NSLocalizedDescriptionKey: "Cannot decode enrollmentBlob"
      ])
    }
    
    enrollmentBlob = try JSONDecoder().decode(DeviceCheckEnrollment.self, from: data)
    signature = try container.decode(String.self, forKey: .signature)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let data = try JSONEncoder().encode(enrollmentBlob).base64EncodedString()
    try container.encode(data, forKey: .enrollmentBlob)
    try container.encode(signature, forKey: .signature)
  }
  
  enum CodingKeys: String, CodingKey {
    case enrollmentBlob
    case signature
  }
}

public struct DeviceCheckEnrollment: Codable {
  // Not sure yet
  let paymentID: String
  
  // The public key in ASN.1 DER, PEM PKCS#8 Format.
  let publicKey: String
  
  // The device check token base64 encoded.
  let deviceToken: String
}

/// A structure used to respond to a nonce challenge
public struct AttestationVerifcation: Codable {
  // The attestation blob is a base-64 encoded version of `AttestationBlob`
  let attestationBlob: AttestationBlob
  
  // The signature is the `nonce` signed by the privateKey and base-64 encoded.
  let signature: String
  
  public init(attestationBlob: AttestationBlob, signature: String) {
    self.attestationBlob = attestationBlob
    self.signature = signature
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    guard let data = Data(base64Encoded: try container.decode(String.self, forKey: .attestationBlob)) else {
      throw NSError(domain: "com.brave.device.check.enrollment", code: -1, userInfo: [
        NSLocalizedDescriptionKey: "Cannot decode attestationBlob"
      ])
    }
    
    attestationBlob = try JSONDecoder().decode(AttestationBlob.self, from: data)
    signature = try container.decode(String.self, forKey: .signature)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let data = try JSONEncoder().encode(attestationBlob).base64EncodedString()
    try container.encode(data, forKey: .attestationBlob)
    try container.encode(signature, forKey: .signature)
  }
  
  enum CodingKeys: String, CodingKey {
    case attestationBlob
    case signature
  }
}

public struct AttestationBlob: Codable {
  // The nonce is a UUIDv4 string
  let nonce: String
}

class DeviceCheckClient {
  
  // A structure representing an error returned by the server
  struct DeviceCheckError: Error, Codable {
    // The error message
    let message: String
    
    // The http error code
    let code: Int
  }
  
  // The ID of the private-key stored in the secure-enclave chip
  private static let privateKeyId = "com.brave.device.check.private.key"
  
  // Registers a device with the server using the device-check token
  public func registerDevice(enrollment: DeviceCheckRegistration, _ completion: @escaping (Error?) -> Void) {
    do {
      try executeRequest(.register(enrollment)) { (result: Result<Data, Error>) in
        if case .failure(let error) = result {
          return completion(error)
        }
        
        completion(nil)
      }
    } catch {
      completion(error)
    }
  }
  
  // Retrieves existing attestations for this device and returns a nonce if any
  public func getAttestation(paymentId: String, _ completion: @escaping (AttestationBlob?, Error?) -> Void) {
    do {
      guard let privateKey = try Cryptography.getExistingKey(id: DeviceCheckClient.privateKeyId) else {
        throw CryptographyError(code: -1, description: "Unable to retrieve existing private key")
      }
      
      guard let publicKey = try privateKey.getPublicKeyExternalRepresentationAsPEM() else {
        throw CryptographyError(code: -1, description: "Unable to retrieve public key")
      }
      
      let parameters = [
        "publicKey": publicKey,
        "paymentID": paymentId
      ]
      
      try executeRequest(.getAttestation(parameters)) { (result: Result<AttestationBlob, Error>) in
        switch result {
        case .success(let blob):
          completion(blob, nil)
          
        case .failure(let error):
          completion(nil, error)
        }
      }
    } catch {
      completion(nil, error)
    }
  }
  
  // Sends the attestation to the server along with the nonce and the challenge signature
  public func setAttestation(nonce: String, _ completion: @escaping (Error?) -> Void) {
    do {
      guard let privateKey = try Cryptography.getExistingKey(id: DeviceCheckClient.privateKeyId) else {
        throw CryptographyError(code: -1, description: "Unable to retrieve existing private key")
      }
      
      let signature = try privateKey.sign(message: nonce).base64EncodedString()
      let verification = AttestationVerifcation(attestationBlob: AttestationBlob(nonce: nonce),
                                                signature: signature)
      
      try executeRequest(.setAttestation(nonce, verification)) { (result: Result<Data, Error>) in
        if case .failure(let error) = result {
          return completion(error)
        }
        
        completion(nil)
      }
    } catch {
      completion(error)
    }
  }
  
  // Generates a device-check token
  public func generateToken(_ completion: @escaping (String, Error?) -> Void) {
        DCDevice.current.generateToken { data, error in
          if let error = error {
            return completion("", error)
          }
          
          guard let deviceCheckToken = data?.base64EncodedString() else {
            return completion("", error)
          }
          
          completion(deviceCheckToken, nil)
    }
  }
  
  // Generates an enrollment structure to be used with `registerDevice`
  public func generateEnrollment(paymentId: String, token: String, _ completion: (DeviceCheckRegistration?, Error?) -> Void) {
    do {
      guard let privateKey = try Cryptography.generateKey(id: DeviceCheckClient.privateKeyId) else {
        throw CryptographyError(code: -1, description: "Unable to generate private key")
      }
      
      guard let publicKey = try privateKey.getPublicKeyExternalRepresentationAsPEM() else {
        throw CryptographyError(code: -1, description: "Unable to retrieve public key")
      }
      
      let signature = try privateKey.sign(message: publicKey + token).base64EncodedString()
      
      let enrollmentBlob = DeviceCheckEnrollment(paymentID: paymentId,
                                                       publicKey: publicKey,
                                                       deviceToken: token)
      let registration = DeviceCheckRegistration(enrollmentBlob: enrollmentBlob,
                                                       signature: signature)
      completion(registration, nil)
    } catch {
      completion(nil, error)
    }
  }
}

private extension DeviceCheckClient {
  // The base URL of the server
  private static let baseURL = URL(string: "http://reputation-alb-1044480833.us-west-2.elb.amazonaws.com")
  
  private enum HttpMethod: String {
    case get
    case put
    case post
  }
  
  private enum Request {
    case register(DeviceCheckRegistration)
    case getAttestation([String: String])
    case setAttestation(String, AttestationVerifcation)
    
    func method() -> HttpMethod {
      switch self {
      case .register: return .post
      case .getAttestation: return .get
      case .setAttestation: return .put
      }
    }
    
    func url() -> URL? {
      switch self {
      case .register:
        return URL(string: "/v1/devicecheck/enrollments", relativeTo: DeviceCheckClient.baseURL)
        
      case .getAttestation:
        return URL(string: "/v1/devicecheck/attestations", relativeTo: DeviceCheckClient.baseURL)
        
      case .setAttestation(let nonce, _):
        let nonce = nonce.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        return URL(string: "/v1/devicecheck/attestations/\(nonce)", relativeTo: DeviceCheckClient.baseURL)
      }
    }
  }
  
  @discardableResult
  private func executeRequest<T: Codable>(_ request: Request, _ completion: @escaping (Result<T, Error>) -> Void) throws -> URLSessionDataTask {
    
    let request = try encodeRequest(request)
    let task = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main).dataTask(with: request) { data, response, error in
      
      if let error = error {
        return completion(.failure(error))
      }
      
      if let data = data, let error = try? JSONDecoder().decode(DeviceCheckError.self, from: data) {
        return completion(.failure(error))
      }
      
      if let response = response as? HTTPURLResponse {
        if response.statusCode < 200 || response.statusCode > 299 {
          return completion(.failure(
            DeviceCheckError(message: "Validation Failed: Invalid Response Code", code: response.statusCode)
            )
          )
        }
      }
      
      guard let data = data else {
        return completion(.failure(
          DeviceCheckError(message: "Validation Failed: Empty Server Response", code: 500)
          )
        )
      }
      
      if T.self == Data.self {
        return completion(.success(data as! T)) //swiftlint:disable:this force_cast
      }
      
      if T.self == String.self {
        return completion(.success(String(data: data, encoding: .utf8) as! T)) //swiftlint:disable:this force_cast
      }
      
      do {
        completion(.success(try JSONDecoder().decode(T.self, from: data)))
      } catch {
        completion(.failure(error))
      }
    }
    task.resume()
    return task
  }
  
  private func encodeRequest(_ endpoint: Request) throws -> URLRequest {
    var request = URLRequest(url: endpoint.url()!)
    request.httpMethod = endpoint.method().rawValue
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    switch endpoint {
    case .register(let parameters):
      request.httpBody = try JSONEncoder().encode(parameters)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      
    case .getAttestation(let parameters):
      request.url = encodeQueryURL(url: request.url!, parameters: parameters)
      
    case .setAttestation(_, let parameters):
      request.httpBody = try JSONEncoder().encode(parameters)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return request
  }
}

private extension DeviceCheckClient {
  //We have to manually encode the query parameters because the server is NON-RFC compliant!
  //RFC 3986: https://www.ietf.org/rfc/rfc3986.txt
  //RFC 3986, section 3.4, page 22, Advises against escaping the `/` & `+` characters.
  //RFC 7230: https://tools.ietf.org/html/rfc7230#section-2.7.1 specifies which characters are not
  //  reserved.
  //RFC 3986                   URI Generic Syntax               January 2005
  //
  //
  //   query       = *( pchar / "/" / "?" )
  //
  // The characters slash ("/") and question mark ("?") may represent data
  // within the query component.
  //
  // The server does not accept slashes or spec compliant characters in the query component of the URL
  // and any character that is NOT one of `-._~`, must be escaped.
  func encodeQueryURL(url: URL, parameters: [String: String]) -> URL? {
    let query = parameters.map({
      "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"))!)"
    }).joined(separator: "&")
    
    var urlComponents = URLComponents()
    urlComponents.scheme = url.scheme
    urlComponents.host = url.host
    urlComponents.path = url.path
    urlComponents.percentEncodedQuery = query
    //urlComponents.queryItems = parameters.map({
    //  URLQueryItem(name: $0.key, value: $0.value)
    //})
    return urlComponents.url
  }
}

//Sample Flow:
//generate Token -> generateEnrollment -> registerDevice
//getAttestation -> setAttestation (verify it)
//store token
