/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import BraveShared
import Shared
import SnapKit
import Data
import Storage

/// The types of actions a user can do in the menu given a URL
enum MenuURLAction {
  /// Opens in URL the current tab
  case openInCurrentTab
  /// Opens in URL a new tab
  case openInNewTab(isPrivate: Bool)
  /// Copy the URL to clipboard
  case copy
  /// Show a share sheet for the URL
  case share
}

protocol HomeMenuControllerDelegate: class {
  func menuDidOpenSettings(_ menu: UIViewController)
  /// The user selected a url in one of the menu panels (i.e. bookmarks or history)
  func menuDidSelectURL(_ menu: UIViewController, url: URL, visitType: VisitType, action: MenuURLAction)
  /// The user tapped "Open All" on a folder
  func menuDidBatchOpenURLs(_ menu: UIViewController, urls: [URL])
}

class HomeMenuController: UIViewController, PopoverContentComponent {
  
  weak var delegate: HomeMenuControllerDelegate?
  
  let bookmarksController: BookmarksViewController
  fileprivate var bookmarksNavController: UINavigationController!
  
  let historyController: HistoryViewController
  
  var bookmarksButton = UIButton()
  var historyButton = UIButton()
  
  var settingsButton = UIButton()
  
  let topButtonsView = UIView()
  let addBookmarkButton = UIButton()
  
  let divider = UIView()
  
  weak var visibleController: UIViewController?
  
  var isPanToDismissEnabled: Bool {
    if visibleController === bookmarksNavController {
      // Don't break reordering bookmarks
      return !bookmarksController.tableView.isEditing
    }
    return true
  }
  
  // Buttons swap out the full page, meaning only one can be active at a time
  var pageButtons: [UIButton: UIViewController] {
    return [
      bookmarksButton: bookmarksNavController,
      historyButton: historyController,
    ]
  }
  
  private(set) weak var profile: Profile?
  
  let tabState: TabState
  
