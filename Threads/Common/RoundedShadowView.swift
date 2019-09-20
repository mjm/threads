//
//  RoundedShadowView.swift
//  Threads
//
//  Created by Matt Moriarity on 9/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowView: UIView {
    let contentView = UIView()

    @IBInspectable
    var cornerRadius: CGFloat = 10 {
        didSet {
            contentView.layer.cornerRadius = cornerRadius
            layer.cornerRadius = cornerRadius
            layer.setNeedsLayout()
        }
    }

    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }

    @IBInspectable
    var shadowOpacity: Float {
        get {
            layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }

    @IBInspectable
    var shadowOffset: CGSize {
        get {
            layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerCurve = .continuous

        clipsToBounds = false
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.shadowColor = shadowColor

        addSubview(contentView)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        layer.shadowPath = UIBezierPath(roundedRect: layer.bounds,
                                        cornerRadius: cornerRadius).cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        layer.shadowColor = shadowColor
    }

    private var shadowColor: CGColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.systemGray3.cgColor
            : UIColor.systemGray.cgColor
    }
}
