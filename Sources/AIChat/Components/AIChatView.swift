// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import SpeechRecognition
import DesignSystem
import BraveCore
import Shared
import Preferences
import BraveUI

public struct AIChatView: View {
  @ObservedObject
  var model: AIChatViewModel
  
  @ObservedObject 
  var speechRecognizer: SpeechRecognizer
  
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
  
  @State
  private var isVoiceEntryPresented = false
  
  @State
  private var voiceSearchActiveInputView: AIChatSpeechRecognitionActiveView = .none
  
  @State
  private var isNoMicrophonePermissionPresented = false
  
  @State
  private var isShowingFeedbackToast = false
  
  @ObservedObject
  private var hasSeenIntro = Preferences.AIChat.hasSeenIntro
  
  var openURL: ((URL) -> Void)
  
  public init(model: AIChatViewModel, speechRecognizer: SpeechRecognizer, openURL: @escaping (URL) -> Void) {
    self.model = model
    self.speechRecognizer = speechRecognizer
    self.openURL = openURL
  }

  public var body: some View {
    VStack(spacing: 0.0) {
      AIChatNavigationView(
        isMenusAvailable: hasSeenIntro.value && model.isAgreementAccepted,
        premiumStatus: model.premiumStatus,
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
        }
      )
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      GeometryReader { geometry in
        ScrollViewReader { scrollViewReader in
          ScrollView {
            if hasSeenIntro.value {
              if model.isAgreementAccepted {
                VStack(spacing: 0.0) {
                  if model.shouldShowPremiumPrompt {
                    AIChatPremiumUpsellView(
                      upsellType: model.apiError == .rateLimitReached ? .rateLimit : .premium,
                      upgradeAction: {
                        isPremiumPaywallPresented = true
                      },
                      dismissAction: {
                        if let basicModel = model.models.first(where: { $0.access == .basic }) {
                          model.changeModel(modelKey: basicModel.key)
                          
                          if let lastRequest = model.conversationHistory.last {
                            model.submitQuery(lastRequest.text)
                          } else {
                            model.retryLastRequest()
                          }
                        } else {
                          // TODO: LOG Error Switching Model
                        }
                      }
                    )
                    .padding()
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
                        
                        if let feedbackIndex = customFeedbackIndex,
                           feedbackIndex == index {
                          AIChatFeedbackView(
                            model: AIChatSpeechRecognitionModel(
                              speechRecognizer: speechRecognizer,
                              activeInputView: $voiceSearchActiveInputView,
                              isVoiceEntryPresented: $isVoiceEntryPresented,
                              isNoMicrophonePermissionPresented: $isNoMicrophonePermissionPresented
                            ),
                            onSubmit: { feedback in
                              Task { @MainActor in
                                await model.submitFeedback(feedback: feedback)
                              }
                              
                              customFeedbackIndex = nil
                              isShowingFeedbackToast = true
                            },
                            onCancel: {
                              customFeedbackIndex = nil
                              isShowingFeedbackToast = false
                            },
                            openURL: { url in
                              if url.host == "dismiss" {
                                //TODO: Dismiss feedback learn-more prompt
                              } else {
                                openURL(url)
                              }
                            }
                          )
                          .padding()
                        }
                      }
                    }
                    
                    if model.apiError == .connectionIssue {
                      AIChatNetworkErrorView()
                        .padding()
                    } else if model.apiError == .rateLimitReached {
                      // TODO: If the user is already premium, are they also rate-limited?
                      AIChatPremiumUpsellView(
                        upsellType: .rateLimit,
                        upgradeAction: {
                          isPremiumPaywallPresented = true
                        },
                        dismissAction: {
                          if let basicModel = model.models.first(where: { $0.access == .basic }) {
                            model.changeModel(modelKey: basicModel.key)
                            
                            if let lastRequest = model.conversationHistory.last {
                              model.submitQuery(lastRequest.text)
                            } else {
                              model.retryLastRequest()
                            }
                          } else {
                            // TODO: LOG Error Switching Model
                          }
                        }
                      )
                      .padding()
                    } else if model.apiError == .contextLimitReached {
                      AIChatContextLimitErrorView()
                        .padding()
                    }
                    
                    if !model.requestInProgress &&
                        !model.suggestedQuestions.isEmpty &&
                        model.apiError == .none {
                      AIChatSuggestionsView(geometry: geometry, suggestions: model.suggestedQuestions) { suggestion in
                        hasSeenIntro.value = true
                        model.submitSuggestion(suggestion)
                      }
                      .padding()
                    }
                    
                    Color.clear.id(lastMessageId)
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
              } else {
                AIChatTermsAndConditionsView(onTermsAccepted: {
                  model.isAgreementAccepted = true
                }, onOpenURL: openURL)
                .padding()
                .frame(minHeight: geometry.size.height)
              }
            } else {
              AIChatIntroView(onSummarizePage: model.isPageConnected ? {
                hasSeenIntro.value = true
                model.submitQuery("Summarize this page")
              } : nil)
              .padding()
              .frame(minHeight: geometry.size.height)
            }
          }
        }
      }
      
      Spacer()
      
      if model.apiError == .none && model.isAgreementAccepted ||
          (!hasSeenIntro.value && !model.isAgreementAccepted) {
        AIChatPageContextView(
          isToggleOn: model.shouldShowPremiumPrompt ? .constant(false) : $model.isPageConnected,
          isToggleEnabled: !model.shouldShowPremiumPrompt && model.hasValidWebPage)
        .padding()
      }
      
      if model.isAgreementAccepted ||
          (!hasSeenIntro.value && !model.isAgreementAccepted) {
        AIChatPromptInputView(
          model: AIChatSpeechRecognitionModel(
            speechRecognizer: speechRecognizer,
            activeInputView: $voiceSearchActiveInputView,
            isVoiceEntryPresented: $isVoiceEntryPresented,
            isNoMicrophonePermissionPresented: $isNoMicrophonePermissionPresented
          ),
          onTextSubmitted: { prompt in
            hasSeenIntro.value = true
            model.submitQuery(prompt)
          }
        )
        .padding(.horizontal)
        .padding(.bottom, 8.0)
        .disabled(model.shouldShowPremiumPrompt)
      }
    }
    .background(Color(braveSystemName: .containerBackground))
    .toastView($isShowingFeedbackToast)
    .background(Color.clear
      .sheet(isPresented: $isPremiumPaywallPresented) {
        AIChatPaywallView(
          restoreAction: {
            // TODO: Restore Action
          },
          upgradeAction: { tierType in
            // TODO: Upgrade Action
          })
      })
    .background(Color.clear
      .sheet(isPresented: $isAdvancedSettingsPresented) {
        AIChatAdvancedSettingsView(
          aiModel: model,
          isModallyPresented: true,
          openURL: { url in
            openURL(url)
            presentationMode.wrappedValue.dismiss()
        })
      })
    .background {
      SpeechToTextInputContentView(
        isPresented: $isVoiceEntryPresented,
        dismissAction: {
          isVoiceEntryPresented = false
        },
        speechModel: speechRecognizer,
        disclaimer: "Brave does not store or share your voice searches.")
    }
    .background(Color.clear
      .alert(isPresented: $isNoMicrophonePermissionPresented) {
        Alert(
          title: Text("Microphone Access Required"),
          message: Text("Please allow microphone access in iOS system eettings for Brave to use anonymous voice entry."),
          primaryButton: Alert.Button.default(
            Text("Settings"),
            action: {
              let url = URL(string: UIApplication.openSettingsURLString)!
              UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
          ),
          secondaryButton: Alert.Button.cancel(Text(Strings.CancelString))
        )
      }
    )
  }
  
