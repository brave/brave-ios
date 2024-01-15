
import SwiftUI
import DesignSystem

struct AIChatPageContextView: View {
  @Binding var isToggleOn: Bool
  
  @State var isToggleEnabled: Bool
  
  var body: some View {
    Toggle(isOn: $isToggleOn) {
      Text("Use page context for response \(Image(braveSystemName: "leo.info.outline"))")
        .font(.footnote)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
    }
    .disabled(!isToggleEnabled)
    .tint(Color(braveSystemName: .primary60))
    .padding(8.0)
    .background(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .foregroundStyle(Color(braveSystemName: .pageBackground))
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatPageContextView(isToggleOn: .constant(true), isToggleEnabled: true)
    .previewLayout(.sizeThatFits)
}
