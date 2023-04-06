// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import DesignSystem
import BraveUI

struct FilterListAddURLView: View {
  enum FocusField: Hashable {
    case urlInput
  }
  
  @ObservedObject private var customFilterListStorage = CustomFilterListStorage.shared
  @Environment(\.presentationMode) @Binding private var presentationMode
  @State private var newURLInput: String = ""
  @State private var errorMessage: String?
  @FocusState private var focusField: FocusField?
  
  private var textField: some View {
    TextField(Strings.filterListsEnterFilterListURL, text: $newURLInput)
      .onChange(of: newURLInput) { newValue in
        errorMessage = nil
      }
      .keyboardType(.URL)
      .textContentType(.URL)
      .autocapitalization(.none)
      .autocorrectionDisabled()
      .focused($focusField, equals: .urlInput)
      .onSubmit {
        handleOnSubmit()
      }
  }
  
  var body: some View {
    NavigationView {
      List {
        Section(content: {
          VStack(alignment: .leading) {
            textField
              .submitLabel(SubmitLabel.done)
          }.listRowBackground(Color(.secondaryBraveGroupedBackground))
        }, header: {
          Text(Strings.customFilterListURL)
        }, footer: {
          VStack(alignment: .leading, spacing: 8) {
            if let errorMessage = errorMessage {
              Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Text(Strings.addCustomFilterListDescription)
            Text(LocalizedStringKey(Strings.addCustomFilterListWarning))
          }.padding(.top, 8)
        })
      }
      .listBackgroundColor(Color(UIColor.braveGroupedBackground))
      .listStyle(.insetGrouped)
      .navigationTitle(Strings.customFilterList)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .confirmationAction) {
          Button(Strings.filterListsAdd) {
            handleOnSubmit()
          }.disabled(newURLInput.isEmpty)
        }
        
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(Strings.CancelString) {
            presentationMode.dismiss()
          }
        }
      }
    }.frame(idealWidth: 400, idealHeight: 400)
      .onAppear {
        focusField = .urlInput
      }
  }
  
  private func handleOnSubmit() {
    guard !newURLInput.isEmpty else { return }
    guard let url = URL(string: newURLInput) else {
      self.errorMessage = Strings.filterListAddInvalidURLError
      return
    }
    guard url.scheme == "https" else {
      self.errorMessage = Strings.filterListAddOnlyHTTPSAllowedError
      return
    }
    guard !customFilterListStorage.filterListsURLs.contains(where: { filterListURL in
      return filterListURL.setting.externalURL == url
    }) else {
      // Don't allow duplicates
      self.presentationMode.dismiss()
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
      
      self.presentationMode.dismiss()
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
