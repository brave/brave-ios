/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

enum TabsBarShowPolicy: Int {
    case never, always, landscapeOnly
}

let kRearangeTabNotification = Notification.Name("kRearangeTabNotification")
let kPrefKeyTabsBarShowPolicy = "kPrefKeyTabsBarShowPolicy"
let kPrefKeyTabsBarOnDefaultValue = TabsBarShowPolicy.always

class TabsBarViewController: UIViewController {
    var plusButton = UIButton()

    var leftOverflowIndicator : CAGradientLayer = CAGradientLayer()
    var rightOverflowIndicator : CAGradientLayer = CAGradientLayer()
    
    var collectionLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!

    weak var tabManager: TabManager?
    
    fileprivate var tabList = WeakList<Tab>()

    var isVisible:Bool {
        return self.view.alpha > 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.scrollDirection = .horizontal
        collectionLayout.itemSize = CGSize(width: BraveUX.TabsBar.minimumWidth, height: view.frame.height)
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
            plusButton.setImage(UIImage(named: "add_tab")!.withRenderingMode(.alwaysTemplate), for: .normal)
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

        tabManager?.addDelegate(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: kRearangeTabNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        updateData()


    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // ensure the selected tab is visible after rotations
        if let index = tabManager?.currentDisplayedIndex {
            let indexPath = IndexPath(item: index, section: 0)
            // since bouncing is disabled, centering horizontally
            // will not overshoot the edges for the bookend tabs
            collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
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

        guard let tabsToUpdate = UIApplication.isInPrivateMode ? tabManager?.privateTabs : tabManager?.normalTabs else {
            return
        }

        tabsToUpdate.forEach {
            tabList.insert($0)
        }

        overflowIndicators()
        
        reloadDataAndRestoreSelectedTab()
    }
    
    func reloadDataAndRestoreSelectedTab() {
        collectionView.reloadData()

        if let selectedTab = tabManager?.selectedTab, let tabManager = tabManager {
            let selectedIndex = tabList.index(of: selectedTab) ?? 0
            if selectedIndex < tabList.count() {
                collectionView.selectItem(at: IndexPath(row: selectedIndex, section: 0), animated: (!tabManager.isRestoring), scrollPosition: .centeredHorizontally)
            }
        }
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
        tabManager?.addTabAndSelect()
    }

    func tabOverflowWidth(_ tabCount: Int) -> CGFloat {
        let overflow = CGFloat(tabCount) * BraveUX.TabsBar.minimumWidth - collectionView.frame.width
        return overflow > 0 ? overflow : 0
    }
    
    func overflowIndicators() {
        // super lame place to put this, need to find a better solution.
        plusButton.tintColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
        collectionView.backgroundColor = UIApplication.isInPrivateMode ? UIColor(white: 0.0, alpha: 0.2) : UIColor(white: 0.0, alpha: 0.075)

        scrollHints()

        // FIXME: getApp tab count, we are not going to show tabs count btw.
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

        let colors = UIApplication.isInPrivateMode ? [BraveUX.barsDarkBackgroundSolidColor.withAlphaComponent(0).cgColor, BraveUX.barsDarkBackgroundSolidColor.cgColor] : [BraveUX.barsBackgroundSolidColor.withAlphaComponent(0).cgColor, BraveUX.barsBackgroundSolidColor.cgColor]

        let locations = [0.9, 1.0]
        maskLayer.startPoint = CGPoint(x: isRightSide ? 0 : 1.0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: isRightSide ? 1.0 : 0, y: 0.5)
        maskLayer.opacity = 0
        maskLayer.colors = colors;
        maskLayer.locations = locations as [NSNumber];
        maskLayer.bounds = CGRect(x: 0, y: 0, width: collectionView.frame.width, height: BraveUX.TabsBar.height)
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
        cell.tabManager = tabManager
        cell.tab = tab
        cell.titleLabel.text = tab.displayTitle
        cell.currentIndex = indexPath.row
        cell.separatorLineRight.isHidden = (indexPath.row != tabList.count() - 1)

        cell.closeTabCallback = { [weak self] tab in
            guard let strongSelf = self, let tabManager = self?.tabManager, let previousIndex = self?.tabList.index(of: tab) else { return }

            tabManager.removeTab(tab)
            strongSelf.updateData()

            let previousOrNext = max(0, previousIndex - 1)
            tabManager.selectTab(strongSelf.tabList.at(previousOrNext))

            strongSelf.collectionView.selectItem(at: IndexPath(row: previousOrNext, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tab = tabList.at(indexPath.row)
        tabManager?.selectTab(tab)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if tabList.count() == 1 {
            return CGSize(width: view.frame.width, height: view.frame.height)
        }
        
        let newTabButtonWidth = CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? BraveUX.TabsBar.buttonWidth : 0)
        let tabsAndButtonWidth = CGFloat(tabList.count()) * BraveUX.TabsBar.minimumWidth
        if tabsAndButtonWidth < collectionView.frame.width - newTabButtonWidth {
            let maxWidth = (collectionView.frame.width - newTabButtonWidth) / CGFloat(tabList.count())
            return CGSize(width: maxWidth, height: view.frame.height)
        }
        
        return CGSize(width: BraveUX.TabsBar.minimumWidth, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let tab = tabList.at(sourceIndexPath.row) else { return }
        
        // Find original from/to index... we need to target the full list not partial.
        guard let tabManager = tabManager else { return }
        guard let from = tabManager.tabs.index(where: {$0 === tab}) else { return }
        
        let toTab = tabList.at(destinationIndexPath.row)
        guard let to = tabManager.tabs.index(where: {$0 === toTab}) else { return }

        tabManager.moveTab(isPrivate: UIApplication.isInPrivateMode, fromIndex: from, toIndex: to)
        updateData()
        
        guard let selectedTab = tabList.at(destinationIndexPath.row) else { return }
        tabManager.selectTab(selectedTab)
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
}
