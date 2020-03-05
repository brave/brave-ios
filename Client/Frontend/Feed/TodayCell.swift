// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class TodayCell: UITableViewCell {
    var data: FeedRow?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
                    
        prepare()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    private func prepare() {
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
        prepare()
        
        self.data = data
        
        if data.cards.count == 1, let card = data.cards.first {
            contentView.subviews.forEach { $0.removeFromSuperview() }
            
            let cardView = TodayCardView()
            contentView.addSubview(cardView)
            
            cardView.snp.makeConstraints {
                $0.left.right.equalTo(contentView).inset(20)
                $0.top.equalTo(10)
                $0.bottom.equalTo(0)
                $0.height.equalTo(card.type.rawValue)
            }
        }
    }
}
