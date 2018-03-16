/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

enum TabsBarShowPolicy : Int {
    case never
    case always
    case landscapeOnly
}

let kRearangeTabNotification = Notification.Name("kRearangeTabNotification")
let kPrefKeyTabsBarShowPolicy = "kPrefKeyTabsBarShowPolicy"
let kPrefKeyTabsBarOnDefaultValue = TabsBarShowPolicy.always

let minTabWidth =  UIDevice.current.userInterfaceIdiom == .pad ? CGFloat(180) : CGFloat(160)
let tabHeight: CGFloat = 29

protocol TabBarCellDelegate: class {
    func tabClose(_ tab: Tab?)
}

class TabBarCell: UICollectionViewCell {
    let title = UILabel()
    let close = UIButton()
    let separatorLine = UIView()
    let separatorLineRight = UIView()
    var currentIndex: Int = -1 {
        didSet {
            // FIXME: getApp
//            isSelected = currentIndex == getApp().tabManager.currentDisplayedIndex
        }
    }
    weak var browser: Tab? {

        didSet {
            // FIXME: web page state delegate
            /*
            if let wv = self.browser?.webView {
                wv.delegatesForPageState.append(BraveWebView.Weak_WebPageStateDelegate(value: self))
            }
            */
        }
    }
    weak var delegate: TabBarCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        
        close.addTarget(self, action: #selector(closeTab), for: .touchUpInside)
        
        [close, title, separatorLine, separatorLineRight].forEach { contentView.addSubview($0) }
        
        title.textAlignment = .center
        title.snp.makeConstraints({ (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self).inset(16)
            make.right.equalTo(close.snp.left)
        })
        
        close.setImage(UIImage(named: "stop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        close.snp.makeConstraints({ (make) in
            make.top.bottom.equalTo(self)
            make.right.equalTo(self).inset(2)
            make.width.equalTo(30)
        })

        // FIXME: Private browsing color
        // close.tintColor = PrivateBrowsing.singleton.isOn ? UIColor.white : UIColor.black
        close.tintColor = UIColor.white

        // Close button is a bit wider to increase tap area, this aligns 'X' image closer to the right.
        close.imageEdgeInsets.left = 6
        
        separatorLine.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        separatorLine.snp.makeConstraints { (make) in
            make.left.equalTo(self)
            make.width.equalTo(0.5)
            make.height.equalTo(self)
            make.centerY.equalTo(self.snp.centerY)
        }
        
        separatorLineRight.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        separatorLineRight.isHidden = true
        separatorLineRight.snp.makeConstraints { (make) in
            make.right.equalTo(self)
            make.width.equalTo(0.5)
            make.height.equalTo(self)
            make.centerY.equalTo(self.snp.centerY)
        }
        
        isSelected = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet(selected) {
            if selected {
                title.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
                close.isHidden = false
                // FIXME: Private browsing colors
                /*
                title.textColor = PrivateBrowsing.singleton.isOn ? UIColor.white : UIColor.black
                close.tintColor = PrivateBrowsing.singleton.isOn ? UIColor.white : UIColor.black
                backgroundColor = PrivateBrowsing.singleton.isOn ? BraveUX.DarkToolbarsBackgroundSolidColor : BraveUX.ToolbarsBackgroundSolidColor
                */
                title.textColor = UIColor.black
                close.tintColor = UIColor.black
                backgroundColor = BraveUX.barsBackgroundSolidColor
            }
            // FIXME: getApp, selected tab
            /*
            else if currentIndex != getApp().tabManager.currentDisplayedIndex {
                // prevent swipe and release outside- deselects cell.
                title.font = UIFont.systemFont(ofSize: 12)
                title.textColor = PrivateBrowsing.singleton.isOn ? UIColor(white: 1.0, alpha: 0.4) : UIColor(white: 0.0, alpha: 0.4)
                close.isHidden = true
                close.tintColor = PrivateBrowsing.singleton.isOn ? UIColor.white : UIColor.black
                backgroundColor = UIColor.clear
            }
            */
        }
    }
    
