// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatPremiumUpsellView: View {
  enum UpsellType {
    case premium, rateLimit
    
    var title: String {
      switch self {
      case .premium:
        return "Unleash Leo's Full Powers With Premium:"
      case .rateLimit:
        return "Response Rate Limit Reached"
      }
    }
    
    var subtitle: String? {
      switch self {
      case .rateLimit:
        return "Unlock a higher response rate by subscribing to Premium, or try again later."
      default:
        return nil
      }
    }
    
    var primaryActionTitle: String {
      switch self {
      case .premium, .rateLimit:
        return "Upgrade"
      }
    }
    
    var dismissActionTitle: String {
      switch self {
      case .premium:
        return "Maybe Later"
      case .rateLimit:
        return "Continue with Basic Model"
      }
    }
  }
  
  let upsellType: UpsellType
  var upgradeAction: (() -> Void)?
  var dismissAction: (() -> Void)?

  var body: some View {
    VStack(spacing: 0) {
      PremiumUpsellTitleView(
        upsellType: upsellType,
        isPaywallPresented: false)
        .padding(24)
      PremiumUpsellDetailView(
        isPaywallPresented: false)
        .padding(8)
      PremiumUpsellActionView(
        upsellType: upsellType,
        upgradeAction: {
          upgradeAction?()
        },
        dismissAction: {
          dismissAction?()
        })
    }
    .background(Color(braveSystemName: .primary10))
    .frame(maxWidth: .infinity, alignment: .leading)
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

struct PremiumUpsellActionView: View {
  let upsellType: AIChatPremiumUpsellView.UpsellType
  var upgradeAction: (() -> Void)?
  var dismissAction: (() -> Void)?

  var body: some View {
    Button(action: {
      upgradeAction?()
    }) {
      Text(upsellType.primaryActionTitle)
        .font(.subheadline.weight(.medium))
        .padding([.top, .bottom], 12)
        .padding([.leading, .trailing], 16)
        .frame(maxWidth: .infinity)
    }
    .background(Color(braveSystemName: .buttonBackground))
    .foregroundStyle(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
    .padding(16)
    
    Button(action: {
      dismissAction?()
    }) {
      Text(upsellType.dismissActionTitle)
        .font(.subheadline.weight(.medium))
        .padding([.top, .bottom], 12)
        .padding([.leading, .trailing], 16)
        .frame(maxWidth: .infinity)
    }
    .background(.clear)
    .foregroundStyle(Color(braveSystemName: .textSecondary))
    .padding([.bottom], 12)
    .padding([.leading, .trailing], 16)
  }
}

struct PremiumUpsellTitleView: View {
  
  let upsellType: AIChatPremiumUpsellView.UpsellType
  
  let isPaywallPresented: Bool
  
  var foregroundTextColor: Color {
    isPaywallPresented ? Color.white : Color(braveSystemName: .textPrimary)
  }
  
  var body: some View {
    switch upsellType {
    case .premium:
      Text(upsellType.title)
        .font(.body.weight(.medium))
        .lineLimit(2)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity, alignment: .center)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(foregroundTextColor)
    case .rateLimit:
      VStack(alignment: .leading, spacing: 8) {
        Text(upsellType.title)
          .font(.body.weight(.medium))
          .lineLimit(2)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundStyle(foregroundTextColor)
        if let subtitle = upsellType.subtitle {
          Text(subtitle)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(foregroundTextColor)
        }
      }
    }
  }
}

struct PremiumUpsellDetailView: View {
  
  let isPaywallPresented: Bool
  
  var body: some View {
    VStack(spacing: 0) {
      PremiumUpsellTopicView(
        topicType: .modelType,
        isPaywallPresented: isPaywallPresented)
          .padding()
      
      Divider()
        .overlay(Color(braveSystemName: .dividerSubtle))
        .frame(height: 1.0)
      
      PremiumUpsellTopicView(
        topicType: .creativity,
        isPaywallPresented: isPaywallPresented)
          .padding()
      
      Divider()
        .overlay(Color(braveSystemName: .dividerSubtle))
        .frame(height: 1.0)
      
      PremiumUpsellTopicView(
        topicType: .accuracy,
        isPaywallPresented: isPaywallPresented)
          .padding()
      
      Divider()
        .overlay(Color(braveSystemName: .dividerSubtle))
        .frame(height: 1.0)
      
      PremiumUpsellTopicView(
        topicType: .chatLength,
        isPaywallPresented: isPaywallPresented)
          .padding()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .overlay(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .strokeBorder(isPaywallPresented
                        ? Color(braveSystemName: .primitivePrimary70)
                        : Color(braveSystemName: .dividerSubtle), 
                      lineWidth: 1.0)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

private struct PremiumUpsellTopicView: View {
  
  fileprivate enum UpsellTopicType {
    case modelType, creativity, accuracy, chatLength
    
    var icon: String {
      switch self {
      case .modelType:
        return "leo.widget.generic"
      case .creativity:
        return "leo.idea"
      case .accuracy:
        return "leo.edit.pencil"
      case .chatLength:
        return "leo.message.bubble-comments"
      }
    }
    
    var title: String {
      switch self {
      case .modelType:
        return "Explore different models"
      case .creativity:
        return "Unlock your creativity"
      case .accuracy:
        return "Stay on topic"
      case .chatLength:
        return "Chat for longer"
      }
    }
    
    var subTitle: String {
      switch self {
      case .modelType:
        return "Priority Access to Claude, Llama-2-70b + more coming soon"
      case .creativity:
        return "Access models better suited for creative tasks and content generation."
      case .accuracy:
        return "Get more accurate answers for more nuanced conversations."
      case .chatLength:
        return "Get higher rate limits for longer conversations."
      }
    }
  }
  
  let topicType: UpsellTopicType
  
  let isPaywallPresented: Bool

  var body: some View {
    HStack {
      Image(braveSystemName: topicType.icon)
        .padding(8.0)
        .background(Color(braveSystemName: .primary20))
        .foregroundColor(Color(braveSystemName: .primary60))
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      
      VStack(alignment: .leading, spacing: 5) {
        Text(topicType.title)
          .font(isPaywallPresented
                ? .headline
                : .subheadline.weight(.semibold))
          .lineLimit(2)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundStyle(isPaywallPresented
                           ? Color.white
                           : Color(braveSystemName: .textPrimary))
        
        Text(topicType.subTitle)
          .font(.footnote)
          .lineLimit(2)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundStyle(isPaywallPresented
                           ? Color(braveSystemName: .primary20 )
                           : Color(braveSystemName: .textSecondary))
      }
    }
  }
  
}

#Preview {
  AIChatPremiumUpsellView(upsellType: .premium)
}
