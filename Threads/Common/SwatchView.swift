//
//  SwatchView.swift
//  Threads
//
//  Created by Matt Moriarity on 9/4/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class SwatchView: RoundedShadowView {
    @IBInspectable
    var color: UIColor = .systemBackground {
        didSet {
            contentView.backgroundColor = color
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
        // I think it's probably clear why we don't want thread swatches to be inverted
        accessibilityIgnoresInvertColors = true
        contentView.accessibilityIgnoresInvertColors = true

        contentView.backgroundColor = color

        shadowOffset = CGSize(width: 0, height: 0)
        shadowRadius = 3
        shadowOpacity = 0.8
    }
}
