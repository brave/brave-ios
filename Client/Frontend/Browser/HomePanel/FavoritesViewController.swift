/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import BraveShared
import XCGLogger
import Storage
import Deferred
import Data
import SnapKit

private let log = Logger.browserLogger

protocol TopSitesDelegate: AnyObject {
    func didSelect(input: String)
    func didTapDuckDuckGoCallout()
}

class FavoritesViewController: UIViewController, Themeable {
    private struct UI {
        static let statsHeight: CGFloat = 110.0
        static let statsBottomMargin: CGFloat = 5
        static let searchEngineCalloutPadding: CGFloat = 30.0
    }
    
    fileprivate var credit: (name: String, url: String?)?
    weak var delegate: TopSitesDelegate?
    
    // MARK: - Favorites collection view properties
    private (set) internal lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 6
        
        let view = UICollectionView(frame: self.view.frame, collectionViewLayout: layout).then {
            $0.backgroundColor = .clear
            $0.delegate = self
        
            let cellIdentifier = FavoriteCell.identifier
            $0.register(FavoriteCell.self, forCellWithReuseIdentifier: cellIdentifier)
            $0.keyboardDismissMode = .onDrag
            $0.alwaysBounceVertical = true
            $0.accessibilityIdentifier = "Top Sites View"
            // Entire site panel, including the stats view insets
            $0.contentInset = UIEdgeInsets(top: UI.statsHeight, left: 0, bottom: 0, right: 0)
        }
        return view
    }()
    private let dataSource: FavoritesDataSource
    
    private let braveShieldStatsView = BraveShieldStatsView(frame: CGRect.zero).then {
        $0.autoresizingMask = [.flexibleWidth]
    }
    
    private let ddgLogo = UIImageView(image: #imageLiteral(resourceName: "duckduckgo"))
    
    private let ddgLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.textColor = BraveUX.GreyD
        $0.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        $0.text = Strings.DDG_promotion
    }
    
    private lazy var ddgButton = UIControl().then {
        $0.addTarget(self, action: #selector(showDDGCallout), for: .touchUpInside)
    }
    
    @objc private func showDDGCallout() {
        delegate?.didTapDuckDuckGoCallout()
    }
    
    // MARK: - Init/lifecycle
    
    private let profile: Profile
    
    init(profile: Profile, dataSource: FavoritesDataSource = FavoritesDataSource()) {
        self.profile = profile
        self.dataSource = dataSource
        
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.do {
            $0.addObserver(self, selector: #selector(existingUserTopSitesConversion), 
                           name: Notification.Name.TopSitesConversion, object: nil)
            $0.addObserver(self, selector: #selector(privateBrowsingModeChanged), 
                           name: Notification.Name.PrivacyModeChanged, object: nil)
        }   
    }
    
    @objc func existingUserTopSitesConversion() {
        dataSource.refetch()
        collection.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.do {
            $0.removeObserver(self, name: Notification.Name.TopSitesConversion, object: nil)
            $0.removeObserver(self, name: Notification.Name.PrivacyModeChanged, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        
        credit = setupBackgroundImage()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        collection.addGestureRecognizer(longPressGesture)
        
        view.addSubview(collection)
        collection.dataSource = dataSource
        dataSource.collectionView = collection
        
        // Could setup as section header but would need to use flow layout,
        // Auto-layout subview within collection doesn't work properly,
        // Quick-and-dirty layout here.
        var statsViewFrame: CGRect = braveShieldStatsView.frame
        statsViewFrame.origin.x = 20
        // Offset the stats view from the inset set above
        statsViewFrame.origin.y = -(UI.statsHeight + UI.statsBottomMargin)
        statsViewFrame.size.width = collection.frame.width - statsViewFrame.minX * 2
        statsViewFrame.size.height = UI.statsHeight
        braveShieldStatsView.frame = statsViewFrame
        
        collection.addSubview(braveShieldStatsView)
        collection.addSubview(ddgButton)
        
        ddgButton.addSubview(ddgLogo)
        ddgButton.addSubview(ddgLabel)
        
        makeConstraints()
        
        collectionContentSizeObservation = collection.observe(\.contentSize, options: [.new, .initial]) { [weak self] _, _ in
            self?.updateDuckDuckGoButtonLayout()
        }
        updateDuckDuckGoVisibility()
    }
    
    private var collectionContentSizeObservation: NSKeyValueObservation?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // This makes collection view layout to recalculate its cell size.
        collection.collectionViewLayout.invalidateLayout()
    }
    
    private func updateDuckDuckGoButtonLayout() {
        let size = ddgButton.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        ddgButton.frame = CGRect(
            x: ceil((collection.bounds.width - size.width) / 2.0),
            y: collection.contentSize.height + UI.searchEngineCalloutPadding,
            width: size.width,
            height: size.height
        )
    }
    
    /// Handles long press gesture for UICollectionView cells reorder.
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = collection.indexPathForItem(at: gesture.location(in: collection)) else {
                handleLongGestureForBackground(gesture: gesture)
                break
            }
            
            dataSource.isEditing = true
            collection.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collection.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collection.endInteractiveMovement()
        default:
            collection.cancelInteractiveMovement()
        }
    }
    
    /// Handles long press gesture for background credit
    func handleLongGestureForBackground(gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began {
            return
        }
        
        let alert = UIAlertController(title: credit?.name, message: credit?.url ?? "", preferredStyle: .actionSheet)
        
        if let creditURL = credit?.url {
            alert.addAction(UIAlertAction(title: "Open Website", style: .default) { [weak self] _ in
                self?.delegate?.didSelect(input: creditURL)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Constraints setup
    fileprivate func makeConstraints() {
        collection.snp.makeConstraints { make in
            make.left.right.equalTo(self.view.safeAreaLayoutGuide)
            make.top.bottom.equalTo(self.view)
        }
        
        ddgLogo.snp.makeConstraints { make in
            make.top.left.bottom.equalTo(0)
            make.size.equalTo(38)
        }
        
        ddgLabel.snp.makeConstraints { make in
            make.top.right.bottom.equalTo(0)
            make.left.equalTo(self.ddgLogo.snp.right).offset(5)
            make.width.equalTo(180)
            make.centerY.equalTo(self.ddgLogo)
        }
    }
    
    // MARK: - Private browsing modde
    @objc func privateBrowsingModeChanged() {
        updateDuckDuckGoVisibility()
    }
    
    var themeableChildren: [Themeable?]? {
        return [braveShieldStatsView]
    }
    
    func applyTheme(_ theme: Theme) {
        styleChildren(theme: theme)
       
        view.backgroundColor = theme.colors.home
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        collection.collectionViewLayout.invalidateLayout()
    }
    
    private func setupBackgroundImage() -> (name: String, url: String?)? {
        guard let background = randomBackground() else {
            return nil
        }
        
        let image = background.image
        
        let imageAspectRatio = image.size.width / image.size.height
        let imageView = UIImageView(image: image)
        
        imageView.contentMode = UIImageView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.snp.makeConstraints {
            
            // Determines the height of the content
            // `999` priority is required for landscape, since top/bottom constraints no longer the most important
            //   using `high` is not enough either.
            $0.top.bottom.equalToSuperview().priority(ConstraintPriority(999))
            
            // In portrait `top`/`bottom` is enough, however, when switching to landscape, those constraints
            //  don't force centering, so this is used as a stronger constraint to center in landscape/portrait
            $0.centerY.equalToSuperview()
            
            // Width of the image view is determined by the forced height constraint and the literal image ratio
            $0.width.equalTo(imageView.snp.height).multipliedBy(imageAspectRatio)
            
            // These are required constraints to avoid a bad center pushing the image out of view.
            // if a center of `-100` or `100000` is specified, these override to keep entire background covered by image.
            // The left side cannot exceed `0` (or superview's left side), otherwise whitespace will be shown on left.
            $0.left.lessThanOrEqualToSuperview()
            
            // the right side cannot drop under `width` (or superview's right side), otherwise whitespace will be shown on right.
            $0.right.greaterThanOrEqualToSuperview()
            
            // If for some reason the image cannot fill full width (e.g. not a landscape image), then these constraints
            //  will fail. A constraint will be broken, since cannot keep both left and right side's pinned
            //  (due to the width multiplier being < 1
            
            // Center point of image is not center point of view.
            // Take `0` for example, if specying `0`, setting centerX to 0, it is not attempting to place the left
            //  side of the image to the middle (e.g. left justifying), it is instead trying to move the image view's
            //  center to `0`, shifting the image _to_ the left, and making more of the image's right side visible.
            // Therefore specifying `0` should take the imageView's left and pinning it to view's center
            
            // So basically the movement needs to be "inverted"
            
            // Need to calculate the sizing difference between `image` and `imageView` to determine the pixel difference ratio
            let sizeRatio = imageView.superview!.frame.size.width / image.size.width
            // See above for negation, image and imageView function as inverses, so need to negate
            let imageOffset = -background.center
            // Image number is given in pixels, must convert to points using screen
            let screenScale = UIScreen.main.scale
            let imageViewOffset = sizeRatio * imageOffset * screenScale
            
            // Using `high` priority so that it will not be applied / broken  if out-of-bounds
            $0.left.equalTo(view.snp.centerX).offset(imageViewOffset).priority(ConstraintPriority.high)
        }
        
        view.layer.addSublayer(gradientOverlay())
        return background.credit
    }
    
    private func randomBackground() -> (image: UIImage, center: CGFloat, credit: (name: String, url: String?))? {
        guard let filePath = Bundle.main.path(forResource: "ntp-data", ofType: "json") else {
            Logger.browserLogger.error("Failed to get bundle path for \"ntp-data.json\"")
            return nil
        }
        
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = try JSONSerialization.jsonObject(with: fileData, options: []) as? [[String: Any]] ?? []
            
            if json.count == 0 { return nil }
            
            let randomBackgroundIndex = Int.random(in: 0..<json.count)
            let backgroundJSON = json[randomBackgroundIndex]
            
            let center = backgroundJSON["center"] as? CGFloat ?? 0
            
            guard
                let imageName = backgroundJSON["image"] as? String,
                let image = UIImage(named: imageName) else {
                    return nil
            }
            
            guard
                let credit = backgroundJSON["credit"] as? [String: String],
                let name = credit["name"] else {
                    return nil
            }

            return (image, center, (name, credit["url"]))
        } catch {
            return nil
        }
    }
    
    fileprivate func gradientOverlay() -> CAGradientLayer {
        
        // Fades from half-black to transparent
        let colorTop = UIColor(white: 0.0, alpha: 0.5).cgColor
        let colorBottom = UIColor(white: 0.0, alpha: 0.0).cgColor
        
        let gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        
        // Only covers to third of the screen
        gl.locations = [0.0, 0.33]
        
        // Making a squrare to handle rotation events
        let maxSide = max(view.bounds.height, view.bounds.width)
        gl.frame = CGRect(size: CGSize(width: maxSide, height: maxSide))
        
        return gl
    }
    
    // MARK: DuckDuckGo
    
    func shouldShowDuckDuckGoCallout() -> Bool {
        let isSearchEngineSet = profile.searchEngines.defaultEngine(forType: .privateMode).shortName == OpenSearchEngine.EngineNames.duckDuckGo
        let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
        let shouldShowPromo = SearchEngines.shouldShowDuckDuckGoPromo
        return isPrivateBrowsing && !isSearchEngineSet && shouldShowPromo
    }
    
    func updateDuckDuckGoVisibility() {
        let isVisible = shouldShowDuckDuckGoCallout()
        let heightOfCallout = ddgButton.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height + (UI.searchEngineCalloutPadding * 2.0)
        collection.contentInset.bottom = isVisible ? heightOfCallout : 0
        ddgButton.isHidden = !isVisible
    }
}

// MARK: - Delegates
extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fav = dataSource.favoriteBookmark(at: indexPath)
        
        guard let urlString = fav?.url else { return }
        
        delegate?.didSelect(input: urlString)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collection.frame.width
        let padding: CGFloat = traitCollection.horizontalSizeClass == .compact ? 6 : 20
        
        let cellWidth = floor(width - padding) / CGFloat(columnsPerRow)
        // The tile's height is determined the aspect ratio of the thumbnails width. We also take into account
        // some padding between the title and the image.
        let cellHeight = floor(cellWidth / (CGFloat(FavoriteCell.imageAspectRatio) - 0.1))
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let favoriteCell = cell as? FavoriteCell else { return }
        favoriteCell.delegate = self
    }
    
    fileprivate var columnsPerRow: Int {
        let size = collection.bounds.size
        let traitCollection = collection.traitCollection
        var cols = 0
        if traitCollection.horizontalSizeClass == .compact {
            // Landscape iPhone
            if traitCollection.verticalSizeClass == .compact {
                cols = 5
            }
                // Split screen iPad width
            else if size.widthLargerOrEqualThanHalfIPad() {
                cols = 4
            }
                // iPhone portrait
            else {
                cols = 3
            }
        } else {
            // Portrait iPad
            if size.height > size.width {
                cols = 4
            }
                // Landscape iPad
            else {
                cols = 5
            }
        }
        return cols + 1
    }
}