    func closeTab() {
        delegate?.tabClose(browser)
    }
    
    fileprivate var titleUpdateScheduled = false
    func updateTitle_throttled() {
        if titleUpdateScheduled {
            return
        }
        titleUpdateScheduled = true
//        postAsyncToMain(0.2) { [weak self] in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.titleUpdateScheduled = false
            self?.title.text = self?.browser?.displayTitle
        }
    }
}

// FIXME: WebPageStateDelegate
/*
extension TabBarCell: WebPageStateDelegate {
    func webView(_ webView: UIWebView, urlChanged: String) {
        title.text = browser?.displayTitle
        updateTitle_throttled()
    }
    
    func webView(_ webView: UIWebView, progressChanged: Float) {
        updateTitle_throttled()
    }
    
    func webView(_ webView: UIWebView, isLoading: Bool) {}
    func webView(_ webView: UIWebView, canGoBack: Bool) {}
    func webView(_ webView: UIWebView, canGoForward: Bool) {}
}
*/

class TabsBarViewController: UIViewController {
    var plusButton = UIButton()

    var leftOverflowIndicator : CAGradientLayer = CAGradientLayer()
    var rightOverflowIndicator : CAGradientLayer = CAGradientLayer()
    
    var collectionLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    fileprivate var tabList = WeakList<Tab>()

