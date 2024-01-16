
import SwiftUI
import DesignSystem

struct MenuScaleTransition: GeometryEffect {
  var scalePercent: Double
  
  var animatableData: Double {
    get { scalePercent }
    set { scalePercent = newValue }
  }
  
  func effectValue(size: CGSize) -> ProjectionTransform {
    let projection = ProjectionTransform(
      CGAffineTransform(scaleX: 1.0, y: scalePercent)
    )
    return ProjectionTransform(CATransform3DIdentity)
      .concatenating(projection)
  }
}

struct DropdownView<ActionView, MenuView>: View where ActionView: View, MenuView: View {
  
  @Binding
  var showMenu: Bool
  
  @ViewBuilder
  let actionView: () -> ActionView
  
  @ViewBuilder
  let menuView: () -> MenuView
  
  var body: some View {
    actionView()
      .opacity(showMenu ? 0.7 : 1.0)
      .zIndex(1)
      .overlay(alignment: .bottom) {
        Group {
          if showMenu {
            menuView()
              .transition(
                .modifier(
                  active: MenuScaleTransition(scalePercent: 0),
                  identity: MenuScaleTransition(scalePercent: 1)
                )
                .combined(with: .opacity)
              )
          }
        }
        .alignmentGuide(.bottom) { $0[.top] }
      }
      .animation(.easeInOut(duration: 0.20), value: showMenu)
    }
}

struct AIChatDropdownButton: View {
  var action: () -> Void
  var title: String
  
  var body: some View {
    Button {
      action()
    } label: {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
      
      Image(braveSystemName: "leo.arrow.small-down")
        .foregroundStyle(Color(braveSystemName: .iconDefault))
        .padding(.leading)
    }
    .padding(12.0)
    .background {
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .stroke(Color(braveSystemName: .iconDefault), lineWidth: 0.5)
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

struct AIChatDropdownMenu<Item>: View where Item: RawRepresentable, Item.RawValue: StringProtocol, Item: Identifiable {
  @Binding
  var selectedIndex: Int
  var items: [Item]
  
  var body: some View {
    VStack(spacing: 0.0) {
      ForEach(Array(items.enumerated()), id: \.offset) { index, option in
        Button {
          selectedIndex = index
        } label: {
          Text(option.rawValue)
            .font(.subheadline)
            .foregroundStyle(Color(braveSystemName: .textPrimary))
            .frame(maxWidth: .infinity, alignment: .leading)
          
          if index == selectedIndex {
            Image(braveSystemName: "leo.check.normal")
              .foregroundStyle(Color(braveSystemName: .iconDefault))
          }
        }
        .padding()
        
        if index != items.count {
          Color(braveSystemName: .dividerSubtle).frame(height: 1)
        }
      }
    }
    .background {
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .stroke(Color(braveSystemName: .iconDefault), lineWidth: 0.5)
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    .shadow(color: .black.opacity(0.25), radius: 10.0, x: 0.0, y: 2.0)
  }
}

struct AIChatDropdownView: View {
  private enum Options: String, CaseIterable, Identifiable {
    case notHelpful = "Answer is not helpful"
    case notWorking = "Something doesn't work"
    case other = "Other"
    
    var id: Self { self }
  }
  
  @State
  private var selectedIndex: Int = 0
  
  @State
  private var showMenu = false

  var body: some View {
    VStack {
      HStack(spacing: 0.0) {
        Text("What's your feedback about?")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
        
        Text("*")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(Color(braveSystemName: .systemfeedbackErrorText))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      
      DropdownView(showMenu: $showMenu) {
        AIChatDropdownButton(action: {
          showMenu.toggle()
        }, title: Options.allCases[selectedIndex].rawValue)
      } menuView: {
        AIChatDropdownMenu(selectedIndex: $selectedIndex, items: Options.allCases)
          .offset(x: 0.0, y: 12.0)
          .onChange(of: selectedIndex) { _ in
            showMenu = false
          }
      }
    }
  }
}

struct AIChatFeedbackInputView: View {
  @State var text: String
  
  var body: some View {
    HStack {
      ZStack(alignment: .leading) {
        TextEditor(text: $text)
          .font(.subheadline)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(minHeight: 80.0)
          .autocorrectionDisabled()
          .autocapitalization(.none)
        
        if text.isEmpty {
          VStack {
            Text("Provide feedback here")
              .font(.subheadline)
              .foregroundColor(Color(braveSystemName: .textTertiary))
              .disabled(true)
              .allowsHitTesting(false)
              .padding(.vertical, 8.0)
              .padding(.horizontal, 5.0)
            Spacer()
          }
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.trailing)
      
      Button {
        
      } label: {
        Image(braveSystemName: "leo.microphone")
          .foregroundStyle(Color(braveSystemName: .iconDefault))
      }
    }
    .padding(12.0)
    .overlay {
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .stroke(Color(braveSystemName: .iconDefault), lineWidth: 0.5)
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

struct AIChatFeedbackLeoPremiumAdView: View {

  var body: some View {
    Text("Brave Leo Premium provides access to an expanded set of language models for even greater answer nuance. [Learn more](https://brave.com/)")
      .tint(Color(braveSystemName: .textInteractive))
      .font(.subheadline)
      .foregroundStyle(Color(braveSystemName: .textSecondary))
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(
        LinearGradient(gradient:
                        Gradient(colors: [
                          Color(UIColor(rgb: 0xF8BEDA)).opacity(0.1),
                          Color(UIColor(rgb: 0xAD99FF)).opacity(0.1)]),
                       startPoint: .init(x: 1.0, y: 1.0),
                       endPoint: .zero)
      )
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .environment(\.openURL, OpenURLAction { url in
          print("Open \(url)")
          return .handled
      })
  }
}

struct AIChatFeedbackView: View {
  
  var body: some View {
    VStack {
      Text("Provide Brave AI Feedback")
        .font(.body)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
      
      AIChatDropdownView()
        .zIndex(999)
        .padding(.horizontal)
      
      Text("Provide Feedback here")
        .font(.caption)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.horizontal, .top])
      
      AIChatFeedbackInputView(text: "")
        .padding([.horizontal, .bottom])
      
      AIChatFeedbackLeoPremiumAdView()
        .padding(.horizontal)
      
      HStack {
        Button {
        
        } label: {
          Text("Cancel")
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(Color(braveSystemName: .textSecondary))
        }
        .padding()
        
        Button {
        
        } label: {
          Text("Submit")
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
      .padding()
    }
    .background(Color(braveSystemName: .blue10))
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatFeedbackView()
    .previewLayout(.sizeThatFits)
}
