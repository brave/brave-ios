//
//  HomeMenuController.swift
//  Client
//
//  Created by Kyle Hickinson on 2018-05-30.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import Foundation
import UIKit
import BraveShared
import Shared
import SnapKit
import Data
import Storage

class HomeMenuController: UIViewController, PopoverContentComponent {
  
  let bookmarksPanel = OldBookmarksPanel(folder: nil)
  fileprivate var bookmarksNavController:UINavigationController!
  
  let history = HistoryPanel()
  
  var bookmarksButton = UIButton()
  var historyButton = UIButton()
  
  var settingsButton = UIButton()
  
  let topButtonsView = UIView()
  let addBookmarkButton = UIButton()
  
  let divider = UIView()
  
  // Buttons swap out the full page, meaning only one can be active at a time
  var pageButtons: Dictionary<UIButton, UIViewController> {
    return [
      bookmarksButton: bookmarksNavController,
      historyButton: history,
    ]
  }
  
  private(set) weak var profile: Profile?
  
  let tabState: TabState
  
  init(profile: Profile, tabState: TabState) {
    self.profile = profile
    self.tabState = tabState
    
    super.init(nibName: nil, bundle: nil)
    bookmarksPanel.profile = profile
    history.profile = profile
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    bookmarksNavController = UINavigationController(rootViewController: bookmarksPanel)
    bookmarksNavController.view.backgroundColor = UIColor.white
    view.addSubview(topButtonsView)
    
    topButtonsView.addSubview(bookmarksButton)
    topButtonsView.addSubview(historyButton)
    topButtonsView.addSubview(addBookmarkButton)
    topButtonsView.addSubview(settingsButton)
    topButtonsView.addSubview(divider)
    
    divider.backgroundColor = BraveUX.ColorForSidebarLineSeparators
    
    settingsButton.setImage(UIImage(named: "menu-settings")?.withRenderingMode(.alwaysTemplate), for: .normal)
    settingsButton.addTarget(self, action: #selector(onClickSettingsButton), for: .touchUpInside)
    settingsButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10)
    settingsButton.accessibilityLabel = Strings.Settings
    
    bookmarksButton.setImage(UIImage(named: "menu-bookmark-list")?.withRenderingMode(.alwaysTemplate), for: .normal)
    bookmarksButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10)
    bookmarksButton.accessibilityLabel = Strings.Show_Bookmarks
    
    historyButton.setImage(UIImage(named: "menu-history")?.withRenderingMode(.alwaysTemplate), for: .normal)
    historyButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10)
    historyButton.accessibilityLabel = Strings.Show_History
    
    addBookmarkButton.addTarget(self, action: #selector(onClickBookmarksButton), for: .touchUpInside)
    addBookmarkButton.setImage(UIImage(named: "menu-add-bookmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
    addBookmarkButton.setImage(UIImage(named: "menu-marked-bookmark")?.withRenderingMode(.alwaysTemplate), for: .selected)
    addBookmarkButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10)
    addBookmarkButton.accessibilityLabel = Strings.Add_Bookmark
    
    pageButtons.keys.forEach { $0.addTarget(self, action: #selector(onClickPageButton), for: .touchUpInside) }
    
    settingsButton.tintColor = BraveUX.ActionButtonTintColor
    addBookmarkButton.tintColor = BraveUX.ActionButtonTintColor
    
    view.addSubview(history.view)
    view.addSubview(bookmarksNavController.view)
    
    // Setup the bookmarks button as default
    onClickPageButton(bookmarksButton)
    
    bookmarksNavController.view.isHidden = false
    
    view.bringSubview(toFront: topButtonsView)
    
    setupConstraints()
    updateBookmarkStatus()
    
    // NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(historyItemAdded), name: kNotificationSiteAddedToHistory, object: nil)
  }

//  func willHide() {
//    //check if we are editing bookmark, if so pop controller then continue
//    if self.bookmarksNavController?.visibleViewController is BookmarkEditingViewController {
//      self.bookmarksNavController?.popViewController(animated: false)
//    }
//    if self.bookmarksPanel.currentBookmarksPanel().tableView.isEditing {
//      self.bookmarksPanel.currentBookmarksPanel().disableTableEditingMode()
//    }
//  }
  
  @objc private func onClickSettingsButton() {
    guard let profile = profile else {
      return
    }
//
//    let settingsTableViewController = BraveSettingsView(style: .grouped)
//    settingsTableViewController.profile = getApp().profile
//
//    let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
//    controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
//    present(controller, animated: true, completion: nil)
  }
  
  //For this function to be called there *must* be a selected tab and URL
  //since we disable the button when there's no URL
  //see MainSidePanelViewController#updateBookmarkStatus(isBookmarked,url)
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
    
    if Bookmark.contains(url: url, context: DataController.shared.workerContext) {
      print("remove")
    } else {
      print("add")
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
    
    settingsButton.snp.remakeConstraints {
      make in
      common(make)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(0.25)
    }
    
    divider.snp.remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.width.equalTo(self.topButtonsView)
      make.height.equalTo(0.5)
    }
    
    historyButton.snp.remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(0.75)
    }
    
    bookmarksButton.snp.remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(1.25)
    }
    
    addBookmarkButton.snp.remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(1.75)
    }
    
    bookmarksNavController.view.snp.remakeConstraints { make in
      make.left.right.bottom.equalTo(self.view)
      make.top.equalTo(topButtonsView.snp.bottom)
    }
    
    history.view.snp.remakeConstraints { make in
      make.left.right.bottom.equalTo(self.view)
      make.top.equalTo(topButtonsView.snp.bottom)
    }
  }
  
  @objc private func onClickPageButton(_ sender: UIButton) {
    guard let newView = self.pageButtons[sender]?.view else { return }
    
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
  }
  
  func setHomePanelDelegate(_ delegate: HomePanelDelegate?) {
    bookmarksPanel.homePanelDelegate = delegate
    history.homePanelDelegate = delegate

    if (delegate != nil) {
      bookmarksPanel.reloadData()
      history.reloadData()
    }
  }
  
  func updateBookmarkStatus() {
    guard let url = tabState.url else {
      //disable button for homescreen/empty url
      addBookmarkButton.isSelected = false
      addBookmarkButton.isEnabled = false
      return
    }
    
    addBookmarkButton.isEnabled = true
    addBookmarkButton.isSelected = Bookmark.contains(url: url, context: DataController.shared.workerContext)
  }
}
