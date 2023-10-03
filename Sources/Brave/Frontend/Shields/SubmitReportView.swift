// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import BraveUI
import DesignSystem
import BraveShields
import BraveVPN
import Data

struct SubmitReportView: View {
  @Environment(\.dismiss) private var dismiss: DismissAction
  let url: URL
  let isPrivateBrowsing: Bool
  
  @State private var additionalDetails = ""
  @State private var contactDetails = ""
  @State private var isSubmittingReport = false
  @State private var isSubmitted = false
  
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
          .textContentType(.emailAddress)
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
        .disabled(isSubmittingReport)
        .hidden(isHidden: isSubmitted)
        .animation(.smooth.speed(0.2), value: isSubmitted)
      }
      
      ToolbarItem(placement: .confirmationAction) {
        if isSubmitted {
          Button(Strings.close, action: {
            dismiss()
          })
        } else {
          Button(Strings.Shields.reportBrokenSubmitButtonTitle, action: {
            withAnimation {
              isSubmittingReport = true
            }
            
            Task { @MainActor in
              await createAndSubmitReport()
              
              withAnimation {
                isSubmitted = true
              }
              
              try await Task.sleep(seconds: 4)
              dismiss()
            }
          }).disabled(isSubmittingReport)
        }
      }
    }
    .overlay {
      if isSubmittingReport {
        ProgressView()
          .progressViewStyle(.braveCircular(size: .normal, tint: .braveBlurpleTint))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.braveBackground).opacity(0.5).ignoresSafeArea())
          .animation(.easeInOut, value: isSubmittingReport)
      }
    }
    .overlay {
      if isSubmitted {
        SubmitReportSuccessView()
          .progressViewStyle(.braveCircular(size: .normal, tint: .braveBlurpleTint))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.braveBackground).ignoresSafeArea())
          .animation(.easeIn, value: isSubmitted)
      }
    }
  }
  
  var body: some View {
    NavigationView {
      scrollContent
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
    }
  }
  
  @MainActor func createAndSubmitReport() async {
    let domain = Domain.getOrCreate(forUrl: url, persistent: !isPrivateBrowsing)
    
    let report = WebcompatReporter.Report(
      cleanedURL: url,
      additionalDetails: additionalDetails,
      contactInfo: contactDetails,
      areShieldsEnabled: !domain.areAllShieldsOff,
      adBlockLevel: domain.blockAdsAndTrackingLevel,
      fingerprintProtectionLevel: domain.finterprintProtectionLevel,
      adBlockListTitles: FilterListStorage.shared.filterLists.compactMap({ return $0.isEnabled ? $0.entry.title : nil }),
      isVPNEnabled: BraveVPN.isConnected
    )
    
    await WebcompatReporter.send(report: report)
  }
}

#if swift(>=5.9)
#Preview {
  SubmitReportView(
    url: URL(string: "https://brave.com/privacy-features")!,
    isPrivateBrowsing: false
  )
}
#endif