  init(profile: Profile, tabState: TabState) {
    self.profile = profile
    self.tabState = tabState
    let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
    self.bookmarksController = BookmarksViewController(folder: nil, isPrivateBrowsing: isPrivateBrowsing)
    self.historyController = HistoryViewController(isPrivateBrowsing: isPrivateBrowsing)
    
    super.init(nibName: nil, bundle: nil)
    bookmarksController.profile = profile
    historyController.profile = profile
    
    bookmarksController.bookmarksDidChange = { [weak self] in
      self?.updateBookmarkStatus()
    }
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    bookmarksNavController = UINavigationController(rootViewController: bookmarksController)
    bookmarksNavController.view.backgroundColor = UIColor.white
    view.addSubview(topButtonsView)
    
    topButtonsView.addSubview(bookmarksButton)
    topButtonsView.addSubview(historyButton)
    topButtonsView.addSubview(addBookmarkButton)
    topButtonsView.addSubview(settingsButton)
    topButtonsView.addSubview(divider)
    
    divider.backgroundColor = BraveUX.ColorForSidebarLineSeparators
    
    settingsButton.setImage(#imageLiteral(resourceName: "menu-settings").template, for: .normal)
    settingsButton.addTarget(self, action: #selector(onClickSettingsButton), for: .touchUpInside)
    settingsButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    settingsButton.accessibilityLabel = Strings.Settings
    
    bookmarksButton.setImage(#imageLiteral(resourceName: "menu-bookmark-list").template, for: .normal)
    bookmarksButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    bookmarksButton.accessibilityLabel = Strings.Show_Bookmarks
    
    historyButton.setImage(#imageLiteral(resourceName: "menu-history").template, for: .normal)
    historyButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    historyButton.accessibilityLabel = Strings.Show_History
    
    addBookmarkButton.addTarget(self, action: #selector(onClickBookmarksButton), for: .touchUpInside)
    addBookmarkButton.setImage(#imageLiteral(resourceName: "menu-add-bookmark").template, for: .normal)
    addBookmarkButton.setImage(#imageLiteral(resourceName: "menu-marked-bookmark").template, for: .selected)
    addBookmarkButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    addBookmarkButton.accessibilityLabel = Strings.Add_Bookmark
    
    pageButtons.keys.forEach { $0.addTarget(self, action: #selector(onClickPageButton), for: .touchUpInside) }
    
    settingsButton.tintColor = BraveUX.ActionButtonTintColor
    addBookmarkButton.tintColor = BraveUX.ActionButtonTintColor
    
    view.addSubview(historyController.view)
    view.addSubview(bookmarksNavController.view)
    
    // Setup the bookmarks button as default
    onClickPageButton(bookmarksButton)
    
    bookmarksNavController.view.isHidden = false
    
    view.bringSubview(toFront: topButtonsView)
    
    setupConstraints()
    updateBookmarkStatus()
  }
  
  @objc private func onClickSettingsButton() {
    delegate?.menuDidOpenSettings(self)
  }
  
  @objc private func onClickBookmarksButton() {
    guard let url = tabState.url else { return }
    
    // stop from spamming the button, and enabled is used elsewhere, so create a guard
    struct Guard { static var block = false }
    if Guard.block {
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      Guard.block = false
    }
    Guard.block = true
    
    //switch to bookmarks 'tab' in case we're looking at history and tapped the add/remove bookmark button
    onClickPageButton(bookmarksButton)
    
    if Bookmark.contains(url: url) {
      Bookmark.remove(forUrl: url)
    } else {
      Bookmark.add(url: url, title: tabState.title, parentFolder: bookmarksController.currentBookmarksPanel().currentFolder)
    }
  }
  
  func setupConstraints() {
    topButtonsView.snp.remakeConstraints { make in
      make.top.left.right.equalTo(self.view)
      make.height.equalTo(44.0 + 0.5)
    }
    
    func common(_ make: ConstraintMaker) {
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.width.equalTo(60)
    }
    
    settingsButton.snp.remakeConstraints { make in
      common(make)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(0.25)
    }
    
    divider.snp.remakeConstraints { make in
      make.bottom.equalTo(self.topButtonsView)
      make.width.equalTo(self.topButtonsView)
      make.height.equalTo(0.5)
    }
    
    historyButton.snp.remakeConstraints { make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(0.75)
    }
    
    bookmarksButton.snp.remakeConstraints { make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(1.25)
    }
    
    addBookmarkButton.snp.remakeConstraints { make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(1.75)
    }
    
    bookmarksNavController.view.snp.remakeConstraints { make in
      make.left.right.bottom.equalTo(self.view)
      make.top.equalTo(topButtonsView.snp.bottom)
    }
    
    historyController.view.snp.remakeConstraints { make in
      make.left.right.bottom.equalTo(self.view)
      make.top.equalTo(topButtonsView.snp.bottom)
    }
  }
  
  @objc private func onClickPageButton(_ sender: UIButton) {
    guard let vc = self.pageButtons[sender], let newView = vc.view else { return }
    
    // Hide all old views
    self.pageButtons.forEach { (btn, controller) in
      btn.isSelected = false
      btn.tintColor = BraveUX.ActionButtonTintColor
      controller.view.isHidden = true
    }
    
    // Setup the new view
    newView.isHidden = false
    sender.isSelected = true
    sender.tintColor = BraveUX.ActionButtonSelectedTintColor
    
    visibleController = vc
  }
  
  func updateBookmarkStatus() {
    guard let url = tabState.url, !url.isLocal else {
      //disable button for homescreen/empty url
      addBookmarkButton.isSelected = false
      addBookmarkButton.isEnabled = false
      return
    }
    
    addBookmarkButton.isEnabled = true
    addBookmarkButton.isSelected = Bookmark.contains(url: url)
  }
}
