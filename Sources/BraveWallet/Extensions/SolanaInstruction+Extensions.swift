// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore

extension BraveWallet.SolanaInstruction {
  
  var isSystemProgram: Bool {
    programId == BraveWallet.SolanaSystemProgramId
  }
  
  var isTokenProgram: Bool {
    programId == BraveWallet.SolanaTokenProgramId
  }
  
  var isAssociatedTokenProgram: Bool {
    programId == BraveWallet.SolanaAssociatedTokenProgramId
  }
  
  var isSysvarRentProgram: Bool {
    programId == BraveWallet.SolanaSysvarRentProgramId
  }
  
  var instructionName: String {
    guard let decodedData = self.decodedData else {
      return "Unknown"
    }
    if isSystemProgram,
       let instructionType = BraveWallet.SolanaSystemInstruction(rawValue: Int(decodedData.instructionType)) {
      let name = instructionType.name
      return "System Program - \(name)"
    } else if isTokenProgram, let instructionType = BraveWallet.SolanaTokenInstruction(rawValue: Int(decodedData.instructionType)) {
      let name = instructionType.name
      return "Token Program - \(name)"
    }
    return "Unknown"
  }
}

extension BraveWallet.SolanaSystemInstruction {
  var name: String {
    switch self {
    case .transfer:
      return "Transfer"
    case .transferWithSeed:
      return "TransferWithSeed"
    case .withdrawNonceAccount:
      return "WithdrawNonceAccount"
    case .createAccount:
      return "CreateAccount"
    case .createAccountWithSeed:
      return "CreateAccountWithSeed"
    case .assign:
      return "Assign"
    case .assignWithSeed:
      return "AssignWithSeed"
    case .allocate:
      return "Allocate"
    case .allocateWithSeed:
      return "AllocateWithSeed"
    case .advanceNonceAccount:
      return "AdvanceNonceAccount"
    case .initializeNonceAccount:
      return "InitializeNonceAccount"
    case .authorizeNonceAccount:
      return "AuthorizeNonceAccount"
    case .upgradeNonceAccount:
      return "UpgradeNonceAccount"
    default:
      return "Unknown"
    }
  }
}

extension BraveWallet.SolanaTokenInstruction {
  var name: String {
    switch self {
    case .initializeMint:
      return "InitializeMint"
    case .initializeMint2:
      return "InitializeMint2"
    case .initializeAccount:
      return "InitializeAccount"
    case .initializeAccount2:
      return "InitializeAccount2"
    case .initializeAccount3:
      return "InitializeAccount3"
    case .initializeMultisig:
      return "InitializeMultisig"
    case .initializeMultisig2:
      return "InitializeMultisig2"
    case .approve:
      return "Approve"
    case .transfer:
      return "Transfer"
    case .revoke:
      return "Revoke"
    case .setAuthority:
      return "SetAuthority"
    case .mintTo:
      return "MintTo"
    case .burn:
      return "Burn"
    case .closeAccount:
      return "CloseAccount"
    case .freezeAccount:
      return "FreezeAccount"
    case .thawAccount:
      return "ThawAccount"
    case .approveChecked:
      return "ApproveChecked"
    case .transferChecked:
      return "TransferChecked"
    case .mintToChecked:
      return "MintToChecked"
    case .burnChecked:
      return "BurnChecked"
    case .syncNative:
      return "SyncNative"
    @unknown default:
      return "Unknown"
    }
  }
}

extension BraveWallet.DecodedSolanaInstructionData {
  func paramFor(_ paramKey: ParamKey) -> BraveWallet.SolanaInstructionParam? {
    params.first(where: { $0.name == paramKey.rawValue })
  }
  
  // brave-core/components/brave_wallet/browser/solana_instruction_data_decoder.cc
  // GetSystemInstructionParams() / GetTokenInstructionParams()
  enum ParamKey: String {
    case lamports
    case amount
    case decimals
    case space
    case owner
    case base
    case seed
    case fromSeed = "from_seed"
    case fromOwner = "from_owner"
    /// should be moved to `accountMetas`, not available in params
    case nonceAccount = "nonce_account"
    case authorityType = "authority_type"
    case newAuthority = "new_authority"
    case mintAuthority = "mint_authority"
    case freezeAuthority = "freeze_authority"
    case numOfSigners = "num_of_signers"
  }
}
