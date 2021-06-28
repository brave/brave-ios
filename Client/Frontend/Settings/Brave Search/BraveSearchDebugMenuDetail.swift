// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared
import BraveUI

private let log = Logger.browserLogger

struct BraveSearchDebugMenuDetail: View {
  let logEntry: BraveSearchLogEntry.FallbackLogEntry
  
  @State private var showingSheet = false
  
  var body: some View {
    List {
      HStack {
        Text("URL")
        Spacer()
        Text(logEntry.url.absoluteString)
      }
      
      Section(header: Text("/can/answer")) {
        HStack {
          Text("Cookies")
          Spacer()
          Text(
            logEntry.cookies.map {
              "\($0.name): \($0.value)"
            }
            .joined(separator: ", ")
          )
        }
        
        HStack {
          Text("Time taken(s)")
          Spacer()
          Text(logEntry.canAnswerTime ?? "-")
        }
        
        HStack {
          Text("Response")
          Spacer()
          Text(logEntry.backupQuery ?? "-")
        }
      }
      
      Section(header: Text("Search Fallback")) {
        HStack {
          Text("Time taken(s)")
          Spacer()
          Text(logEntry.fallbackTime ?? "-")
            .font(.body)
        }
        
        Button("Export response") {
          showingSheet.toggle()
        }
        .disabled(logEntry.fallbackData == nil)
        .background(
          ActivityView(isPresented: $showingSheet, activityItems: [dataAsUrl].compactMap { $0 })
        )
      }
    }
  }
  
  private var dataAsUrl: URL? {
    guard let data = logEntry.fallbackData else { return nil }
    let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("output.html")
    
    do {
      try data.write(to: tempUrl)
      return tempUrl
    } catch {
      log.error("data write-to error")
      return nil
    }
  }
}

struct BraveSearchDebugMenuDetail_Previews: PreviewProvider {
  static var previews: some View {
    BraveSearchDebugMenuDetail(
      logEntry: BraveSearchDebugMenuFixture.sample)
  }
}
