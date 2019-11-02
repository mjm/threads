//
//  EmptyView.swift
//  Threads
//
//  Created by Matt Moriarity on 9/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class EmptyView: UIView {
    private let stackView = UIStackView()

    let iconView = UIImageView()
    let textLabel = UILabel()

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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .systemGray2
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 60)

        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.textColor = .systemGray2

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(textLabel)
        addSubview(stackView)

        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 60),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(
                greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
