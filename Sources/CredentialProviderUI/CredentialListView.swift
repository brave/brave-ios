// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import AuthenticationServices
import DesignSystem

public class CredentialListModel: ObservableObject {
  @Published var suggestedCredentials: [any Credential] = []
  @Published var allCredentials: [any Credential] = []
  @Published var originHost: String?
  @Published var faviconAttributes: [String: FaviconAttributes] = [:]
  
  public init() {
    UIView.applyAppearanceDefaults()
  }
  
  public enum Action {
    case selectedCredential(any Credential)
    case cancelled
  }
  public var actionHandler: ((Action) -> Void)?
  
  public func populateFromStore(_ store: CredentialStore, identifiers: [ASCredentialServiceIdentifier]) {
    self.allCredentials = store.credentials
    if let origin = identifiers.first?.identifier,
        let originURL = URL(string: origin) {
      self.originHost = URLOrigin(url: originURL).host
      // From credential_list_mediator.mm
      self.suggestedCredentials = allCredentials.filter({ credential in
        if credential.serviceName != nil &&
            origin.localizedStandardContains(credential.serviceName) {
          return true
        }
        if credential.serviceIdentifier != nil &&
            origin.localizedStandardContains(credential.serviceIdentifier) {
          return true
        }
        return false
      })
    }
  }
  
  public func loadFavicon(for credential: any Credential) {
    if faviconAttributes[credential.serviceIdentifier] != nil {
      return
    }
    CredentialProviderAPI.loadAttributes(for: credential) { [weak self] attributes in
      self?.faviconAttributes[credential.serviceIdentifier] = attributes
    }
  }
  
  public func passwordWithIdentifier(_ identifier: String) -> String? {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: identifier,
      kSecReturnData: true
    ] as [CFString: Any]
    
    var passwordData: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &passwordData)
    guard status == errSecSuccess,
          let data = passwordData as? Data,
          let password = String(data: data, encoding: .utf8)
    else {
      return nil
    }
    return password
  }
}

private struct Favicon: View {
  var attributes: FaviconAttributes
  
  var body: some View {
    if let image = attributes.faviconImage {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
    } else if let monogramString = attributes.monogramString {
      Text(monogramString)
        .bold()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(Color(uiColor: attributes.textColor ?? .label))
        .background(Color(uiColor: attributes.backgroundColor ?? .clear))
    }
  }
}

public struct CredentialListView: View {
  @ObservedObject public var model: CredentialListModel
  @State private var filter: String = ""
  @State private var credDetails: (any Credential)?
  
  public init(model: CredentialListModel) {
    self.model = model
  }
  
  private struct CredentialButton: View {
    @ObservedObject public var model: CredentialListModel
    var credential: any Credential
    var tappedInfoAction: () -> Void
    
