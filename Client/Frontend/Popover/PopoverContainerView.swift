//
//  PopoverContainerView.swift
//  Brave
//
//  Created by Kyle Hickinson on 2018-05-22.
//  Copyright © 2018 Kyle Hickinson. All rights reserved.
//

import Foundation
import UIKit

extension PopoverController {
    
    struct PopoverUX {
        static let backgroundColor: UIColor = .white
        static let arrowSize = CGSize(width: 14.0, height: 8.0)
        static let cornerRadius: CGFloat = 10.0
        static let shadowOffset = CGSize(width: 0, height: 2.0)
        static let shadowRadius: CGFloat = 3.0
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.3
    }
    
    /// The direction the arrow faces
    enum ArrowDirection {
        /// The arrow faces upwards like: ▴
        case up
        /// The arrow faces downwards like: ▾
        case down
    }
    
    /// The internal view loaded by PopoverController. Applies default styling as well as sets up the arrow
    class ContainerView: UIView {
        
        /// The arrow direction for this view
        var arrowDirection: ArrowDirection = .up {
            didSet {
                updateTrianglePath()
                setNeedsLayout()
                setNeedsUpdateConstraints()
                updateConstraintsIfNeeded()
            }
        }
        
        /// Where to display the arrow on the popover
        var arrowOrigin = CGPoint.zero {
            didSet {
                setNeedsLayout()
                setNeedsUpdateConstraints()
                updateConstraintsIfNeeded()
            }
        }
        
        /// The view where you will place the content controller's view
        let contentView = UIView()
        
        /// The actual white background view with the arrow. We have two separate views to ensure content placed within
        /// the popover are clipped at the corners
        private let backgroundView = UIView()
        
        private let triangleLayer = CAShapeLayer()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .clear
            
            triangleLayer.fillColor = PopoverUX.backgroundColor.cgColor
            triangleLayer.shadowColor = PopoverUX.shadowColor.cgColor
            triangleLayer.shadowOffset = PopoverUX.shadowOffset
            triangleLayer.shadowRadius = PopoverUX.shadowRadius
            triangleLayer.shadowOpacity = PopoverUX.shadowOpacity
            
            contentView.backgroundColor = PopoverUX.backgroundColor
            contentView.layer.cornerRadius = PopoverUX.cornerRadius
            contentView.clipsToBounds = true
            contentView.translatesAutoresizingMaskIntoConstraints = false
            
            backgroundView.backgroundColor = PopoverUX.backgroundColor
            backgroundView.layer.cornerRadius = PopoverUX.cornerRadius
            backgroundView.layer.shadowColor = PopoverUX.shadowColor.cgColor
            backgroundView.layer.shadowOffset = PopoverUX.shadowOffset
            backgroundView.layer.shadowRadius = PopoverUX.shadowRadius
            backgroundView.layer.shadowOpacity = PopoverUX.shadowOpacity
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(backgroundView)
            addSubview(contentView)
            layer.addSublayer(triangleLayer)
            
            updateTrianglePath()
            
            let backgroundViewTopConstraint = backgroundView.topAnchor.constraint(equalTo: topAnchor)
            let backgroundViewBottomConstraint = backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
            
            NSLayoutConstraint.activate([
                backgroundView.leftAnchor.constraint(equalTo: leftAnchor),
                backgroundView.rightAnchor.constraint(equalTo: rightAnchor),
                backgroundViewTopConstraint,
                backgroundViewBottomConstraint,
                
                contentView.leftAnchor.constraint(equalTo: leftAnchor),
                contentView.rightAnchor.constraint(equalTo: rightAnchor),
                contentView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
            ])
            
            self.backgroundViewTopConstraint = backgroundViewTopConstraint
            self.backgroundViewBottomConstraint = backgroundViewBottomConstraint
            
            setNeedsUpdateConstraints()
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            // Assure the arrow will not be hanging off a corner
            let clampedArrowXOrigin = min(max(arrowOrigin.x, PopoverUX.cornerRadius), bounds.width - PopoverUX.cornerRadius - PopoverUX.arrowSize.width / 2.0) - PopoverUX.arrowSize.width / 2.0
            
            var contentRect = bounds
            contentRect.size.height -= PopoverUX.arrowSize.height
            
            CATransaction.setDisableActions(true)
            switch arrowDirection {
            case .down:
                triangleLayer.position = CGPoint(x: clampedArrowXOrigin, y: contentRect.size.height - 1.0)
            case .up:
                triangleLayer.position = CGPoint(x: clampedArrowXOrigin, y: 1.0)
            }
            CATransaction.setDisableActions(false)
            
            backgroundView.layer.shadowPath = UIBezierPath(roundedRect: backgroundView.bounds, cornerRadius: PopoverUX.cornerRadius).cgPath
        }
        
        private var backgroundViewTopConstraint: NSLayoutConstraint?
        private var backgroundViewBottomConstraint: NSLayoutConstraint?
        
        override func updateConstraints() {
            super.updateConstraints()
            
            switch arrowDirection {
            case .down:
                backgroundViewTopConstraint?.constant = 0.0
                backgroundViewBottomConstraint?.constant = -PopoverUX.arrowSize.height
                
            case .up:
                backgroundViewTopConstraint?.constant = PopoverUX.arrowSize.height
                backgroundViewBottomConstraint?.constant = 0.0
            }
        }
        
        private func updateTrianglePath() {
            let arrowSize = PopoverUX.arrowSize
            
            // Also have to apply a mask to the triangle so that the shadow doesn't appear on top of the content
            let shadowMask = CALayer()
            shadowMask.backgroundColor = UIColor.black.cgColor
            
            let path = UIBezierPath()
            switch arrowDirection {
            case .up:
                path.move(to: CGPoint(x: arrowSize.width / 2.0, y: 0.0))
                path.addLine(to: CGPoint(x: arrowSize.width, y: arrowSize.height))
                path.addLine(to: CGPoint(x: 0, y: arrowSize.height))
                
                shadowMask.frame = CGRect(x: -PopoverUX.shadowRadius, y: -PopoverUX.shadowRadius + PopoverUX.shadowOffset.height, width: PopoverUX.arrowSize.width + (PopoverUX.shadowRadius * 2.0), height: PopoverUX.arrowSize.height + 1.0)
            case .down:
                path.move(to: CGPoint(x: arrowSize.width / 2.0, y: arrowSize.height))
                path.addLine(to: CGPoint(x: arrowSize.width, y: 0.0))
                path.addLine(to: CGPoint(x: 0, y: 0.0))
                
                shadowMask.frame = CGRect(x: -PopoverUX.shadowRadius, y: 0, width: PopoverUX.arrowSize.width + (PopoverUX.shadowRadius * 2.0), height: PopoverUX.arrowSize.height + PopoverUX.shadowRadius + PopoverUX.shadowOffset.height)
            }
            path.close()
            
            triangleLayer.path = path.cgPath
            triangleLayer.mask = shadowMask
        }
    }
}
