// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem
import BraveCore
import Shared

class AIChatViewModel: NSObject, AIChatDelegate, ObservableObject {
  private var api: AIChat!
  private let webView: WKWebView?
  
  @Published var siteInfo: AiChat.SiteInfo?
  @Published var premiumStatus: AiChat.PremiumStatus = .inactive
  @Published var suggestedQuestions: [String] = []
  @Published var conversationHistory: [AiChat.ConversationTurn] = []
  @Published var models: [AiChat.Model] = []
  @Published var currentModel: AiChat.Model!
  
  @Published var requestInProgress: Bool = false
  @Published var apiError: AiChat.APIError = .none
  
  var isPageConnected: Bool {
    get {
      return api.shouldSendPageContents == true
    }
    
    set {
      if api.shouldSendPageContents != newValue {
        api.shouldSendPageContents = newValue
      }
    }
  }
  
  var shouldShowPremiumPrompt: Bool {
    return premiumStatus == .inactive && api.canShowPremiumPrompt
  }
  
  var hasValidWebPage: Bool {
    if let url = webView?.url {
      return url.isWebPage() && !InternalURL.isValid(url: url)
    }
    return false
  }
  
  init(braveCore: BraveCoreMain, webView: WKWebView?) {
    self.webView = webView
    
    super.init()

    api = braveCore.aiChatAPI(with: self)
    isPageConnected = hasValidWebPage
    currentModel = api.currentModel
    models = api.models
    
    api.setConversationActive(true)
    api.isAgreementAccepted = true
    
    Task { @MainActor in
      api.generateQuestions()
      self.premiumStatus = await getPremiumStatus()
    }
  }
  
  func getPageTitle() -> String? {
    if isPageConnected {
      if let webView = webView {
        return webView.title
      }
    }
    return "Leo"
  }
  
  func getLastCommittedURL() -> URL? {
    return webView?.url
  }
  
  func getPageContent(completion: @escaping (String?, Bool) -> Void) {
    guard let webView = webView else {
      completion(nil, false)
      return
    }
    
    BraveLeoScriptHandler.getMainArticle(webView: webView) { articleText in
      guard let articleText = articleText else {
        completion(nil, false)
        return
      }
      
      completion(articleText, false)
    }
  }
  
  func isDocumentOnLoadCompletedInPrimaryFrame() -> Bool {
    return webView?.isLoading == false
  }
  
  func onHistoryUpdate() {
    conversationHistory = api.conversationHistory
  }
  
  func onAPIRequest(inProgress: Bool) {
    requestInProgress = inProgress
  }
  
  func onAPIResponseError(_ error: AiChat.APIError) {
    apiError = error
  }
  
  func onSuggestedQuestionsChanged(_ questions: [String], status: AiChat.SuggestionGenerationStatus) {
    suggestedQuestions = questions
  }
  
  func onModelChanged(_ modelKey: String) {
    currentModel = models.first(where: { $0.key == modelKey })
  }
  
  func onPageHasContent(_ siteInfo: AiChat.SiteInfo) {
    
  }
  
  func onConversationEntryPending() {
    
  }
  
  // MARK: - API
  
  func changeModel(modelKey: String) {
    Task { @MainActor in
      api.changeModel(modelKey)
    }
  }
  
  func clearConversationHistory() {
    api.clearConversationHistory()
  }
  
  func submitSuggestion(_ suggestion: String) {
    submitQuery(suggestion)
  }
  
  func submitQuery(_ text: String) {
    api.submitHumanConversationEntry(text)
  }
  
  @MainActor
  func getPremiumStatus() async -> AiChat.PremiumStatus {
    return await withCheckedContinuation { continuation in
      api.getPremiumStatus { status in
        DispatchQueue.main.async {
          self.premiumStatus = status
          continuation.resume(returning: status)
        }
      }
    }
  }
  
  @MainActor
  func rateConversation(isLiked: Bool, turnId: UInt) async -> String? {
    return await withCheckedContinuation { continuation in
      api.rateMessage(isLiked, turnId: turnId, completion: { identifier in
        DispatchQueue.main.async {
          continuation.resume(returning: identifier)
        }
      })
    }
  }
}

struct AIChatView: View {
  @StateObject 
  var model: AIChatViewModel
  
