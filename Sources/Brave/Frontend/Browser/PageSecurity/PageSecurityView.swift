// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI
import BraveCore

private struct TopView<L, C, R>: View where L: View, C: View, R: View {
  private let left: () -> L
  private let center: () -> C
  private let right: () -> R
  
  init(@ViewBuilder left: @escaping () -> L,
       @ViewBuilder center: @escaping () -> C,
       @ViewBuilder right: @escaping () -> R) {
      self.left = left
      self.center = center
      self.right = right
  }

  var body: some View {
    ZStack {
      HStack {
        left()
        Spacer()
      }
      
      center()
      
      HStack {
          Spacer()
          right()
      }
    }
  }
}

struct PageSecurityTitleView: View {
  let title: String
  let hasSecureContentOnly: Bool
  let hasCertificate: Bool
  let hasError: Bool

  var body: some View {
    VStack {
      Text(title)
        .font(.callout.weight(.bold))
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      
      HStack(alignment: .firstTextBaseline, spacing: 4.0) {
        // Certificate is invalid
        if !hasCertificate || hasError {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(Color(.braveErrorLabel))
            .font(.callout)
          Text("This site is not secure")
            .font(.callout)
            .foregroundColor(Color(.braveErrorLabel))
            .lineLimit(nil)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          // Page has mixed-content
          if !hasSecureContentOnly {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(Color(.braveErrorLabel))
              .font(.callout)
            Text("This site is not fully secure")
              .font(.callout)
              .foregroundColor(Color(.braveErrorLabel))
              .lineLimit(nil)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          } else {
            // Everything seems okay
            Image(systemName: "checkmark.seal")
              .foregroundColor(Color(.braveSuccessLabel))
              .font(.callout)
            Text("Connection secure")
              .font(.callout)
              .foregroundColor(Color(.secondaryBraveLabel))
              .lineLimit(nil)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
  }
}

struct PageSecurityCertificateListView: View {
  let models: [BraveCertificateModel]
  let hasSecureContentOnly: Bool
  let evaluationError: String?
  
  @Environment(\.presentationMode)
  var presentationMode: Binding<PresentationMode>
  
  var body: some View {
    VStack(spacing: 0.0) {
      TopView {
        Button {
          presentationMode.wrappedValue.dismiss()
        } label: {
          Image(braveSystemName: "leo.arrow.small-left")
            .resizable()
            .frame(width: 11.0, height: 22.0, alignment: .leading)
            .padding()
        }
      } center: {
        CertificateTitleView(isRootCertificate: true, commonName: "Certificates", evaluationError: evaluationError)
//        PageSecurityTitleView(title: "Certificates",
//                              hasSecureContentOnly: hasSecureContentOnly,
//                              hasCertificate: !models.isEmpty,
//                              hasError: evaluationError != nil)
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
      } right: {
        EmptyView()
      }
      .background(Color(.secondaryBraveGroupedBackground))
        
      Divider()
        .shadow(color: Color.black.opacity(0.1),
                radius: 5.0)
      
      List {
        ForEach(Array(models.enumerated()), id: \.element) { index, model in
          NavigationLink(destination:
            CertificateView(model: model,
                            evaluationError: evaluationError)
              .navigationBarBackButtonHidden(true)
              .navigationBarHidden(true)) {
            Text(model.subjectName.commonName)
              .font(.callout.weight(index == 0 ? .bold : .regular))
              .lineLimit(nil)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.leading, CGFloat(index) * 10.0)
        }
      }
      .listStyle(.insetGrouped)
    }
    .navigationBarBackButtonHidden(true)
    .navigationBarHidden(true)
  }
  
  private struct CertificateView: View {
    let model: BraveCertificateModel
    let evaluationError: String?
    
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    
    var body: some View {
      VStack(spacing: 0.0) {
        TopView {
          Button {
            presentationMode.wrappedValue.dismiss()
          } label: {
            Image(braveSystemName: "leo.arrow.small-left")
              .resizable()
              .frame(width: 11.0, height: 22.0, alignment: .leading)
              .padding()
          }
        } center: {
          CertificateTitleView(
            isRootCertificate: model.isRootCertificate,
            commonName: model.subjectName.commonName,
            evaluationError: evaluationError
          )
          .padding()
          .frame(maxWidth: .infinity, alignment: .center)
        } right: {
          EmptyView()
        }
        .background(Color(.secondaryBraveGroupedBackground))
        
        Divider()
          .shadow(color: Color.black.opacity(0.1),
                  radius: 5.0)
        
        CertificateListView(
          model: model,
          evaluationError: evaluationError
        )
      }
    }
  }
}

struct PageSecurityView: View {
  let commonName: String
  let hasSecureContentOnly: Bool
  let certificates: [BraveCertificateModel]
  let certificateEvaluationError: String
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0.0) {
        PageSecurityTitleView(title: commonName,
                              hasSecureContentOnly: hasSecureContentOnly,
                              hasCertificate: !certificates.isEmpty,
                              hasError: !certificateEvaluationError.isEmpty)
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(.secondaryBraveGroupedBackground))
        
        Divider()
          .shadow(color: Color.black.opacity(0.1),
                  radius: 5.0)
        
        List {
          Section {
            NavigationLink(destination:
              PageSecurityCertificateListView(
                models: certificates,
                hasSecureContentOnly: hasSecureContentOnly,
                evaluationError: certificateEvaluationError.isEmpty ? nil : certificateEvaluationError)) {
              Text("View Certificate")
                .font(.system(.caption, design: .monospaced))
            }
            .listRowBackground(Color(.secondaryBraveGroupedBackground))
          }
          
          if certificates.isEmpty {
            Section {
              Text("This website contains no SSL certificates.\nYou should not enter any sensitive information on this site (for example, passwords or credit cards), because it could be stolen by attackers.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(.braveErrorLabel))
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
          } else if !certificateEvaluationError.isEmpty {
            Section {
              Text("The SSL certificate on this website is invalid.\nYou should not enter any sensitive information on this site (for example, passwords or credit cards), because it could be stolen by attackers.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(.braveErrorLabel))
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
          } else if !hasSecureContentOnly {
            Section {
              Text("The website context Mixed-Content (http inside https).\nYou should not enter any sensitive information on this site (for example, passwords or credit cards), because it could be stolen by attackers.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(.braveErrorLabel))
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
          }
        }
        .listStyle(InsetGroupedListStyle())
        .listBackgroundColor(Color(.braveGroupedBackground))
      }
    }
  }
}

#Preview {
  PageSecurityView(commonName: "brave.com", hasSecureContentOnly: true, certificates: [], certificateEvaluationError: "")
}

class PageSecurityViewController: UIViewController, PopoverContentComponent {
  
  private let rootView: PageSecurityView
  private let hostView: UIHostingController<PageSecurityView>

  init(commonName: String, hasSecureContentOnly: Bool, certificates: [BraveCertificateModel], evaluationError: String) {
    
    rootView = PageSecurityView(commonName: commonName, hasSecureContentOnly: hasSecureContentOnly, certificates: certificates.reversed(), certificateEvaluationError: evaluationError)
    
    hostView = UIHostingController(rootView: rootView)
    
    super.init(nibName: nil, bundle: nil)
    
    addChild(hostView)
    view.addSubview(hostView.view)
    hostView.didMove(toParent: self)

    hostView.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override var preferredContentSize: CGSize {
    get {
      return hostView.view.bounds.size
    }

    set {
      hostView.preferredContentSize = newValue
      super.preferredContentSize = newValue
    }
  }
}
