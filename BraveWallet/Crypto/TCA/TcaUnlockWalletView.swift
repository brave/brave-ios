// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BraveUI
import ComposableArchitecture
import LocalAuthentication
import SwiftUI
import struct Shared.Strings

struct UnlockState: Equatable {
  @BindableState var password: String = ""
  var isUnlockButtonDisabled: Bool = true
  var isPasswordSaved: Bool = false
  var attemptedBiometricUnlock: Bool = false
  var unlockError: UnlockError?
  @BindableState var isRestoreVisible: Bool = false
  var restore: RestoreState?
}

enum UnlockAction: BindableAction {
  case onAppear
  case binding(BindingAction<UnlockState>)
  case unlockTapped
  case unlockFailed
  case fillPasswordFromKeychain
  case restoreTapped
  case restoreDismissed
}

struct WalletKeychain {
  var savePassword: (String) -> Result<Void, NSError>
  var loadPassword: () -> Result<String, NSError>
  var isPasswordSaved: () -> Bool
}

struct UnlockEnvironment {
  let keyringController: BraveWalletKeyringController
  let walletKeychain: WalletKeychain
}

let unlockReducer: Reducer<UnlockState, UnlockAction, UnlockEnvironment> =
  .init { state, action, environment in
    switch action {
    case .onAppear:
      let isPasswordSaved = environment.walletKeychain.isPasswordSaved()
      state.isPasswordSaved = isPasswordSaved
      // Attempt to unlock with biometrics
      if !state.attemptedBiometricUnlock, isPasswordSaved {
        return .init(value: .fillPasswordFromKeychain)
      }
      return .none
    
    case .binding(\.$password):
      state.isUnlockButtonDisabled = state.password.isEmpty
      state.unlockError = nil
      return .none
      
    case .binding:
      return .none
      
    case .unlockTapped:
      return Effect
        .future { [password = state.password] callback in
          environment.keyringController
            .unlock(password) { success in
              // We only care about failures inside the unlock view
              if success {
                return
              }
              callback(.success(UnlockAction.unlockFailed))
            }
        }
      
    case .unlockFailed:
      state.unlockError = .incorrectPassword
      return .none
      
    case .fillPasswordFromKeychain:
      if case .success(let password) = environment.walletKeychain.loadPassword() {
        state.password = password
        return .init(value: .unlockTapped)
      }
      return .none
      
    case .restoreTapped:
      state.isRestoreVisible = true
      state.restore = .init()
      return .none
      
    case .restoreDismissed:
      state.isRestoreVisible = false
      state.restore = nil
      return .none
    }
}
.binding()

public struct TcaUnlockWalletView: View {
  var store: Store<UnlockState, UnlockAction>
  @ObservedObject var viewStore: ViewStore<UnlockState, UnlockAction>
  
  init(store: Store<UnlockState, UnlockAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  private var biometricsIcon: Image? {
    let context = LAContext()
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
      switch context.biometryType {
      case .faceID:
        return Image(systemName: "faceid")
      case .touchID:
        return Image(systemName: "touchid")
      case .none:
        return nil
      @unknown default:
        return nil
      }
    }
    return nil
  }
  
  private func unlock() {
    viewStore.send(.unlockTapped)
  }
  
  public var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 46) {
        Image("graphic-lock")
          .padding(.bottom)
          .accessibilityHidden(true)
        VStack {
          Text(Strings.Wallet.unlockWalletTitle)
            .font(.headline)
            .padding(.bottom)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
          HStack {
            SecureField(Strings.Wallet.passwordPlaceholder, text: viewStore.binding(\.$password), onCommit: unlock)
              .textContentType(.password)
              .font(.subheadline)
              .introspectTextField(customize: { tf in
                tf.becomeFirstResponder()
              })
              .textFieldStyle(BraveValidatedTextFieldStyle(error: viewStore.unlockError))
            if viewStore.state.isPasswordSaved, let icon = biometricsIcon {
              Button(action: {
                viewStore.send(.fillPasswordFromKeychain)
              }) {
                icon
                  .imageScale(.large)
                  .font(.headline)
              }
            }
          }
          .padding(.horizontal, 48)
        }
        VStack(spacing: 30) {
          Button(action: unlock) {
            Text(Strings.Wallet.unlockWalletButtonTitle)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .normal))
          .disabled(viewStore.isUnlockButtonDisabled)
          NavigationLink(
            isActive: viewStore.binding(
              get: { $0.restore != nil },
              send: { $0 ? .restoreTapped : .restoreDismissed }),
            destination: {
              Text("Test")
            }, label: {
              Text(Strings.Wallet.restoreWalletButtonTitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(.braveLabel))
            }
          )
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
      .padding()
      .padding(.vertical)
    }
    .navigationTitle(Strings.Wallet.cryptoTitle)
    .navigationBarTitleDisplayMode(.inline)
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .onAppear {
      viewStore.send(.onAppear)
    }
  }
}

#if DEBUG
struct TcaCryptoUnlockView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TcaUnlockWalletView(
        store: .init(
          initialState: .init(),
          reducer: unlockReducer,
          environment: .init(
            keyringController: TestKeyringController(),
            walletKeychain: .init(
              savePassword: { _ in return .success(()) },
              loadPassword: { .success("password") },
              isPasswordSaved: { false }
            )
          )
        )
      )
    }
  }
}
#endif
