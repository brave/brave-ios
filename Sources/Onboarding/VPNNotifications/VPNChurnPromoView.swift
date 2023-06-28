// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared
import DesignSystem
import BraveUI

public enum VPNChurnPromoType {
  case autoRenewSoonExpire
  case autoRenewDiscount
  case autoRenewFreeMonth
  case updateBillingSoonExpire
  case updateBillingExpired
  
  var promoImage: String {
    switch self {
    case .autoRenewSoonExpire:
      return "auto_renew _soon_image"
    case .autoRenewDiscount:
      return "auto_renew _discount_image"
    case .autoRenewFreeMonth:
      return "auto_renew _free_image"
    case .updateBillingSoonExpire, .updateBillingExpired:
      return "update_billing_expired"
    }
  }
  
  var title: String {
    switch self {
    case .autoRenewSoonExpire:
      return "Oh no! Your Brave VPN subscription is about to expire."
    case .autoRenewDiscount:
      return "Auto-renew your Brave VPN Subscription now and get 20% off for 3 months!"
    case .autoRenewFreeMonth:
      return "Auto-renew your Brave VPN Subscription now and get 1 month free!"
    case .updateBillingSoonExpire:
      return "There's a billing issue with your account, which means your Brave VPN subscription is about to expire."
    case .updateBillingExpired:
      return "Update your payment info to stay protected with Brave VPN."
    }
  }
  
  var buttonTitle: String {
    switch self {
    case .autoRenewSoonExpire, .autoRenewDiscount, .autoRenewFreeMonth:
      return "Enable Auto-Renew"
    case .updateBillingSoonExpire, .updateBillingExpired:
      return "Update Payment"
    }
  }
}

public struct VPNChurnPromoView: View {
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  public var renewAction: (() -> Void)?
  
  public var churnPromoType: VPNChurnPromoType
  
  public init(churnPromoType: VPNChurnPromoType) {
    self.churnPromoType = churnPromoType
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerView
        detailView
        footerView
      }
      .padding(.horizontal, 32)
      .padding(.vertical, 16)
    }
    .background(Color(.braveBackground))
    .frame(maxWidth: BraveUX.baseDimensionValue, maxHeight: 650)
    .overlay {
      Button {
        presentationMode.dismiss()
      } label: {
        Image(braveSystemName: "leo.close")
          .renderingMode(.template)
          .foregroundColor(Color(.bravePrimary))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      .padding([.top, .trailing], 20)
    }
  }

  private var headerView: some View {
    VStack(spacing: 24) {
      Image(churnPromoType.promoImage, bundle: .module)

      Text(churnPromoType.title)
        .font(.title)
        .multilineTextAlignment(.center)
    }
  }
  
  private var detailView: some View {
    Text("Long long long long long long long description of all times")
      .font(.subheadline)
      .multilineTextAlignment(.center)
  }

  private var footerView: some View {
    VStack(spacing: 24) {
      Button(action: {
        renewAction?()
        presentationMode.dismiss()
      }) {
        Text(churnPromoType.buttonTitle)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      
      HStack(spacing: 8) {
        Text(Strings.VPN.poweredBy)
          .font(.footnote)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.center)
        Image(sharedName: "vpn_brand")
          .renderingMode(.template)
          .foregroundColor(Color(.bravePrimary))
      }
    }
  }
}

#if DEBUG
struct VPNChurnPromoView_Previews: PreviewProvider {
  static var previews: some View {
    VPNChurnPromoView(churnPromoType: .autoRenewSoonExpire)
      .previewLayout(.sizeThatFits)
    
    VPNChurnPromoView(churnPromoType: .autoRenewDiscount)
      .previewLayout(.sizeThatFits)
    
    VPNChurnPromoView(churnPromoType: .autoRenewFreeMonth)
      .previewLayout(.sizeThatFits)
    
    VPNChurnPromoView(churnPromoType: .updateBillingSoonExpire)
      .previewLayout(.sizeThatFits)
    
    VPNChurnPromoView(churnPromoType: .updateBillingExpired)
      .previewLayout(.sizeThatFits)
  }
}
#endif
