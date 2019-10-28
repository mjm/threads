//
//  RoundedShadowImageView.swift
//  Threads
//
//  Created by Matt Moriarity on 9/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowImageView: RoundedShadowView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear

        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: imageView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    }
}
