// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import BraveUI
import DesignSystem

struct SubmitReportView: View {
  @Environment(\.dismiss) private var dismiss: DismissAction
  let url: URL
  let submit: (URL, String, String) -> Void
  
  @State private var additionalDetails = ""
  @State private var contactDetails = ""
  
  private var scrollContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(Strings.Shields.reportBrokenSiteBody1)
        Text(url.absoluteString)
          .foregroundStyle(Color(braveSystemName: .textInteractive))
        Text(Strings.Shields.reportBrokenSiteBody2)
          .font(.footnote)
        BraveTextEditor(
          text: $additionalDetails,
          prompt: Strings.Shields.reportBrokenAdditionalDetails
        ).frame(height: 80)
        
        VStack(alignment: .leading, spacing: 4) {
          Text(Strings.Shields.reportBrokenContactMe).font(.caption)
          TextField(
            Strings.Shields.reportBrokenContactMe,
            text: $contactDetails, prompt: Text(Strings.Shields.reportBrokenContactMeSuggestions)
          )
          .textFieldStyle(BraveTextFieldStyle())
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
        }
      }
      .padding()
      .foregroundStyle(Color(braveSystemName: .textSecondary))
    }
    .background(Color(.braveBackground))
    .foregroundStyle(Color(braveSystemName: .textSecondary))
    .navigationTitle(Strings.Shields.reportABrokenSite)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(Strings.cancelButtonTitle) {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button(Strings.Shields.reportBrokenSubmitButtonTitle, action: {
          dismiss()
          didTapSubmit()
        })
      }
    }
  }
  
  var body: some View {
    if #available(iOS 17.0, *) {
      NavigationStack {
        #if swift(>=5.9)
        scrollContent
          .toolbarTitleDisplayMode(.inline)
        #else
        scrollContent
        #endif
      }
    } else if #available(iOS 16.0, *) {
      NavigationStack {
        scrollContent
      }
    } else {
      NavigationView {
        scrollContent
      }
    }
  }
  
  func didTapSubmit() {
    submit(url, additionalDetails, contactDetails)
  }
}

#if swift(>=5.9)
#Preview {
  SubmitReportView(
    url: URL(string: "https://brave.com/privacy-features")!) { _, _, _ in
      // Do nothing
    }
}
#endif
