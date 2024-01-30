// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct WrappingHStack<Model, V>: View where Model: Hashable, V: View {
  typealias ViewGenerator = (Model) -> V
    
  let models: [Model]
  let hSpacing: CGFloat
  let vSpacing: CGFloat
  let viewGenerator: ViewGenerator
  let proxy: GeometryProxy

  @State private var viewHeight = CGFloat.infinity
  
  init(geometry: GeometryProxy, models: [Model], viewGenerator: @escaping ViewGenerator) {
    self.models = models
    self.viewGenerator = viewGenerator
    self.hSpacing = 2.0
    self.vSpacing = 2.0
    self.proxy = geometry
  }
  
  init(geometry: GeometryProxy, models: [Model], hSpacing: Float, vSpacing: Float, viewGenerator: @escaping ViewGenerator) {
    self.models = models
    self.viewGenerator = viewGenerator
    self.hSpacing = CGFloat(hSpacing)
    self.vSpacing = CGFloat(vSpacing)
    self.proxy = geometry
  }

  var body: some View {
    VStack {
      self.generateContent(in: proxy)
    }
//    .frame(maxHeight: viewHeight)
  }

  @ViewBuilder
  private func generateContent(in geometry: GeometryProxy) -> some View {
    var width: CGFloat = .zero
    var height: CGFloat = .zero

    ZStack(alignment: .topLeading) {
      ForEach(models, id: \.self) { model in
        viewGenerator(model)
          .padding(.horizontal, hSpacing)
          .padding(.vertical, vSpacing)
          .alignmentGuide(.leading, computeValue: { dimension in
            if abs(width - dimension.width) > geometry.size.width {
              width = 0.0
              height -= dimension.height
            }
            
            let result = width
            width = model == models.last! ? 0.0 : width - dimension.width
            return result
          })
          .alignmentGuide(.top, computeValue: { dimension in
            let result = height
            if model == models.last! {
              height = 0.0
            }
            return result
          })
      }
    }
  }
}

struct AIChatSuggestionsView: View {
  let suggestions: [String]
  let onSuggestionPressed: ((String) -> Void)?
  private let proxy: GeometryProxy
  
  init(geometry: GeometryProxy, suggestions: [String], onSuggestionPressed: ((String) -> Void)? = nil) {
    self.suggestions = suggestions
    self.proxy = geometry
    self.onSuggestionPressed = onSuggestionPressed
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        LinearGradient(gradient:
                        Gradient(colors: [
                          Color(UIColor(rgb: 0xFA7250)),
                          Color(UIColor(rgb: 0xFF1893)),
                          Color(UIColor(rgb: 0xA77AFF))]),
                       startPoint: .init(x: 1.0, y: 1.0),
                       endPoint: .zero)
        
        Image(braveSystemName: "leo.product.brave-leo")
          .foregroundColor(.white)
          .padding(8.0)
      }
      .fixedSize()
      .clipShape(Capsule())
      
      Text("Suggested follow-ups")
        .font(.caption)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
      
      WrappingHStack(geometry: proxy, models: suggestions, hSpacing: 8.0, vSpacing: 8.0) { suggestion in
        Button {
          onSuggestionPressed?(suggestion)
        } label: {
          Text(suggestion)
            .font(.callout)
            .foregroundColor(Color(braveSystemName: .textInteractive))
        }
        .padding(12.0)
        .background(
          RoundedRectangle(cornerRadius: 12.0, style: .continuous)
            .strokeBorder(Color(braveSystemName: .dividerInteractive), lineWidth: 1.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
      }
    }
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  GeometryReader { geometry in
    AIChatSuggestionsView(geometry: geometry, suggestions: ["What Bluetooth version does it use?", "Summarize this page?", "What is Leo?", "What can the Leo assistant do for me?"])
      .previewLayout(.sizeThatFits)
  }
}
