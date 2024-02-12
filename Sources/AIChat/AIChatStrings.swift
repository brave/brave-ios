// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
@_exported import Strings

extension Strings {
  public struct AIChat {
    public static let contextLimitErrorTitle = NSLocalizedString(
      "aichat.contextLimitErrorTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "This conversation is too long and cannot continue.\nThere may be other models available with which Leo is capable of maintaining accuracy for longer conversations.",
      comment: "The title shown on limit reached error view, which is suggesting user to change default model"
    )
    public static let newChatActionTitle = NSLocalizedString(
      "aichat.newChatActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "New Chat",
      comment: "The title for button that starts a new chat"
    )
    public static let networkErrorViewTitle = NSLocalizedString(
      "aichat.networkErrorViewTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "There was a network issue connecting to Leo, check your connection and try again.",
      comment: "The title for view that shows network - connection error and suggesting to try again"
    )
    public static let retryActionTitle = NSLocalizedString(
      "aichat.retryActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Retry",
      comment: "The title for button for re-try"
    )
    public static let feedbackSuccessAnswerLikedTitle = NSLocalizedString(
      "aichat.feedbackSuccessAnswerLikedTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Answer Liked",
      comment: "The title for feedback view when response is sucessfull also liked"
    )
    public static let feedbackSuccessAnswerDisLikedTitle = NSLocalizedString(
      "aichat.feedbackSuccessAnswerDisLikedTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Answer DisLiked",
      comment: "The title for feedback view when response is sucessfull but disliked"
    )
    public static let feedbackSubmittedTitle = NSLocalizedString(
      "aichat.feedbackSuccessAnswerDisLiked",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Feedback sent successfully",
      comment: "The title for feedback view when it is submitted"
    )
    public static let addFeedbackActionTitle = NSLocalizedString(
      "aichat.addFeedbackActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Add Feedback",
      comment: "The title for button that submits feedback"
    )
    public static let feedbackOptionTitleNotHelpful = NSLocalizedString(
      "aichat.feedbackOptionTitleNotHelpful",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Answer is not helpful",
      comment: "The title for helpful feedback option"
    )
    public static let feedbackOptionTitleNotWorking = NSLocalizedString(
      "aichat.feedbackOptionTitleNotWorking",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Something doesn't work",
      comment: "The title for not working feedback option"
    )
    public static let feedbackOptionTitleOther = NSLocalizedString(
      "aichat.feedbackOptionTitleOther",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Other",
      comment: "The title for other feedback option"
    )
    public static let feedbackOptionsViewTitle = NSLocalizedString(
      "aichat.feedbackOptionsViewTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "What's your feedback about?",
      comment: "The title for view which listsfeedback option list"
    )
    public static let feedbackInputViewTitle = NSLocalizedString(
      "aichat.feedbackInputViewTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Provide feedback here",
      comment: "The title for view which user type feedback"
    )
    public static let feedbackViewMainTitle = NSLocalizedString(
      "aichat.feedbackViewMainTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Provide Brave AI Feedback",
      comment: "The title for view which user type feedback"
    )
    public static let feedbackSubmitActionTitle = NSLocalizedString(
      "aichat.feedbackSubmitActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Submit",
      comment: "The title for the button that submits feedback"
    )
    public static let summarizePageActionTitle = NSLocalizedString(
      "aichat.summarizePageActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Summarize this page",
      comment: "The title for button that start summarizing page"
    )
    public static let chatIntroTitle = NSLocalizedString(
      "aichat.chatIntroTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Hi, I'm Leo!",
      comment: "The title for intro view"
    )
    public static let chatIntroSubTitle = NSLocalizedString(
      "aichat.chatIntroSubTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "An AI-powered intelligent assistant, built right into Brave.",
      comment: "The subtitle for intro view"
    )
    public static let chatIntroWebsiteHelpTitle = NSLocalizedString(
      "aichat.chatIntroWebsiteHelpTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Need help with a website?",
      comment: "The title for intro view which triggers website help"
    )
    public static let chatIntroWebsiteHelpSubtitlePageSummarize = NSLocalizedString(
      "aichat.chatIntroWebsiteHelpSubtitlePageSummarize",
      tableName: "BraveLeo",
      bundle: .module,
      value: "I can help you summarizing articles, expanding on a site's content and much more. Not sure where to start? Try this:",
      comment: "The subtitle for intro view which triggers website help for summary"
    )
    public static let chatIntroWebsiteHelpSubtitleArticleSummarize = NSLocalizedString(
      "aichat.chatIntroWebsiteHelpSubtitleArticleSummarize",
      tableName: "BraveLeo",
      bundle: .module,
      value: "I can help you summarizing articles, expanding on a site's content and much more.",
      comment: "The subtitle for intro view which triggers website help for article"
    )
    public static let chatIntroJustTalkTitle = NSLocalizedString(
      "aichat.chatIntroJustTalkTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Just want to chat?",
      comment: "The title for intro view which triggers just chat"
    )
    public static let chatIntroJustTalkSubTitle = NSLocalizedString(
      "aichat.chatIntroJustTalkSubTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Ask me anything! We can talk about any topic you want. I'm always learning and improving to provide better answers.",
      comment: "The subtitle for intro view which triggers just chat"
    )
    public static let introMessageTitle = NSLocalizedString(
      "aichat.introMessageTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Chat",
      comment: "The title for intro message"
    )
    public static let introMessageLlamaModelDescription = NSLocalizedString(
      "aichat.introMessageLlamaModelDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Llama 2 13b by Meta",
      comment: "The model and creator for intro message - Llama 2 13b is the model name -- Meta is the creator"
    )
    public static let introMessageMixtralModelDescription = NSLocalizedString(
      "aichat.introMessageMixtralModelDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Mixtral by Mistral AI",
      comment: "The model and creator for intro message - Mixstral is the model name -- Mistral AI is the creator"
    )
    public static let introMessageClaudeInstantModelDescription = NSLocalizedString(
      "aichat.introMessageClaudeInstantModelDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Claude Instant by Anthropic",
      comment: "The model and creator for intro message - Claude Instant is the model -- Anthropic is the creator"
    )
    public static let introMessageLlamaMessageDescription = NSLocalizedString(
      "aichat.introMessageLlamaMessageDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Hi, I'm Leo. I'm a fully hosted AI assistant by Brave. I'm powered by Llama 13B, a model created by Meta to be performant and applicable to many use cases.",
      comment: "The model intro message when you first enter the chat assistant"
    )
    public static let introMessageMixtralMessageDescription = NSLocalizedString(
      "aichat.introMessageMixtralMessageDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Hi, I'm Leo. I'm a fully hosted AI assistant by Brave. I'm powered by Mixtral 8x7B, a model created by Mistral AI to handle advanced tasks.",
      comment: "The model intro message when you first enter the chat assistant"
    )
    public static let introMessageClaudeInstantMessageDescription = NSLocalizedString(
      "aichat.introMessageClaudeInstantMessageDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Hi, I'm Leo. I'm proxied by Brave and powered by Claude Instant, a model created by Anthropic to power conversational and text processing tasks.",
      comment: "The model intro message when you first enter the chat assistant"
    )
    public static let introMessageGenericMessageDescription = NSLocalizedString(
      "aichat.introMessageGenericMessageDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Hi, I'm Leo. I'm an AI assistant by Brave. I'm powered by %@. Ask me anything, and I'll do my best to answer.",
      comment: "The model intro message when you first enter the chat assistant -- %@ is a place-holder for the model name"
    )
    public static let paywallViewTitle = NSLocalizedString(
      "aichat.paywallViewTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Leo Premium",
      comment: "The title for paywall view"
    )
    public static let restorePaywallButtonTitle = NSLocalizedString(
      "aichat.restorePaywallButtonTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Restore",
      comment: "The button title for restoring ai-app purchse for Leo."
    )
    public static let paywallPurchaseErrorDescription = NSLocalizedString(
      "aichat.paywallPurchaseErrorDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Unable to complete purchase. Please try again, or check your payment details on Apple and try again.",
      comment: "The error description when in app purcahse is erroneous."
    )
    public static let paywallYearlySubscriptionTitle = NSLocalizedString(
      "aichat.paywallYearlySubscriptionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "One Year",
      comment: "Title indicating yearly subscription"
    )
    public static let paywallYearlySubscriptionDescription = NSLocalizedString(
      "aichat.paywallYearlySubscriptionDescription",
      tableName: "BraveLeo",
      bundle: .module,
      value: "One Year",
      comment: "The description indicating yearly subscription that show how much user is saving percentage"
    )
    public static let paywallYearlyPriceDividend = NSLocalizedString(
      "aichat.paywallYearlyPriceDividend",
      tableName: "BraveLeo",
      bundle: .module,
      value: "One Year",
      comment: "The description indicating yearly subscription that show how much user is saving percentage"
    )
  }
}
