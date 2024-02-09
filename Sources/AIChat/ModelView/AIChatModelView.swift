// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import WebKit
import BraveCore
import Shared

public class AIChatViewModel: NSObject, AIChatDelegate, ObservableObject {
  private var api: AIChat!
  private let webView: WKWebView?
  private let pageContentFetcher: (WKWebView) async -> String?
  public var querySubmited: String?
  
  @Published var siteInfo: AiChat.SiteInfo?
  @Published var premiumStatus: AiChat.PremiumStatus = .inactive
  @Published var suggestedQuestions: [String] = []
  @Published var conversationHistory: [AiChat.ConversationTurn] = []
  @Published var models: [AiChat.Model] = []
  @Published var currentModel: AiChat.Model!
  
  @Published var requestInProgress: Bool = false
  @Published var apiError: AiChat.APIError = .none
   
  public var isPageConnected: Bool {
    get {
      return api.shouldSendPageContents && webView?.url?.isWebPage(includeDataURIs: true) == true
    }
    
    set {
      objectWillChange.send()
      
      if api.shouldSendPageContents != newValue && webView?.url?.isWebPage(includeDataURIs: true) == true {
        api.shouldSendPageContents = newValue
      }
    }
  }
  
  public var shouldShowPremiumPrompt: Bool {
    return premiumStatus == .inactive && api.canShowPremiumPrompt
  }
  
  public var hasValidWebPage: Bool {
    if let url = webView?.url {
      return url.isWebPage() && !InternalURL.isValid(url: url)
    }
    return false
  }
  
  public var isAgreementAccepted: Bool {
    get {
      return api.isAgreementAccepted
    }
    
    set {
      objectWillChange.send()
      api.isAgreementAccepted = newValue
      
      if newValue {
        isPageConnected = hasValidWebPage
        api.setConversationActive(true)
        
        if isPageConnected {
          api.generateQuestions()
        }
      }
    }
  }
  
  public init(braveCore: BraveCoreMain,
              webView: WKWebView?,
              querySubmited: String? = nil,
              pageContentFetcher: @escaping (WKWebView) async -> String?) {
    self.webView = webView
    self.querySubmited = querySubmited
    self.pageContentFetcher = pageContentFetcher
    
    super.init()

    api = braveCore.aiChatAPI(with: self)
    currentModel = api.currentModel
    models = api.models
    
    if isAgreementAccepted {
      isPageConnected = hasValidWebPage
      api.setConversationActive(true)
      
      if isPageConnected {
        api.generateQuestions()
      }
    }
    
    Task { @MainActor in
      self.premiumStatus = await getPremiumStatus()
    }
  }
  
  public func getPageTitle() -> String? {
    if isPageConnected {
      if let webView = webView {
        return webView.title
      }
    }
    return "Leo"
  }
  
  public func getLastCommittedURL() -> URL? {
    return webView?.url
  }
  
  public func getPageContent(completion: @escaping (String?, Bool) -> Void) {
    guard let webView = webView else {
      completion(nil, false)
      return
    }
    
    Task { @MainActor in
      completion(await pageContentFetcher(webView), false)
    }
  }
  
  public func isDocumentOnLoadCompletedInPrimaryFrame() -> Bool {
    return webView?.isLoading == false
  }
  
  public func onHistoryUpdate() {
    conversationHistory = api.conversationHistory
  }
  
  public func onAPIRequest(inProgress: Bool) {
    requestInProgress = inProgress
  }
  
  public func onAPIResponseError(_ error: AiChat.APIError) {
    apiError = error
  }
  
  public func onSuggestedQuestionsChanged(_ questions: [String], status: AiChat.SuggestionGenerationStatus) {
    suggestedQuestions = questions
  }
  
  public func onModelChanged(_ modelKey: String) {
    currentModel = models.first(where: { $0.key == modelKey })
  }
  
  public func onPageHasContent(_ siteInfo: AiChat.SiteInfo) {
    
  }
  
  public func onConversationEntryPending() {
    
  }
  
  // MARK: - API
  
  func changeModel(modelKey: String) {
    api.changeModel(modelKey)
  }
  
  func clearConversationHistory() {
    apiError = .none
    api.clearConversationHistory()
  }
  
  func submitSuggestion(_ suggestion: String) {
    apiError = .none
    submitQuery(suggestion)
  }
  
  func submitQuery(_ text: String) {
    apiError = .none
    api.submitHumanConversationEntry(text)
  }
  
  func retryLastRequest() {
    api.retryAPIRequest()
  }
  
  func clearAndResetData() {
    apiError = .none
    api.clearConversationHistory()
    api.setConversationActive(false)
    api.isAgreementAccepted = false
  }
  
  @MainActor
  @discardableResult
  func getPremiumStatus() async -> AiChat.PremiumStatus {
    return await withCheckedContinuation { @MainActor continuation in
      api.getPremiumStatus { status in
        DispatchQueue.main.async {
          self.premiumStatus = status
          
          let subscriptionManager = LeoSubscriptionManager.shared
          switch status {
          case .active:
            subscriptionManager.subscriptionState = .purchased
          default:
            subscriptionManager.subscriptionState = .expired
          }
          
          continuation.resume(returning: status)
        }
      }
    }
  }
  
  @MainActor
  func rateConversation(isLiked: Bool, turnId: UInt) async -> String? {
    return await withCheckedContinuation { @MainActor continuation in
      api.rateMessage(isLiked, turnId: turnId, completion: { identifier in
        DispatchQueue.main.async {
          continuation.resume(returning: identifier)
        }
      })
    }
  }
  
  @MainActor
  func submitFeedback(category: String, feedback: String, ratingId: String) async -> Bool {
    await api.sendFeedback(category, feedback: feedback, ratingId: ratingId)
  }
}
