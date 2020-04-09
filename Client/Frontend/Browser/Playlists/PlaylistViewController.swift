// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveShared
import AVKit
import AVFoundation

class PlaylistViewController: UIViewController {
    private var tabManager: TabManager
    
    private let infoLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.appearanceTextColor = .white
        $0.numberOfLines = 0
        $0.text = "Playlist"
    }
    
    private let playerView = VideoView()
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var playlistItems = [PlaylistInfo]()
    private var itemToBeAdded: PlaylistInfo?
    private var cacheLoader = PlaylistCacheLoader()
    private var webLoader = PlaylistWebLoader(handler: { _ in })
    private var currentItem = -1
    private let activityIndicator = UIActivityIndicatorView(style: .white).then {
        $0.isHidden = true
        $0.hidesWhenStopped = true
    }
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.title = "Playlist"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).appearanceTextColor = .white
        
        navigationController?.presentationController?.delegate = self
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.appearanceBarTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(onClearAll(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close_popup"), style: .done, target: self, action: #selector(onExit(_:)))
        
        view.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        
        tableView.backgroundView = UIView()
        tableView.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        tableView.appearanceBackgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        tableView.separatorColor = .clear
        tableView.appearanceSeparatorColor = .clear
        
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: "PlaylistCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        view.addSubview(playerView)
        playerView.addSubview(activityIndicator)
        
        playerView.snp.makeConstraints {
            $0.top.equalTo(view.safeArea.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.60 * view.bounds.width)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeArea.edges)
        }
        
        //tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 0.60 * view.bounds.width, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.contentOffset = CGPoint(x: 0.0, y: -0.60 * view.bounds.width)
        
        tabManager.tabsForCurrentMode.forEach({
            $0.playlistItems.observe { [weak self] _, _ in
                guard let self = self else { return }
                self.updateItems()
            }.bind(to: self)
        })
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
    }
    
    private func updateItems() {
        //Only add items from the current tab
        itemToBeAdded = tabManager.selectedTab?.playlistItems.value.first
        
        //Add items from all tabs
        //itemsToBeAdded = tabManager.tabsForCurrentMode.map({ $0.playlistItems }).flatMap({ $0.value })
        
        //Fetch items from the database
        playlistItems = Playlist.shared.getItems()
        CarplayMediaManager.shared.updateItems()
        self.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
    }
    
    @objc
    private func onClearAll(_ button: UIBarButtonItem) {
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to remove all items from your playlist?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            self.playlistItems = []
            Playlist.shared.removeAll()
            
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PlaylistViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if itemToBeAdded != nil {
            return 84.0
        }
        
        if currentItem != -1 {
            return 50.0
        }
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        let item = self.playlistItems[indexPath.row]
        
        cell.selectionStyle = .none
        cell.indicatorIcon.image = #imageLiteral(resourceName: "videoThumbSlider").template
        cell.indicatorIcon.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        cell.thumbnailView.image = #imageLiteral(resourceName: "menu-NoImageMode")
        cell.titleLabel.text = item.name
        cell.detailLabel.text = URL(string: item.pageSrc)?.baseDomain ?? item.pageSrc //String(format: "%.2f mins", item.duration / 60.0)
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.thumbnailView.setFavicon(forSite: .init(url: item.pageSrc, title: item.pageTitle))
        
        if indexPath.row == currentItem {
            cell.indicatorIcon.image = #imageLiteral(resourceName: "videoPlayingIndicator")
            cell.indicatorIcon.tintColor = .clear
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return PlaylistItemPlayingView().then {
            if let item = self.itemToBeAdded {
                $0.titleLabel.text = item.name
                $0.detailLabel.text = URL(string: item.pageSrc)?.baseDomain
                $0.addButton.isHidden = false
            } else if currentItem != -1 {
                $0.titleLabel.text = playlistItems[currentItem].name
                $0.detailLabel.text = URL(string: playlistItems[currentItem].pageSrc)?.baseDomain
                $0.addButton.isHidden = true
            }
            $0.addButton.addTarget(self, action: #selector(onAddItem(_:)), for: .touchUpInside)
        }
    }
    
    @objc
    private func onAddItem(_ button: UIButton) {
        if let item = self.itemToBeAdded {
            Playlist.shared.addItem(item: item) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.itemToBeAdded = nil
                    self.playlistItems = Playlist.shared.getItems()
                    CarplayMediaManager.shared.updateItems()
                    self.tableView.reloadData()
                }
            }
        }
    }
}

