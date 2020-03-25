// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

class AddToPlaylistViewController: UIViewController {
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
        $0.numberOfLines = 2
        $0.text = "Multiple items were found on this page.\nSelect all items you would like to add to playlist."
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
    }
    
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var footerButton = UIButton().then {
        $0.setTitle("Add Item(s) to Playlist", for: .normal)
        $0.backgroundColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        $0.titleLabel?.font = .systemFont(ofSize: 14.0, weight: .medium)
        $0.isHidden = true
    }
    private var footerStackView = UIStackView().then {
        $0.axis = .vertical
    }
    
    private var playlistItems = [PlaylistInfo]()
    private var checkedItems = [Bool]()
    private var isSelectingAll = true
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = "Add to Playlist"
        navigationController?.navigationBar.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.appearanceBarTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(onSelectAll(_:)))
        
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17.0, weight: .medium)
        ]
        
        view.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        
        tableView.backgroundView = UIView()
        tableView.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        tableView.appearanceBackgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        tableView.separatorColor = .clear
        tableView.appearanceSeparatorColor = .clear
        
        tableView.register(PlaylistSelectionCell.self, forCellReuseIdentifier: "PlaylistSelectionCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        view.addSubview(stackView)
        view.addSubview(separator)
        view.addSubview(footerStackView)
        stackView.addArrangedSubview(infoLabel)
        footerStackView.addArrangedSubview(footerButton)
        
        stackView.snp.makeConstraints {
            $0.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(40.0)
        }
        
        separator.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(10.0)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeArea.edges)
        }
        
        footerStackView.snp.makeConstraints {
            $0.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(42.0)
        }
        
        //tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 50.0, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.contentOffset = CGPoint(x: 0.0, y: -50.0)

        tabManager.tabsForCurrentMode.forEach({
            $0.playlistItems.observe { [weak self] _, _ in
                guard let self = self else { return }
                self.updateItems()
            }.bind(to: self)
        })
        
        footerButton.addTarget(self, action: #selector(onAddItemsToPlaylist(_:)), for: .touchUpInside)
    }
    
    private func updateItems() {
        playlistItems = tabManager.tabsForCurrentMode.map({ $0.playlistItems }).flatMap({ $0.value })
        checkedItems = [Bool](repeating: false, count: playlistItems.count)
        footerButton.isHidden = true
    }
    
    @objc
    private func onSelectAll(_ button: UIBarButtonItem) {
        for i in 0..<checkedItems.count {
            checkedItems[i] = isSelectingAll
        }
        
        if isSelectingAll {
            footerButton.isHidden = false
            footerButton.setTitle("Add \(playlistItems.count) Item(s) to Playlist", for: .normal)
        } else {
            footerButton.isHidden = true
            footerButton.setTitle("Add Item(s) to Playlist", for: .normal)
        }
        
        isSelectingAll.toggle()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: isSelectingAll ? "Select All" : "Deselect All", style: .plain, target: self, action: #selector(onSelectAll(_:)))
        tableView.reloadData()
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
            
            let playlistController = PlaylistViewController(tabManager: self.tabManager)
            self.present(playlistController, animated: true, completion: nil)
        }
    }
}

extension AddToPlaylistViewController: UITableViewDataSource {
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
        cell.detailLabel.text = String(format: "%.2f mins", item.duration / 60.0)
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

extension AddToPlaylistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        checkedItems[indexPath.row].toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        let countOfCheckedItems = checkedItems.filter({ $0 }).count
        footerButton.isHidden = countOfCheckedItems == 0
        footerButton.setTitle("Add \(countOfCheckedItems) Item(s) to Playlist", for: .normal)
    }
}

private class PlaylistSelectionCell: UITableViewCell {

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
    
    let checkedIcon = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = #imageLiteral(resourceName: "check").scale(toSize: CGSize(width: 20.0, height: 20.0)).template
        $0.transform = CGAffineTransform(rotationAngle: 10 * .pi / 180.0)
        $0.tintColor = .white
        $0.isHidden = true
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
        iconStackView.addArrangedSubview(thumbnailView)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)
        contentView.addSubview(checkedIcon)
        contentView.addSubview(separator)
        
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
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        checkedIcon.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(infoStackView.snp.right).offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.centerY.equalToSuperview()
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
