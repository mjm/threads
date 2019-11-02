//
//  SeparatorView.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
let separatorHeight: CGFloat = 1.0
#else
let separatorHeight: CGFloat = 0.5
#endif

@IBDesignable
class SeparatorView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .separator

        heightAnchor.constraint(equalToConstant: separatorHeight).isActive = true
    }
}
