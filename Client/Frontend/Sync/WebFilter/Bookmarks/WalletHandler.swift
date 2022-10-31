//
//  File.swift
//  
//
//  Created by Brandon on 2022-10-31.
//

import Foundation
import WebKit
import Shared
import GCDWebServers
import BraveShared
import os.log

public class WalletHandler {

}

extension WalletHandler {
  public static func register(_ webServer: WebServer) {
    let registerHandler = { (page: String) in
      webServer.registerHandlerForMethod(
        "GET", module: "modules", resource: page,
        handler: { (request) -> GCDWebServerResponse? in
          guard let url = request?.url else {
            return GCDWebServerResponse(statusCode: 404)
          }

          return WalletHandler.responseForURL(url, headers: request?.headers ?? [:])
        })
    }

    webServer.registerMainBundleResource("Bookmarks.html", module: "modules")
    registerHandler("Module.js")
  }

  private static func responseForURL(_ url: URL, headers: [String: String]) -> GCDWebServerResponse? {
    let asset = Bundle.module.path(forResource: "CustomModule", ofType: "js")
    return buildResponse(asset: asset, variables: [:])
  }

  private static func buildResponse(asset: String?, variables: [String: String]) -> GCDWebServerResponse? {
    guard let unwrappedAsset = asset else {
      Logger.module.error("Asset is nil")
      return GCDWebServerResponse(statusCode: 404)
    }

    let response = GCDWebServerDataResponse(htmlTemplate: unwrappedAsset, variables: variables)
    response?.setValue("no cache", forAdditionalHeader: "Pragma")
    response?.setValue("no-cache,must-revalidate", forAdditionalHeader: "Cache-Control")
    response?.setValue(Date().description, forAdditionalHeader: "Expires")
    return response
  }
}