extension FavoritesViewController: FavoriteCellDelegate {
    func editFavorite(_ favoriteCell: FavoriteCell) {
        guard let indexPath = collection.indexPath(for: favoriteCell),
            let fav = dataSource.frc?.fetchedObjects?[indexPath.item] else { return }
        
        let actionSheet = UIAlertController(title: fav.displayTitle, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: Strings.Remove_Favorite, style: .destructive) { _ in
            fav.delete()
            
            // Remove cached icon.
            if let urlString = fav.url, let url = URL(string: urlString) {
                ImageCache.shared.remove(url, type: .square)
            }
            
            self.dataSource.isEditing = false
        }
        
        let editAction = UIAlertAction(title: Strings.Edit_Favorite, style: .default) { _ in
            guard let title = fav.displayTitle, let urlString = fav.url else { return }
            
            let editPopup = UIAlertController.userTextInputAlert(title: Strings.Edit_Bookmark, message: urlString,
                                                                 startingText: title, startingText2: fav.url,
                                                                 placeholder2: urlString,
                                                                 keyboardType2: .URL) { callbackTitle, callbackUrl in
                                                                    if let cTitle = callbackTitle, !cTitle.isEmpty, let cUrl = callbackUrl, !cUrl.isEmpty {
                                                                        if URL(string: cUrl) != nil {
                                                                            fav.update(customTitle: cTitle, url: cUrl)
                                                                        }
                                                                    }
                                                                    self.dataSource.isEditing = false
            }
            
            self.present(editPopup, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)
        
        actionSheet.addAction(editAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.permittedArrowDirections = .any
            actionSheet.popoverPresentationController?.sourceView = favoriteCell
            actionSheet.popoverPresentationController?.sourceRect = favoriteCell.bounds
            present(actionSheet, animated: true)
        } else {
            present(actionSheet, animated: true) {
                self.dataSource.isEditing = false
            }
        }
    }
}

extension CGSize {
    public func widthLargerOrEqualThanHalfIPad() -> Bool {
        let halfIPadSize: CGFloat = 507
        return width >= halfIPadSize
    }
}
