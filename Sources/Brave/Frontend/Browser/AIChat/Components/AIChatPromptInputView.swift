
import SwiftUI
import DesignSystem

struct AIChatPromptInputView: View {
  let onTextSubmitted: (String) -> Void
  
  @State private var prompt: String = ""

  var body: some View {
    HStack {
      TextField("", text: $prompt, 
                prompt: Text("Enter a prompt here")
                          .font(.subheadline)
                          .foregroundColor(Color(braveSystemName: .textTertiary))
      )
      .font(.subheadline)
      .foregroundColor(Color(braveSystemName: .textPrimary))
      .padding()
      .onSubmit {
        if !prompt.isEmpty {
          onTextSubmitted(prompt)
          prompt = ""
        }
      }
      
      if prompt.isEmpty {
        Button {
          
        } label: {
          Image(braveSystemName: "leo.microphone")
            .foregroundStyle(Color(braveSystemName: .iconDefault))
        }
        .padding()
      } else {
        Button {
          onTextSubmitted(prompt)
          prompt = ""
        } label: {
          Image(braveSystemName: "leo.send")
            .foregroundStyle(Color(braveSystemName: .iconDefault))
        }
        .padding()
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .strokeBorder(Color(braveSystemName: .dividerStrong), lineWidth: 1.0)
        .mask(
          VStack {
            Rectangle()
              .offset(.init(x: 0.0, y: 0.0))
              .padding(.bottom, 14.0)
            Rectangle()
              .padding(.horizontal)
              .padding(.bottom)
          }
        ).allowsHitTesting(false)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatPromptInputView() { prompt in
    print("Prompt Submitted: \(prompt)")
  }
    .previewLayout(.sizeThatFits)
}
