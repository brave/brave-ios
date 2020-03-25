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
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var playlistItems = [PlaylistInfo]()
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: "PlaylistCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints({
            $0.edges.equalTo(view.safeArea.edges)
        })
        
        tabManager.tabsForCurrentMode.forEach({
            $0.playlistItems.observe { [weak self] _, _ in
                guard let self = self else { return }
                self.updateItems()
            }.bind(to: self)
        })
    }
    
    private func updateItems() {
        playlistItems = tabManager.tabsForCurrentMode.map({ $0.playlistItems }).flatMap({ $0.value })
    }
    
    var player: AVPlayer?
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        cell.titleLabel.text = playlistItems[indexPath.row].name
        cell.playButton.setTitle("Play", for: .normal)
        cell.playButton.tag = indexPath.row
        cell.playButton.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc
    private func onPlay(_ button: UIButton) {
        let item = self.playlistItems[button.tag]
        let player = AVPlayer(url: URL(string: item.src)!)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            let controller = AVPlayerViewController()
            controller.player = player
            present(controller, animated: true) {
                player.play()
            }
            
//            self.player = player
//            player.play()
        } catch {
            print(error)
        }
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}

private class PlaylistCell: UITableViewCell {
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
    }
    
    let titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
    let playButton = UIButton().then {
        $0.setTitleColor(.blue, for: .normal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(playButton)
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints({
            $0.edges.equalTo(contentView.snp.edges).inset(15.0)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