    var isVisible:Bool {
        return self.view.alpha > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.scrollDirection = .horizontal
        collectionLayout.itemSize = CGSize(width: minTabWidth, height: view.frame.height)
        collectionLayout.minimumInteritemSpacing = 0
        collectionLayout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: collectionLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.decelerationRate = UIScrollViewDecelerationRateNormal
        collectionView.register(TabBarCell.self, forCellWithReuseIdentifier: "TabCell")
        view.addSubview(collectionView)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        longPressGesture.minimumPressDuration = 0.2
        collectionView.addGestureRecognizer(longPressGesture)

        if UIDevice.current.userInterfaceIdiom == .pad {
            plusButton.setImage(UIImage(named: "add")!.withRenderingMode(.alwaysTemplate), for: .normal)
            plusButton.imageEdgeInsets = UIEdgeInsetsMake(6, 10, 6, 10)
            plusButton.tintColor = UIColor.black
            plusButton.contentMode = .scaleAspectFit
            plusButton.addTarget(self, action: #selector(addTabPressed), for: .touchUpInside)
            plusButton.backgroundColor = UIColor(white: 0.0, alpha: 0.075)
            view.addSubview(plusButton)

            plusButton.snp.makeConstraints { (make) in
                make.right.top.bottom.equalTo(view)
                make.width.equalTo(BraveUX.TabsBar.buttonWidth)
            }
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.bottom.top.left.equalTo(view)
            make.right.equalTo(view).inset(BraveUX.TabsBar.buttonWidth)
        }

        // FIXME: getApp
        // getApp().tabManager.addDelegate(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: kRearangeTabNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        updateData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // FIXME: getApp selected tab
        /*
        // ensure the selected tab is visible after rotations
        if let index = getApp().tabManager.currentDisplayedIndex {
            let indexPath = IndexPath(item: index, section: 0)
            // since bouncing is disabled, centering horizontally
            // will not overshoot the edges for the bookend tabs
            collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        */
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.reloadDataAndRestoreSelectedTab()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func orientationChanged() {
        overflowIndicators()
    }
    
    func updateData() {
        tabList = WeakList<Tab>()
        // FIXME: getApp
        /*
        getApp().tabManager.tabs.displayedTabsForCurrentPrivateMode.forEach {
            tabList.insert($0)
        }
        */
        overflowIndicators()
        
        reloadDataAndRestoreSelectedTab()
    }
    
    func reloadDataAndRestoreSelectedTab() {
        collectionView.reloadData()

        // FIXME: getApp selected tab
        /*
        if let selectedTab = getApp().tabManager.selectedTab {
            let selectedIndex = tabList.index(of: selectedTab) ?? 0
            if selectedIndex < tabList.count() {
                collectionView.selectItem(at: IndexPath(row: selectedIndex, section: 0), animated: (!getApp().tabManager.isRestoring), scrollPosition: .centeredHorizontally)
            }
        }
        */
    }
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case UIGestureRecognizerState.began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case UIGestureRecognizerState.changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case UIGestureRecognizerState.ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    func addTabPressed() {
        // FIXME: getApp
        // getApp().tabManager.addTabAndSelect()
    }

    func tabOverflowWidth(_ tabCount: Int) -> CGFloat {
        let overflow = CGFloat(tabCount) * minTabWidth - collectionView.frame.width
        return overflow > 0 ? overflow : 0
    }
    
    func overflowIndicators() {
        // super lame place to put this, need to find a better solution.
        // FIXME: Private browsing
        /*
        plusButton.tintColor = PrivateBrowsing.singleton.isOn ? UIColor.white : UIColor.black
        collectionView.backgroundColor = PrivateBrowsing.singleton.isOn ? UIColor(white: 0.0, alpha: 0.2) : UIColor(white: 0.0, alpha: 0.075)
        */
        plusButton.tintColor = UIColor.black
        collectionView.backgroundColor = UIColor(white: 0.0, alpha: 0.075)
        scrollHints()

        // FIXME: getApp tab count
        /*
        if tabOverflowWidth(getApp().tabManager.tabCount) < 1 {
            leftOverflowIndicator.opacity = 0
            rightOverflowIndicator.opacity = 0
            return
        }
        */
        
        let offset = Float(collectionView.contentOffset.x)
        let startFade = Float(30)
        if offset < startFade {
            leftOverflowIndicator.opacity = offset / startFade
        } else {
            leftOverflowIndicator.opacity = 1
        }
        
        // all the way scrolled right
        let offsetFromRight = collectionView.contentSize.width - CGFloat(offset) - collectionView.frame.width
        if offsetFromRight < CGFloat(startFade) {
            rightOverflowIndicator.opacity = Float(offsetFromRight) / startFade
        } else {
            rightOverflowIndicator.opacity = 1
        }
    }
    
    func scrollHints() {
        addLeftRightScrollHint(false, maskLayer: leftOverflowIndicator)
        addLeftRightScrollHint(true, maskLayer: rightOverflowIndicator)
    }

    func addLeftRightScrollHint(_ isRightSide: Bool, maskLayer: CAGradientLayer) {
        maskLayer.removeFromSuperlayer()
        // FIXME: Private browsing

        /*
        let colors = PrivateBrowsing.singleton.isOn ? [BraveUX.DarkToolbarsBackgroundSolidColor.withAlphaComponent(0).cgColor, BraveUX.DarkToolbarsBackgroundSolidColor.cgColor] : [BraveUX.ToolbarsBackgroundSolidColor.withAlphaComponent(0).cgColor, BraveUX.ToolbarsBackgroundSolidColor.cgColor]
        */
        let colors = [BraveUX.barsBackgroundSolidColor.withAlphaComponent(0).cgColor, BraveUX.barsBackgroundSolidColor.cgColor]
        let locations = [0.9, 1.0]
        maskLayer.startPoint = CGPoint(x: isRightSide ? 0 : 1.0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: isRightSide ? 1.0 : 0, y: 0.5)
        maskLayer.opacity = 0
        maskLayer.colors = colors;
        maskLayer.locations = locations as [NSNumber];
        maskLayer.bounds = CGRect(x: 0, y: 0, width: collectionView.frame.width, height: tabHeight)
        maskLayer.anchorPoint = CGPoint.zero;
        // you must add the mask to the root view, not the scrollView, otherwise the masks will move as the user scrolls!
        view.layer.addSublayer(maskLayer)
    }
}

extension TabsBarViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        overflowIndicators()
    }
}

