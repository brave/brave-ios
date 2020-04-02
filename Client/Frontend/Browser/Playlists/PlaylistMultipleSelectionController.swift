// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

class PlaylistMultipleSelectionController: UIViewController {
    private var tabManager: TabManager
    private var playlistItems = [PlaylistInfo]()
    private var checkedItems = [Bool]()
    private let selectionView = PlaylistMultipleSelectionView()
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        selectionView.tableView.dataSource = self
        selectionView.tableView.delegate = self
        
        view.addSubview(selectionView)
        selectionView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.left.right.equalToSuperview().inset(15.0)
            $0.top.greaterThanOrEqualTo(view.safeArea.top).inset(15.0)
            $0.bottom.lessThanOrEqualTo(view.safeArea.bottom).inset(15.0)
        }
        
        tabManager.tabsForCurrentMode.forEach({
            $0.playlistItems.observe { [weak self] _, _ in
                guard let self = self else { return }
                self.updateItems()
            }.bind(to: self)
        })
        
        selectionView.exitButton.addTarget(self, action: #selector(onExit(_:)), for: .touchUpInside)
        selectionView.footerButton.addTarget(self, action: #selector(onAddItemsToPlaylist(_:)), for: .touchUpInside)
    }
        
    private func updateItems() {
        playlistItems = tabManager.tabsForCurrentMode.map({ $0.playlistItems }).flatMap({ $0.value })
        checkedItems = [Bool](repeating: false, count: playlistItems.count)
        selectionView.tableView.reloadData()
    }
    
    @objc
    private func onExit(_ button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    private func onAddItemsToPlaylist(_ button: UIButton) {
        let group = DispatchGroup()
        
        playlistItems.forEach({
            group.enter()
            Playlist.shared.addItem(item: $0, completion: {
                group.leave()
            })
        })
        
        group.notify(queue: .main) {
            self.tabManager.tabsForCurrentMode.forEach({
                $0.playlistItems.value.removeAll(where: {
                    Playlist.shared.itemExists(item: $0)
                })
            })
            
            let playlistController = UINavigationController(rootViewController: PlaylistViewController(tabManager: self.tabManager))
            self.present(playlistController, animated: true, completion: nil)
        }
    }
}

extension PlaylistMultipleSelectionController: UITableViewDataSource {
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
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistSelectionCell", for: indexPath) as? PlaylistSelectionCell else {
            return UITableViewCell()
        }
        
        let item = self.playlistItems[indexPath.row]
        
        cell.selectionStyle = .none
        cell.thumbnailView.image = #imageLiteral(resourceName: "shields-menu-icon")
        cell.titleLabel.text = item.name
        cell.detailLabel.isHidden = true
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        
        cell.thumbnailView.setFavicon(forSite: .init(url: item.pageSrc, title: item.pageTitle))
        cell.checkedIcon.isHidden = !checkedItems[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension PlaylistMultipleSelectionController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        checkedItems[indexPath.row].toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        let countOfCheckedItems = checkedItems.filter({ $0 }).count
        selectionView.footerButton.isHidden = countOfCheckedItems == 0
        selectionView.footerButton.setTitle("Add \(countOfCheckedItems) Item(s) to Playlist", for: .normal)
    }
}

private class PlaylistMultipleSelectionView: UIView {
    public let exitButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "close_popup"), for: .normal)
        $0.imageView?.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16.0, weight: .bold)
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.text = "Make a selection"
        $0.textAlignment = .center
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12.0, weight: .medium)
        $0.textColor = #colorLiteral(red: 0.8784313725, green: 0.8823529412, blue: 0.8784313725, alpha: 1)
        $0.appearanceTextColor = #colorLiteral(red: 0.8784313725, green: 0.8823529412, blue: 0.8784313725, alpha: 1)
        $0.text = "Multiple video files detected. Select which video(s) you would like to add."
        $0.numberOfLines = 2
        $0.textAlignment = .center
    }
    
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 15.0
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
    }
    
    public var footerButton = UIButton().then {
        $0.setTitle("Add to Playlist", for: .normal)
        $0.backgroundColor = #colorLiteral(red: 0.3019607843, green: 0.3450980392, blue: 0.8078431373, alpha: 1)
        $0.titleLabel?.font = .systemFont(ofSize: 14.0, weight: .medium)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.appearanceTextColor = .white
        $0.layer.masksToBounds = true
        $0.layer.cornerRadius = 20.0
    }
    
    private var footerStackView = UIStackView().then {
        $0.axis = .vertical
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(equalInset: 15.0)
    }
    
    public var tableView = UITableView(frame: .zero, style: .grouped)
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let layer = self.layer as? CAGradientLayer {
            layer.colors = [#colorLiteral(red: 0.368627451, green: 0.368627451, blue: 0.368627451, alpha: 1), #colorLiteral(red: 0.4196078431, green: 0.4196078431, blue: 0.4196078431, alpha: 1), #colorLiteral(red: 0.09411764706, green: 0.07843137255, blue: 0.1019607843, alpha: 1)].map({ $0.cgColor })
            layer.locations = [0.0, 0.5, 1.0]
            layer.startPoint = CGPoint(x: 0.5, y: 0.0)
            layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        }
        
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        
        tableView.backgroundView = UIView()
        tableView.backgroundColor = .clear
        tableView.appearanceBackgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.appearanceSeparatorColor = .clear
        
        tableView.register(PlaylistSelectionCell.self, forCellReuseIdentifier: "PlaylistSelectionCell")
        
        addSubview(exitButton)
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        addSubview(separator)
        addSubview(tableView)
        addSubview(footerStackView)
        footerStackView.addArrangedSubview(footerButton)
        
        exitButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8.0)
            $0.right.equalToSuperview().offset(-8.0)
        }
        
        stackView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(exitButton.snp.bottom)
        }
        
        separator.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(20.0)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(separator.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(45.0 * 3.0)
        }
        
        footerStackView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(20.0)
            $0.left.right.bottom.equalToSuperview()
        }
        
        footerButton.snp.makeConstraints {
            $0.height.equalTo(40.0)
        }
        
        //tableView.contentInsetAdjustmentBehavior = .never
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
