// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

protocol FeedCellDelegate {
    func shouldRemoveContent(id: Int)
    func shouldRemovePublisherContent(publisherId: String)
}

class FeedCell: UITableViewCell {
    var data: FeedRow?
    var delegate: FeedCellDelegate?
    let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints {
            $0.width.equalTo(contentView).inset(20).priority(999)
            $0.width.lessThanOrEqualTo(460).priority(.required)
            $0.centerX.equalToSuperview()
            $0.top.bottom.equalTo(0)
        }
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
    
    func setData(data: FeedRow) {
        self.data = data
        
        // clear containers
        // TODO: cache these using reuesable ids on table for each card type
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Only two possible cases
        // 1 card takes up entire width
        // 2 two cards side-by-side
        if data.cards.count == 1, let card = data.cards.first {
            let cardView = FeedCardView(data: card)
            cardView.delegate = self
            containerView.addSubview(cardView)
            
            cardView.snp.makeConstraints {
                $0.left.right.equalTo(containerView)
                $0.top.equalTo(10)
                $0.bottom.equalTo(0)
                $0.height.equalTo(card.type.rawValue)
            }
        } else {
            let card1 = data.cards[0]
            let cardView1 = FeedCardView(data: card1)
            cardView1.delegate = self
            containerView.addSubview(cardView1)
            
            cardView1.snp.makeConstraints {
                $0.left.equalTo(containerView)
                $0.width.equalTo(containerView).multipliedBy(0.5).inset(2.5).priority(999)
                $0.top.equalTo(10)
                $0.bottom.equalTo(0)
                $0.height.equalTo(card1.type.rawValue)
            }
            
            let card2 = data.cards[1]
            let cardView2 = FeedCardView(data: card2)
            cardView2.delegate = self
            containerView.addSubview(cardView2)
            
            cardView2.snp.makeConstraints {
                $0.right.equalTo(containerView)
                $0.width.equalTo(containerView).multipliedBy(0.5).inset(2.5).priority(999)
                $0.top.equalTo(10)
                $0.bottom.equalTo(0)
                $0.height.equalTo(card2.type.rawValue)
            }
        }
    }
}

extension FeedCell: FeedCardViewDelegate {
    func shouldRemoveContent(id: Int) {
        delegate?.shouldRemoveContent(id: id)
        
        guard let data = data else { return }
        
        if let index = findCardWithId(cardNumber: 0, id: id) {
            // Remove from card 1 item, grab new, rebuild cell
            if let newItem = FeedManager.shared.getOne() {
                data.cards[0].items[index] = newItem
            }
        } else if let index = findCardWithId(cardNumber: 1, id: id) {
            // Remove card 2 item, grab new, rebuild cell
            if let newItem = FeedManager.shared.getOne() {
                data.cards[1].items[index] = newItem
            }
        }
        
        setData(data: data)
    }
    
    func shouldRemovePublisherContent(publisherId: String) {
        delegate?.shouldRemovePublisherContent(publisherId: publisherId)
    }
    
    func findCardWithId(cardNumber: Int, id: Int) -> Int? {
        guard let data = data, data.cards.count-1 >= cardNumber else { return nil }
        
        let card = data.cards[cardNumber].items
        for (index, value) in card.enumerated() {
            if id == value.id {
                return index
            }
        }
        return nil
    }
}
