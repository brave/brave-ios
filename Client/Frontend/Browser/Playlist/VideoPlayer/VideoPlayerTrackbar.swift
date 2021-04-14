// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import AVKit

private class VideoSliderBar: UIControl {
    public var trackerInsets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
    public var value: CGFloat = 0.0 {
        didSet {
            trackerConstraint?.constant = boundaryView.bounds.size.width * value
            filledConstraint?.constant = value >= 1.0 ? bounds.size.width : ((bounds.size.width - (trackerInsets.left + trackerInsets.right)) * value) + trackerInsets.left
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tracker.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPanned(_:))))
        
        addSubview(background)
        addSubview(boundaryView)
        
        background.addSubview(filledView)
        boundaryView.addSubview(tracker)
        
        background.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        boundaryView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        filledView.snp.makeConstraints {
            $0.right.top.bottom.equalTo(background)
        }
        
        tracker.snp.makeConstraints {
            $0.centerY.equalTo(boundaryView.snp.centerY)
            $0.width.height.equalTo(18.0)
        }
        
        filledConstraint = filledView.leftAnchor.constraint(equalTo: background.leftAnchor).then {
            $0.isActive = true
        }
        
        trackerConstraint = tracker.centerXAnchor.constraint(equalTo: boundaryView.leftAnchor).then {
            $0.isActive = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.background.layer.cornerRadius = self.bounds.size.height / 2.0
        
        boundaryView.snp.remakeConstraints {
            $0.edges.equalToSuperview().inset(self.trackerInsets)
        }
        
        if self.filledConstraint?.constant ?? 0 < self.trackerInsets.left {
            self.filledConstraint?.constant = self.trackerInsets.left
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if tracker.bounds.size.width < 44.0 || tracker.bounds.size.height < 44.0 {
            let adjustedBounds = CGRect(x: tracker.center.x, y: tracker.center.y, width: 0.0, height: 0.0).inset(by: touchInsets)
            
            if adjustedBounds.contains(point) {
                return tracker
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if tracker.bounds.size.width < 44.0 || tracker.bounds.size.height < 44.0 {
            let adjustedBounds = CGRect(x: tracker.center.x, y: tracker.center.y, width: 0.0, height: 0.0).inset(by: touchInsets)
            
            if adjustedBounds.contains(point) {
                return true
            }
        }
        
        return super.point(inside: point, with: event)
    }
    
    @objc
    private func onPanned(_ recognizer: UIPanGestureRecognizer) {
        let offset = min(boundaryView.bounds.size.width, max(0.0, recognizer.location(in: boundaryView).x))
        
        value = offset / boundaryView.bounds.size.width
        
        sendActions(for: .valueChanged)
        
        if recognizer.state == .cancelled || recognizer.state == .ended {
            sendActions(for: .touchUpInside)
        }
    }
    
    private var filledConstraint: NSLayoutConstraint?
    private var trackerConstraint: NSLayoutConstraint?
    
    private let touchInsets = UIEdgeInsets(top: 44.0, left: 44.0, bottom: 44.0, right: 44.0)
    
    private var background = UIView().then {
        $0.backgroundColor = .white
        $0.clipsToBounds = true
    }
    
    private var filledView = UIView().then {
        $0.backgroundColor = .black
        $0.clipsToBounds = true
    }
    
    private var boundaryView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private var tracker = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
        $0.image = #imageLiteral(resourceName: "playlist_video_thumb")
    }
}

protocol VideoTrackerBarDelegate: class {
    func onValueChanged(_ trackBar: VideoTrackerBar, value: CGFloat)
    func onValueEnded(_ trackBar: VideoTrackerBar, value: CGFloat)
}

class VideoTrackerBar: UIView {
    public weak var delegate: VideoTrackerBarDelegate?
    
    private let slider = VideoSliderBar()
    
    private let currentTimeLabel = UILabel().then {
        $0.text = "0:00"
        $0.textColor = .white
        $0.appearanceTextColor = #colorLiteral(red: 0.5254901961, green: 0.5568627451, blue: 0.5882352941, alpha: 1)
        $0.font = .systemFont(ofSize: 14.0, weight: .medium)
    }
    
    private let endTimeLabel = UILabel().then {
        $0.text = "0:00"
        $0.textColor = .white
        $0.appearanceTextColor = #colorLiteral(red: 0.5254901961, green: 0.5568627451, blue: 0.5882352941, alpha: 1)
        $0.font = .systemFont(ofSize: 14.0, weight: .medium)
    }
    
    public func setTimeRange(currentTime: CMTime, endTime: CMTime) {
        if CMTimeCompare(endTime, .zero) != 0 && endTime.value > 0 {
            slider.value = CGFloat(currentTime.value) / CGFloat(endTime.value)
            
            currentTimeLabel.text = self.timeToString(currentTime)
            endTimeLabel.text = "-\(self.timeToString(endTime - currentTime))"
        } else {
            slider.value = 0.0
            currentTimeLabel.text = "0:00"
            endTimeLabel.text = "0:00"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        slider.addTarget(self, action: #selector(onValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(onValueEnded(_:)), for: .touchUpInside)
        
        addSubview(slider)
        addSubview(currentTimeLabel)
        addSubview(endTimeLabel)
        
        currentTimeLabel.snp.makeConstraints {
            $0.left.equalToSuperview().inset(10.0)
            $0.top.equalToSuperview().offset(2.0)
            $0.bottom.equalTo(slider.snp.top).offset(-10.0)
        }
        
        endTimeLabel.snp.makeConstraints {
            $0.right.equalToSuperview().inset(10.0)
            $0.top.equalToSuperview().offset(2.0)
            $0.bottom.equalTo(slider.snp.top).offset(-10.0)
        }
        
        slider.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(10.0)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(2.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onValueChanged(_ slider: VideoSliderBar) {
        self.delegate?.onValueChanged(self, value: slider.value)
    }
    
    @objc
    private func onValueEnded(_ slider: VideoSliderBar) {
        self.delegate?.onValueEnded(self, value: slider.value)
    }
    
    private func timeToString(_ time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let minutes = floor(totalSeconds.truncatingRemainder(dividingBy: 3600.0) / 60.0)
        let seconds = floor(totalSeconds.truncatingRemainder(dividingBy: 60.0))
        return String(format: "%02zu:%02zu", Int(minutes), Int(seconds))
    }
}
