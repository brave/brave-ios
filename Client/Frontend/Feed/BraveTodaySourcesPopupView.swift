// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import Kingfisher

class BraveTodaySourcesPopupView: PopupView {
    fileprivate var titleLabel: UILabel!
    fileprivate var messageTextView: UITextView!
    fileprivate var tableView = UITableView(frame: .zero, style: .plain)
    fileprivate var containerView: UIView!
    fileprivate let kPadding: CGFloat = 12.0
    fileprivate var maxHeight = UIScreen.main.bounds.height
    
    fileprivate var publishers: [PublisherItem] = []
    
    var completionHandler: ((Bool) -> Void)?
    
    init(completed: ((Bool) -> Void)? = nil) {
        super.init(frame: CGRect.zero)
        
        if completed != nil {
            completionHandler = completed
        }
        
        containerView = UIView(frame: CGRect.zero)
        containerView.autoresizingMask = [.flexibleWidth]
        
        titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.text = "Choose your sources."
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        messageTextView = UITextView(frame: CGRect.zero)
        messageTextView.textColor = UIColor.white.withAlphaComponent(0.8)
        messageTextView.textAlignment = .center
        messageTextView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        messageTextView.text = "Customize what you see in Brave Today by selecting your sources below."
        messageTextView.isEditable = false
        messageTextView.showsVerticalScrollIndicator = true
        messageTextView.showsHorizontalScrollIndicator = false
        messageTextView.isScrollEnabled = true
        messageTextView.alwaysBounceVertical = true
        messageTextView.backgroundColor = .clear
        containerView.addSubview(messageTextView)
        
        tableView.bounces = true
        tableView.register(PubSourceCell.self, forCellReuseIdentifier: "PubSourceCell")
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.accessibilityIdentifier = "Pubs"
        tableView.estimatedRowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        tableView.layer.borderWidth = 1
        tableView.layer.cornerRadius = 8
        tableView.layer.masksToBounds = true
        tableView.dataSource = self
        tableView.delegate = self
        containerView.addSubview(tableView)
        
        updateSubviews()
        
        overlayDismisses = true
        defaultShowType = .normal
        defaultDismissType = .noAnimation
        presentsOverWindow = true
        
        setStyle(popupStyle: .dialog)
        setDialogColor(color: UIColor.black.withAlphaComponent(0.4))
        setOverlayColor(color: UIColor(rgb: 0x353535).withAlphaComponent(0.8), animate: false)
        
        if #available(iOS 13.0, *) {
            dialogView.effect = UIBlurEffect(style: .systemThinMaterialDark)
        } else {
            dialogView.effect = UIBlurEffect(style: .dark)
        }
        
        setPopupContentView(view: containerView)
        