  @ViewBuilder
  private func responseContextMenuItems(for turnIndex: Int, turn: AiChat.ConversationTurn) -> some View {
    AIChatResponseMessageViewContextMenuButton(title: "Follow-ups", icon: Image(braveSystemName: "leo.message.bubble-comments"), onSelected: {
      customFeedbackIndex = turnIndex
    })
    
    AIChatResponseMessageViewContextMenuButton(title: "Regenerate", icon: Image(braveSystemName: "leo.refresh"), onSelected: {
      model.retryLastRequest()
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
    AIChatNavigationView(
      isMenusAvailable: true,
      premiumStatus: .active,
      onClose: {
        print("Closed Chat")
      }, onErase: {
        print("Erased Chat History")
      }, menuContent: {
        EmptyView()
      }
    )
    
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

          AIChatFeedbackView(
            model: AIChatSpeechRecognitionModel(
              speechRecognizer: SpeechRecognizer(),
              activeInputView: .constant(.none),
              isVoiceEntryPresented: .constant(false),
              isNoMicrophonePermissionPresented: .constant(false)
            ),
            onSubmit: {
              print("Submitted Feedback: \($0)")
            }, onCancel: {
              print("Cancelled Feedback")
            }, openURL: {
              print("Open Feedback URL: \($0)")
            }
          )
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
    
    AIChatPromptInputView(
      model: AIChatSpeechRecognitionModel(
        speechRecognizer: SpeechRecognizer(),
        activeInputView: .constant(.none),
        isVoiceEntryPresented: .constant(false),
        isNoMicrophonePermissionPresented: .constant(false)
      ),
      onTextSubmitted: {
        print("Prompt Submitted: \($0)")
      }
    )
  }
  .background(Color(braveSystemName: .containerBackground))
    .previewLayout(.sizeThatFits)
}