extension PlaylistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < self.playlistItems.count {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            currentItem = indexPath.row
            let item = self.playlistItems[indexPath.row]
            let cache = Playlist.shared.getCache(item: item)
            
            infoLabel.text = item.name
            
            if cache.isEmpty {
                if let url = URL(string: item.src) {
                    self.playerView.load(url: url, resourceDelegate: nil)
                    self.activityIndicator.stopAnimating()
                } else {
                    webLoader = PlaylistWebLoader(handler: { [weak self] item in
                        guard let self = self else { return }
                        if let item = item, let url = URL(string: item.src) {
                            self.playerView.load(url: url, resourceDelegate: nil)
                            self.activityIndicator.stopAnimating()
                        } else {
                            self.activityIndicator.stopAnimating()
                            self.displayLoadingResourceError()
                        }
                    })
                    
                    if let url = URL(string: item.pageSrc) {
                        webLoader.load(url: url)
                    } else {
                        self.displayLoadingResourceError()
                    }
                }
            } else {
//                let directory = NSTemporaryDirectory()
//                let fileName = "foo.m4v"
//                let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])!
//
//                try? cache.write(to: fullURL, options: .atomicWrite)
                
                self.cacheLoader = PlaylistCacheLoader(cacheData: cache)
                let url = URL(string: "brave-media-ios://local-media-resource?time=\(Date().timeIntervalSince1970)")!
                self.playerView.load(url: url, resourceDelegate: self.cacheLoader)
            }
        }
        
        tableView.reloadData()
    }
    
    private func displayLoadingResourceError() {
        let alert = UIAlertController(title: "Sorry", message: "There was a problem loading the resource!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

private class PlaylistItemPlayingView: UIView {
    
    public let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 14.0, weight: .medium)
    }
    
    public let detailLabel = UILabel().then {
        $0.textColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.appearanceTextColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
    }
    
    public let addButton = UIButton().then {
        let image = #imageLiteral(resourceName: "playlistsAdd")
        $0.setTitle("Add", for: .normal)
        $0.setImage(image, for: .normal)
        $0.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 10 - image.size.width, bottom: 0.0, right: 0.0)
        $0.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0, bottom: 0.0, right: 0.0)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 20.0, bottom: 8.0, right: 20.0)
        $0.contentHorizontalAlignment = .left
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.appearanceTextColor = .white
        $0.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .semibold)
        $0.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        $0.layer.borderWidth = 1.0
        $0.layer.cornerRadius = 18.0
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 5.0
    }
    
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.preservesSuperviewLayoutMargins = false
        self.backgroundColor = #colorLiteral(red: 0.05098039216, green: 0.2862745098, blue: 0.4823529412, alpha: 1)
        
        self.addSubview(stackView)
        stackView.addArrangedSubview(infoStackView)
        stackView.addArrangedSubview(addButton)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)

        stackView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class PlaylistCell: UITableViewCell {
    public let indicatorIcon = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    public let thumbnailView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 5.0
        $0.layer.masksToBounds = true
    }
    
    public let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 14.0, weight: .medium)
    }
    
    public let detailLabel = UILabel().then {
        $0.textColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.appearanceTextColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
    }
    
    private let iconStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 15.0
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
        
        contentView.addSubview(iconStackView)
        contentView.addSubview(infoStackView)
        iconStackView.addArrangedSubview(indicatorIcon)
        iconStackView.addArrangedSubview(thumbnailView)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)
        contentView.addSubview(separator)
        
        indicatorIcon.snp.makeConstraints {
            $0.width.height.equalTo(12.0)
        }
        
        thumbnailView.snp.makeConstraints {
            $0.width.height.equalTo(30.0)
        }
        
        iconStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        infoStackView.snp.makeConstraints {
            $0.left.equalTo(iconStackView.snp.right).offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        separator.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.left)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var layoutMargins: UIEdgeInsets {
        get {
            return .zero
        }

        set (newValue) {
            _ = newValue
            super.layoutMargins = .zero
        }
    }
    
    override var separatorInset: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
        
        set (newValue) {
            _ = newValue
            super.separatorInset = UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
    }
}
