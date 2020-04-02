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
    
    private let stackView = UIStackView().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
    }
    
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
    private var cacheLoader = PlaylistCacheLoader()
    private var webLoader = PlaylistWebLoader(handler: { _ in })
    private var currentItem = 0
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
    
        navigationController?.presentationController?.delegate = self
        navigationController?.navigationBar.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.appearanceBarTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "browser_lock_popup")).then {
            $0.contentMode = .scaleAspectFit
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear All", style: .plain, target: nil, action: nil)
        
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
        view.addSubview(stackView)
        view.addSubview(playerView)
        playerView.addSubview(activityIndicator)
        stackView.addArrangedSubview(infoLabel)
        
        stackView.snp.makeConstraints {
            $0.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(40.0)
        }
        
        playerView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom)
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
        tableView.contentInset = UIEdgeInsets(top: (0.60 * view.bounds.width) + 40.0, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.contentOffset = CGPoint(x: 0.0, y: (-0.60 * view.bounds.width) - 40.0)
        
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
        playlistItems = Playlist.shared.getItems()
        CarplayMediaManager.shared.updateItems()
        
        self.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
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
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        let item = self.playlistItems[indexPath.row]
        
        cell.selectionStyle = .none
        cell.indicatorIcon.image = #imageLiteral(resourceName: "videoThumbSlider").template
        cell.indicatorIcon.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        cell.thumbnailView.image = #imageLiteral(resourceName: "shields-menu-icon")
        cell.titleLabel.text = item.name
        cell.detailLabel.text = String(format: "%.2f mins", item.duration / 60.0)
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
        return PlaylistHeader()
    }
}

extension PlaylistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        currentItem = indexPath.row
        let item = self.playlistItems[indexPath.row]
        let cache = Playlist.shared.getCache(item: item)
        
        infoLabel.text = item.name
        if let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell, let image = cell.thumbnailView.image {
            (navigationItem.titleView as? UIImageView)?.image = image
        } else {
            (navigationItem.titleView as? UIImageView)?.setFavicon(forSite: .init(url: item.pageSrc, title: item.pageTitle), onCompletion: { [weak self] _, _ in
                guard let self = self else { return }
                self.navigationItem.titleView?.backgroundColor = .clear
                self.navigationItem.titleView?.tintColor = .white
            })
        }
        
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
            self.cacheLoader = PlaylistCacheLoader(cacheData: cache)
            self.playerView.load(url: URL(string: "brave-ios://local-media-resource")!, resourceDelegate: self.cacheLoader)
        }
        
        tableView.reloadData()
    }
    
    private func displayLoadingResourceError() {
        let alert = UIAlertController(title: "Sorry", message: "There was a problem loading the resource!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

private class PlaylistHeader: UIView {
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 17.0, weight: .bold)
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.text = "Playlist"
    }
    
    private let sortButton = UIButton().then {
        $0.setTitle("Sort by Most Recent ", for: .normal)
        $0.setTitleColor(#colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14.0, weight: .regular)
        $0.setImage(#imageLiteral(resourceName: "find_next").scale(toSize: CGSize(width: 12, height: 8)).template, for: .normal)
        $0.imageView?.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        $0.imageView?.contentMode = .scaleAspectFit
        
        $0.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        $0.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        $0.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        addSubview(sortButton)
        addSubview(separator)
        
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-15.0)
        }
        
        sortButton.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-15.0)
        }
        
        separator.snp.makeConstraints {
            $0.left.equalToSuperview().offset(87.0)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
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
            super.layoutMargins = .zero
        }
    }
    
    override var separatorInset: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
        
        set (newValue) {
            super.separatorInset = UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
    }
}