    var body: some View {
      HStack {
        Button {
          model.actionHandler?(.selectedCredential(credential))
        } label: {
          HStack(spacing: 12) {
            ZStack {
              if let attributes = model.faviconAttributes[credential.serviceIdentifier] {
                Favicon(attributes: attributes)
              }
            }
            .onAppear {
              model.loadFavicon(for: credential)
            }
            .frame(width: 28, height: 28)
            .background(Color.white)
            .overlay {
              RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 0) {
              Text(credential.serviceName)
              if !credential.user.isEmpty {
                Text(credential.user)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
        .tint(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        Button {
          tappedInfoAction()
        } label: {
          Image(braveSystemName: "leo.info.outline")
            .foregroundColor(Color(braveSystemName: .iconInteractive))
        }
        .buttonStyle(.plain)
      }
    }
  }
  
  private var allCredentials: [any Credential] {
    if filter.isEmpty {
      return model.allCredentials
    }
    return model.allCredentials.filter({ $0.serviceName.localizedStandardContains(filter) })
  }
  
  public var body: some View {
    NavigationView {
      List {
        if let origin = model.originHost {
          Section {
            if model.suggestedCredentials.isEmpty {
              Text("No Suggestions")
                .font(.footnote)
                .foregroundStyle(Color(braveSystemName: .textTertiary))
                .listRowBackground(Color(uiColor: .secondaryBraveGroupedBackground))
            } else {
              ForEach(model.suggestedCredentials.sorted(by: { $0.rank < $1.rank }), id: \.recordIdentifier) { cred in
                CredentialButton(model: model, credential: cred) {
                  credDetails = cred
                }
                .listRowBackground(Color(uiColor: .secondaryBraveGroupedBackground))
              }
            }
          } header: {
            Text("Logins for \(origin)")
              .foregroundStyle(Color(braveSystemName: .textTertiary))
          }
        }
        Section {
          ForEach(allCredentials, id: \.recordIdentifier) { cred in
            CredentialButton(model: model, credential: cred) {
              credDetails = cred
            }
            .listRowBackground(Color(uiColor: .secondaryBraveGroupedBackground))
          }
          if allCredentials.isEmpty && !filter.isEmpty {
            Text("No results for \"\(filter)\"")
              .font(.footnote)
              .foregroundStyle(Color(braveSystemName: .textTertiary))
              .listRowBackground(Color(uiColor: .secondaryBraveGroupedBackground))
          }
        } header: {
          Text("Other Logins")
            .foregroundStyle(Color(braveSystemName: .textTertiary))
        }
      }
      .background {
        NavigationLink(isActive: Binding(get: { credDetails != nil }, set: { if !$0 { credDetails = nil } })) {
          if let credDetails {
            CredentialDetailView(model: model, credential: credDetails)
          }
        } label: {
          EmptyView()
        }
      }
      .navigationTitle("Brave Passwords")
      .navigationBarTitleDisplayMode(.inline)
      .animation(.default, value: filter)
      .searchable(text: $filter, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search Logins"))
      .listStyle(.insetGrouped)
      .listBackgroundColor(Color(uiColor: .braveGroupedBackground))
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button("Cancel") {
            model.actionHandler?(.cancelled)
          }
          .tint(Color(braveSystemName: .textInteractive))
        }
      }
    }
  }
}

// Can't import BraveUI here due to SDWebImage requirement
extension View {
  /// Sets the background color of a List when using iOS 16 which is no longer backed by `UITableView`, thus
  /// not respecting `UIAppearance` overrides
  @available(iOS, introduced: 14.0, deprecated: 16.0, message: "Use `scrollContentBackground` and `background` directly")
  public func listBackgroundColor(_ color: Color) -> some View {
    if #available(iOS 16.0, *) {
      return self.scrollContentBackground(.hidden).background(color)
    } else {
      return self
    }
  }
}

#if DEBUG
extension CredentialListModel {
  private class MockCredential: NSObject, Credential {
    var favicon: String!
    var keychainIdentifier: String!
    var rank: Int64 = 0
    var recordIdentifier: String!
    var serviceIdentifier: String!
    var serviceName: String!
    var user: String!
    var note: String!
    
    init(
      favicon: FaviconAttributes?,
      rank: Int64,
      serviceName: String,
      user: String,
      note: String
    ) {
      if let favicon {
        self.favicon = {
          let data = try? NSKeyedArchiver.archivedData(withRootObject: favicon, requiringSecureCoding: false)
          print(data)
          return ""
          //        return String(data: data, encoding: .utf8)
        }()
      } else {
        self.favicon = ""
      }
      self.keychainIdentifier = serviceName
      self.rank = rank
      self.recordIdentifier = UUID().uuidString
      self.serviceIdentifier = UUID().uuidString
      self.serviceName = serviceName
      self.user = user
      self.note = note
      super.init()
    }
  }
  static let mock: CredentialListModel = {
    let model = CredentialListModel()
    model.originHost = "github.com"
    model.allCredentials = [MockCredential](
      arrayLiteral:
          .init(favicon: nil, rank: 1, serviceName: "github.com", user: "user", note: ""),
      .init(favicon: nil, rank: 2, serviceName: "github.com", user: "", note: "")
    )
    return model
  }()
}

#Preview {
  CredentialListView(model: .mock)
}
#endif
