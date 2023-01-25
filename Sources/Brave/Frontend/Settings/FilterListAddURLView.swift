// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import DesignSystem
import BraveUI

struct FilterListAddURLView: View {
  @ObservedObject private var customFilterListStorage = CustomFilterListStorage.shared
  @SwiftUI.Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
  @State private var newURLInput: String = ""
  
  private var textField: some View {
    TextField(Strings.filterListsEnterFilterListURL, text: $newURLInput)
      .keyboardType(.URL)
      .textContentType(.URL)
      .autocapitalization(.none)
  }
  
  var body: some View {
    NavigationView {
      List {
        Section(content: {
          VStack {
            textField
              .submitLabel(SubmitLabel.done)
          }.listRowBackground(Color(.secondaryBraveGroupedBackground))
        }, header: {
          Text(Strings.customFilterListURL)
            .textCase(.uppercase)
        }, footer: {
          VStack(alignment: .leading, spacing: 8) {
            Text(Strings.addCustomFilterListDescription)
            Text(Strings.addCustomFilterListWarning).bold() + Text(Strings.addCustomFilterListWarning2)
          }.padding(.top, 16)
        })
      }
        .listBackgroundColor(Color(UIColor.braveGroupedBackground))
        .navigationTitle(Strings.customFilterList)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            Button(Strings.filterListsAdd) {
              handleOnSubmit()
            }.disabled(newURLInput.isEmpty)
          }
          
          ToolbarItemGroup(placement: .cancellationAction) {
            Button(Strings.CancelString) {
              presentationMode.wrappedValue.dismiss()
            }
          }
        }
    }
  }
  
  private func handleOnSubmit() {
    guard !newURLInput.isEmpty else { return }
    guard let url = URL(string: newURLInput) else {
      // Show invalid URL error
      return
    }
    guard url.scheme == "https" else {
      // Show invalid scheme error
      return
    }
    guard !customFilterListStorage.filterListsURLs.contains(where: { filterListURL in
      return filterListURL.setting.externalURL == url
    }) else {
      // Don't allow duplicates
      self.presentationMode.wrappedValue.dismiss()
      return
    }
    
    Task {
      let customURL = FilterListCustomURL(
        externalURL: url, isEnabled: true,
        inMemory: !customFilterListStorage.persistChanges
      )
      
      customFilterListStorage.filterListsURLs.append(customURL)
      
      await FilterListCustomURLDownloader.shared.startFetching(
        filterListCustomURL: customURL
      )
      
      self.presentationMode.wrappedValue.dismiss()
    }
  }
}

#if DEBUG
struct FilterListAddURLView_Previews: PreviewProvider {
  static var previews: some View {
    FilterListAddURLView()
  }
}
#endif
