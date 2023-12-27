
import SwiftUI
import DesignSystem

struct AIChatUserMessageView: View {
  let prompt: String
  
  var body: some View {
    VStack {
      HStack {
        ZStack {
          Color.white
          Image(braveSystemName: "leo.user.circle")
            .padding(8.0)
        }
        .fixedSize()
        .clipShape(Capsule())
        
        Spacer()
      }
      
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
  AIChatUserMessageView(prompt: "Does it work with Apple devices?")
    .previewLayout(.sizeThatFits)
}
