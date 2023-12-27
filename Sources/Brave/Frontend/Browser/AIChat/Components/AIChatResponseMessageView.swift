
import SwiftUI
import DesignSystem

struct AIChatResponseMessageViewContextMenuButton: View {
  let title: String
  let icon: Image
  let onSelected: () -> Void
  
  var body: some View {
    Button(action: onSelected, label: {
      Text(title)
        .font(.body)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
      icon
        .foregroundStyle(Color(braveSystemName: .iconDefault))
    })
    .padding()
  }
}

struct AIChatResponseMessageView: View {
  let prompt: String
  
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
      
      Text(prompt)
        .font(.subheadline)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatResponseMessageViewContextMenuButton(title: "Follow-ups", icon: Image(braveSystemName: "leo.message.bubble-comments"), onSelected: {})
    .previewLayout(.sizeThatFits)
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatResponseMessageView(prompt: "After months of leaks and some recent coordinated teases from the company itself, Sonos is finally officially announcing the Era 300 and Era 100 speakers. Both devices go up for preorder today — the Era 300 costs $449 and the Era 100 is $249 — and they’ll be available to purchase in stores beginning March 28th.\n\nAs its unique design makes clear, the Era 300 represents a completely new type of speaker for the company; it’s designed from the ground up to make the most of spatial audio music and challenge competitors like the HomePod and Echo Studio.")
    .previewLayout(.sizeThatFits)
}
