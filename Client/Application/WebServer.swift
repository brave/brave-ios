/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers
import Shared

class WebServer {
    private let log = Logger.browserLogger

    static let webServerSharedInstance = WebServer()

    class var sharedInstance: WebServer {
        return webServerSharedInstance
    }

    let server: GCDWebServer = GCDWebServer()

    var base: String {
        return "http://localhost:\(server.port)"
    }

    /// The private credentials for accessing resources on this Web server.
    let credentials: URLCredential
    
    // For development builds, random host is used in case of working with multiple instances of the app.
    // For safety we keep static port number for public builds.
    let port = AppConstants.buildChannel.isPublic ? 6571 : Int.random(in: 6572..<6600)

    /// A random, transient token used for authenticating requests.
    /// Other apps are able to make requests to our local Web server,
    /// so this prevents them from accessing any resources.
    fileprivate let sessionToken = UUID().uuidString

    init() {
        credentials = URLCredential(user: sessionToken, password: "", persistence: .forSession)
    }

    @discardableResult func start() throws -> Bool {
        if !server.isRunning {
            try server.start(options: [
                GCDWebServerOption_Port: port,
                GCDWebServerOption_BindToLocalhost: true,
                GCDWebServerOption_AutomaticallySuspendInBackground: false, // done by the app in AppDelegate
                GCDWebServerOption_AuthenticationMethod: GCDWebServerAuthenticationMethod_Basic,
                GCDWebServerOption_AuthenticationAccounts: [sessionToken: ""]
            ])
        }
        return server.isRunning
    }

    /// Convenience method to register a dynamic handler. Will be mounted at $base/$module/$resource
    func registerHandlerForMethod(_ method: String, module: String, resource: String, handler: @escaping (_ request: GCDWebServerRequest?) -> GCDWebServerResponse?) {
        // Prevent serving content if the requested host isn't a whitelisted local host.
        let wrappedHandler = {(request: GCDWebServerRequest?) -> GCDWebServerResponse? in
            guard let request = request, request.url.isLocal else {
                return GCDWebServerResponse(statusCode: 403)
            }

            return handler(request)
        }
        server.addHandler(forMethod: method, path: "/\(module)/\(resource)", request: GCDWebServerRequest.self, processBlock: wrappedHandler)
    }

    /// Convenience method to register a resource in the main bundle. Will be mounted at $base/$module/$resource
    func registerMainBundleResource(_ resource: String, module: String) {
        if let path = Bundle.main.path(forResource: resource, ofType: nil) {
            server.addGETHandler(forPath: "/\(module)/\(resource)", filePath: path, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
        }
    }

    /// Convenience method to register all resources in the main bundle of a specific type. Will be mounted at $base/$module/$resource
    func registerMainBundleResourcesOfType(_ type: String, module: String) {
        for path: String in Bundle.paths(forResourcesOfType: type, inDirectory: Bundle.main.bundlePath) {
            if let resource = NSURL(string: path)?.lastPathComponent {
                server.addGETHandler(forPath: "/\(module)/\(resource)", filePath: path as String, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
            } else {
                log.warning("Unable to locate resource at path: '\(path)'")
            }
        }
    }
    
    func updateLocalURL(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if components.host == "localhost" && components.scheme == "http" {
            components.port = Int(WebServer.sharedInstance.server.port)
        }
        return components.url
    }

    /// Return a full url, as a string, for a resource in a module. No check is done to find out if the resource actually exist.
    func URLForResource(_ resource: String, module: String) -> String {
        return "\(base)/\(module)/\(resource)"
    }

    func baseReaderModeURL() -> String {
        return WebServer.sharedInstance.URLForResource("page", module: "reader-mode")
    }
}