extension TabsBarViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabList.count()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: TabBarCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath) as! TabBarCell
        guard let tab = tabList.at(indexPath.row) else { return cell }
        cell.delegate = self
        cell.browser = tab
        cell.title.text = tab.displayTitle
        cell.currentIndex = indexPath.row
        cell.separatorLineRight.isHidden = (indexPath.row != tabList.count() - 1)
        // FIXME: getApp
        // debugPrint("index: \(getApp().tabManager.currentDisplayedIndex ?? -1)")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tab = tabList.at(indexPath.row)
        // FIXME: getApp
        // getApp().tabManager.selectTab(tab)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if tabList.count() == 1 {
            return CGSize(width: view.frame.width, height: view.frame.height)
        }
        
        let newTabButtonWidth = CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? BraveUX.TabsBar.buttonWidth : 0)
        let tabsAndButtonWidth = CGFloat(tabList.count()) * minTabWidth
        if tabsAndButtonWidth < collectionView.frame.width - newTabButtonWidth {
            let maxWidth = (collectionView.frame.width - newTabButtonWidth) / CGFloat(tabList.count())
            return CGSize(width: maxWidth, height: view.frame.height)
        }
        
        return CGSize(width: minTabWidth, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let tab = tabList.at(sourceIndexPath.row) else { return }
        
        // Find original from/to index... we need to target the full list not partial.
        // FIXME: getApp, moving tabs, this is important

        /*
        guard let tabManager = getApp().tabManager else { return }
        guard let from = tabManager.tabs.tabs.index(where: {$0 === tab}) else { return }
        
        let toTab = tabList.at(destinationIndexPath.row)
        guard let to = tabManager.tabs.tabs.index(where: {$0 === toTab}) else { return }
        
        tabManager.move(tab: tab, from: from, to: to)
        updateData()
        
        guard let selectedTab = tabList.at(destinationIndexPath.row) else { return }
        tabManager.selectTab(selectedTab)
        */
    }
}

extension TabsBarViewController: TabBarCellDelegate {
    func tabClose(_ tab: Tab?) {
        guard let tab = tab else { return }
        // FIXME: getApp
        /*
        guard let tabManager = getApp().tabManager else { return }
        guard let previousIndex = tabList.index(of: tab) else { return }
        
        tabManager.removeTab(tab, createTabIfNoneLeft: true)
        
        updateData()
        
        let previousOrNext = max(0, previousIndex - 1)
        tabManager.selectTab(tabList.at(previousOrNext))
        
        collectionView.selectItem(at: IndexPath(row: previousOrNext, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        */
    }
}

extension TabsBarViewController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        assert(Thread.current.isMainThread)
        updateData()
    }

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {

    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        updateData()
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {

    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        assert(Thread.current.isMainThread)
        updateData()
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        assert(Thread.current.isMainThread)
        updateData()
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {

    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {

    }


    // FIXME: TabManagerDelegate changed a bit

    /*
    func tabManagerDidEnterPrivateBrowsingMode(_ tabManager: TabManager) {
        assert(Thread.current.isMainThread)
        updateData()
    }

    func tabManagerDidExitPrivateBrowsingMode(_ tabManager: TabManager) {
        assert(Thread.current.isMainThread)
        updateData()
    }

    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?) {
        assert(Thread.current.isMainThread)
        updateData()
    }

    func tabManager(_ tabManager: TabManager, didCreateWebView tab: Tab, url: URL?, at: Int?) {
        updateData()
        // getApp().browserViewController.urlBar.updateTabsBarShowing()
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        updateData()
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        assert(Thread.current.isMainThread)
        updateData()
        // getApp().browserViewController.urlBar.updateTabsBarShowing()
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        assert(Thread.current.isMainThread)
        updateData()
        // getApp().browserViewController.urlBar.updateTabsBarShowing()
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {}
    */
}