  @Environment(\.presentationMode)
  private var presentationMode
  
  @Namespace
  private var lastMessageId
  
  @State 
  private var customFeedbackIndex: Int?
  
  @State
  private var isPremiumPaywallPresented = false
  
  @State
  private var isAdvancedSettingsPresented = false
  
  var body: some View {
    VStack(spacing: 0.0) {
      AIChatNavigationView(premiumStatus: model.premiumStatus,
      onClose: {
        presentationMode.wrappedValue.dismiss()
      }, onErase: {
        model.clearConversationHistory()
      }, menuContent: {
        ScrollView {
          AIChatMenuView(
            currentModel: model.currentModel,
            modelOptions: model.models,
            onModelChanged: { modelKey in
              model.changeModel(modelKey: modelKey)
            }, onOptionSelected: { option in
              switch option {
              case .premium:
                isPremiumPaywallPresented.toggle()
              case .advancedSettings:
                isAdvancedSettingsPresented.toggle()
              default:
                break
              }
            }
          )
            .frame(minWidth: 300)
            .osAvailabilityModifiers({ view in
              if #available(iOS 16.4, *) {
                view
                  .presentationCompactAdaptation(.popover)
              } else {
                view
              }
            })
        }
      })
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      GeometryReader { geometry in
        ScrollViewReader { scrollViewReader in
          ScrollView {
            VStack(spacing: 0.0) {
              if model.shouldShowPremiumPrompt {
                AIChatPremiumUpsellView(
                  upsellType: model.apiError == .rateLimitReached ? .rateLimit : .premium,
                  upgradeAction: {
                    // TODO: Upgrade Action
                  },
                  dismissAction: {
                    // TODO: Dismiss Action
                  }
                )
                  .padding(8)
              } else {
                ForEach(Array(model.conversationHistory.enumerated()), id: \.offset) { index, turn in
                  if turn.characterType == .human {
                    AIChatUserMessageView(prompt: turn.text)
                      .padding()
                      .background(Color(braveSystemName: .pageBackground))
                    
                    if index == 0 && model.isPageConnected {
                      AIChatPageInfoBanner(url: model.getLastCommittedURL(), pageTitle: model.getPageTitle() ?? "")
                        .padding([.horizontal, .bottom])
                        .background(Color(braveSystemName: .pageBackground))
                    }
                  } else {
                    AIChatResponseMessageView(prompt: turn.text)
                      .padding()
                      .background(Color(braveSystemName: .containerBackground))
                      .contextMenu {
                        responseContextMenuItems(for: index, turn: turn)
                      }
                    
                    if let customFeedbackIndex = customFeedbackIndex,
                       customFeedbackIndex == index {
                      AIChatFeedbackView()
                        .padding()
                    }
                  }
                }
                
                if model.apiError == .connectionIssue {
                  // TODO: Connection Issue View
                  EmptyView()
                } else if model.apiError == .rateLimitReached {
                  // TODO: If the user is already premium, are they also rate-limited?
                  AIChatPremiumUpsellView(upsellType: .rateLimit,
                    upgradeAction: {
                    // TODO: Upgrade Action
                    },
                    dismissAction: {
                    // TODO: Dismiss Action
                    }
                  )
                    .padding(8)
                } else if model.apiError == .contextLimitReached {
                  // TODO: Conversation Length Limit View
                  EmptyView()
                }
                
                Color.clear.id(lastMessageId)
                
                if !model.requestInProgress && !model.suggestedQuestions.isEmpty {
                  AIChatSuggestionsView(geometry: geometry, suggestions: model.suggestedQuestions) { suggestion in
                    model.submitSuggestion(suggestion)
                  }
                  .padding()
                }
              }
            } 
            .onChange(of: model.conversationHistory) { _ in
              scrollViewReader.scrollTo(lastMessageId, anchor: .bottom)
            }
            .onChange(of: model.conversationHistory.last?.text) { _ in
              scrollViewReader.scrollTo(lastMessageId, anchor: .bottom)
            }
            .onChange(of: customFeedbackIndex) { _ in
              withAnimation {
                scrollViewReader.scrollTo(lastMessageId, anchor: .bottom)
              }
            }
          }
        }
      }
      
      Spacer()
      
      AIChatPageContextView(
        isToggleOn: model.shouldShowPremiumPrompt ? .constant(false) : $model.isPageConnected,
        isToggleEnabled: !model.shouldShowPremiumPrompt && model.hasValidWebPage)
        .padding()
      
      AIChatPromptInputView() { prompt in
        model.submitQuery(prompt)
      }
        .disabled(model.shouldShowPremiumPrompt)
    }
    .background(Color(braveSystemName: .containerBackground))
    .popover(isPresented: $isPremiumPaywallPresented, content: {
      AIChatPaywallView(
        restoreAction: {
          // TODO: Restore Action
        },
        upgradeAction: { tierType in
          // TODO: Upgrade Action
        })
    })
    .popover(isPresented: $isAdvancedSettingsPresented, content: {
      AIChatAdvancedSettingsView(isModallyPresented: true, aiModel: model)
    })
  }
  
  @ViewBuilder
  private func responseContextMenuItems(for turnIndex: Int, turn: AiChat.ConversationTurn) -> some View {
    AIChatResponseMessageViewContextMenuButton(title: "Follow-ups", icon: Image(braveSystemName: "leo.message.bubble-comments"), onSelected: {
      customFeedbackIndex = turnIndex
    })
    
    AIChatResponseMessageViewContextMenuButton(title: "Regenerate", icon: Image(braveSystemName: "leo.refresh"), onSelected: {
      
    })
    
    AIChatResponseMessageViewContextMenuButton(title: "Copy", icon: Image(braveSystemName: "leo.copy"), onSelected: {
      UIPasteboard.general.setValue(turn.text, forPasteboardType: "public.plain-text")
    })
    
    AIChatResponseMessageViewContextMenuButton(title: "Like Answer", icon: Image(braveSystemName: "leo.thumb.up"), onSelected: {
      Task {
        await model.rateConversation(isLiked: true, turnId: UInt(turnIndex))
      }
    })
    
    AIChatResponseMessageViewContextMenuButton(title: "Dislike Answer", icon: Image(braveSystemName: "leo.thumb.down"), onSelected: {
      Task {
        await model.rateConversation(isLiked: false, turnId: UInt(turnIndex))
      }
    })
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  return VStack(spacing: 0.0) {
    AIChatNavigationView(premiumStatus: .active,
    onClose: {
      print("Closed Chat")
    }, onErase: {
      print("Erased Chat History")
    }, menuContent: {
      EmptyView()
    })
    
    Divider()
    
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0.0) {
          AIChatUserMessageView(prompt: "Does it work with Apple devices?")
            .padding()
            .background(Color(braveSystemName: .pageBackground))
          
          AIChatPageInfoBanner(url: nil, pageTitle: "Sonos Era 300 and Era 100...'s Editors’Choice Awards: The Best AIs and Services for 2023")
            .padding([.horizontal, .bottom])
            .background(Color(braveSystemName: .pageBackground))
        
          AIChatResponseMessageView(prompt: "After months of leaks and some recent coordinated teases from the company itself, Sonos is finally officially announcing the Era 300 and Era 100 speakers. Both devices go up for preorder today — the Era 300 costs $449 and the Era 100 is $249 — and they’ll be available to purchase in stores beginning March 28th.\n\nAs its unique design makes clear, the Era 300 represents a completely new type of speaker for the company; it’s designed from the ground up to make the most of spatial audio music and challenge competitors like the HomePod and Echo Studio.")
            .padding()
            .background(Color(braveSystemName: .containerBackground))

          AIChatFeedbackView()
            .padding()
          
          AIChatSuggestionsView(geometry: geometry, suggestions: ["What Bluetooth version does it use?", "Summarize this page?", "What is Leo?", "What can the Leo assistant do for me?"])
            .padding()
        }
      }
      .frame(maxHeight: geometry.size.height)
    }
    
    Spacer()
    
    AIChatPageContextView(isToggleOn: .constant(true), isToggleEnabled: true)
      .padding()
    
    AIChatPromptInputView() { prompt in
      print("Prompt Submitted: \(prompt)")
    }
  }
  .background(Color(braveSystemName: .containerBackground))
    .previewLayout(.sizeThatFits)
}