        addButton(title: "Done", type: .primary, fontSize: 16) { () -> PopupViewDismissType in
            self.completionHandler?(true)
            return .flyDown
        }
    }
    
    func updateSubviews() {
        let width: CGFloat = dialogWidth
        
        let titleLabelSize: CGSize = titleLabel.sizeThatFits(CGSize(width: width - kPadding * 3.0, height: CGFloat.greatestFiniteMagnitude))
        var titleLabelFrame: CGRect = titleLabel.frame
        titleLabelFrame.size = titleLabelSize
        titleLabelFrame.origin.x = rint((width - titleLabelSize.width) / 2.0)
        titleLabelFrame.origin.y = kPadding * 2
        titleLabel.frame = titleLabelFrame
        
        let messageTextViewSize: CGSize = messageTextView.sizeThatFits(CGSize(width: width - kPadding * 4.0, height: CGFloat.greatestFiniteMagnitude))
        var messageTextViewFrame: CGRect = messageTextView.frame
        messageTextViewFrame.size = messageTextViewSize
        messageTextViewFrame.origin.x = rint((width - messageTextViewSize.width) / 2.0)
        messageTextViewFrame.origin.y = rint(titleLabelFrame.maxY)
        messageTextView.frame = messageTextViewFrame
        
        var tableViewFrame: CGRect = tableView.frame
        tableViewFrame.size.width = width - kPadding * 2.0
        tableViewFrame.size.height = min(UIScreen.main.bounds.height - 230, 390)
        tableViewFrame.origin.x = kPadding
        tableViewFrame.origin.y = rint(messageTextViewFrame.maxY + kPadding)
        tableView.frame = tableViewFrame
        
        var containerViewFrame: CGRect = containerView.frame
        containerViewFrame.size.width = width
        containerViewFrame.size.height = tableViewFrame.maxY + kPadding * 1.5
        containerView.frame = containerViewFrame
        
        getPublishers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maxHeight = UIScreen.main.bounds.height
        updateSubviews()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getPublishers() {
        if let publishers = FeedManager.shared.db?.getAvailablePublisherRecords().value.successValue {
            self.publishers = publishers
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension BraveTodaySourcesPopupView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publishers.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PubSourceCell", for: indexPath) as UITableViewCell
        let data = publishers[indexPath.row]
        (cell as? PubSourceCell)?.setData(data: data)
        (cell as? PubSourceCell)?.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}

extension BraveTodaySourcesPopupView: PubSourceCellDelegate {
    func boolRow(data: PublisherItem, value: Bool) {
        if let index = publishers.firstIndex(where: { $0.publisherId == data.publisherId }) {
            publishers[index] = PublisherItem(id: data.id, publisherId: data.publisherId, publisherName: data.publisherName, publisherLogo: data.publisherLogo, show: value)
        }
        
        FeedManager.shared.db?.updatePublisherRecord(data.id, show: value)
    }
}

protocol PubSourceCellDelegate {
    func boolRow(data: PublisherItem, value: Bool)
}

class PubSourceCell: UITableViewCell {
    var data: PublisherItem?
    var delegate: PubSourceCellDelegate?
    
    var nameLabel: UILabel?
    var logo: UIImageView?
    var boolSwitch: UISwitch = UISwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(nameLabel)
        
        self.nameLabel = nameLabel
        self.nameLabel?.snp.makeConstraints {
            $0.top.bottom.equalTo(0)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        let logo = UIImageView()
        logo.contentMode = .scaleAspectFit
        contentView.addSubview(logo)
        
        self.logo = logo
        self.logo?.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(20)
            $0.size.equalTo(CGSize(width: 173, height: 20))
        }
        
        boolSwitch.tintColor = .white
        accessoryView = boolSwitch
        
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {

        } else {

        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {

        } else {

        }
    }
    
    func setData(data: PublisherItem) {
        self.data = data
        boolSwitch.removeTarget(self, action: #selector(boolChanged), for: .valueChanged)
        
        boolSwitch.setOn(data.show, animated: false)
        
        boolSwitch.addTarget(self, action: #selector(boolChanged), for: .valueChanged)
        
//        if data.publisherLogo.isEmpty == false, let logo = self.logo {
//            logo.isHidden = false
//            nameLabel?.isHidden = true
//
//            loadImage(urlString: data.publisherLogo, imageView: logo) { [weak self] success in
//                if success == false {
//                    self?.nameLabel?.text = data.publisherName
//                    self?.logo?.isHidden = true
//                    self?.nameLabel?.isHidden = false
//                }
//            }
//        } else {
            nameLabel?.text = data.publisherName
            logo?.isHidden = true
            nameLabel?.isHidden = false
//        }
    }
    
    @objc func boolChanged() {
        guard let data = data else { return }
        delegate?.boolRow(data: data, value: boolSwitch.isOn)
    }
    
    // TODO: move to media loader
    private func loadImage(urlString: String, imageView: UIImageView, completed: @escaping (Bool) -> Void) {
        guard urlString.isEmpty == false else { return }
        
        let url = URL(string: urlString)
        
        if url?.pathExtension == "gif" {
            imageView.image = UIImage.gifImageWithURL(urlString)
        } else {
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                switch result {
                case .success(let value):
                    print("Task done for: \(value.source.url?.absoluteString ?? "")")
                    completed(true)
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
                    completed(false)
                }
            }
        }
    }
}
