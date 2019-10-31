//
//  ThreadDetailsTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class ThreadDetailsTableViewCell: ReactiveTableViewCell {
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var statusStackView: UIStackView!
    @IBOutlet var onBobbinStackView: UIStackView!
    @IBOutlet var onBobbinImageView: UIImageView!
    @IBOutlet var onBobbinLabel: UILabel!
    @IBOutlet var outOfStockStackView: UIStackView!
    @IBOutlet var outOfStockImageView: UIImageView!
    @IBOutlet var outOfStockLabel: UILabel!

    func bind(_ model: ThreadDetailCellViewModel) {
        model.label.assign(to: \.text, on: labelLabel).store(in: &cancellables)

        let background = model.color.map { c -> UIColor? in c ?? .systemBackground }
        background.assign(to: \.backgroundColor, on: self).store(in: &cancellables)

        let foreground = background.map { $0?.labelColor }
        foreground.assign(to: \.textColor, on: labelLabel).store(in: &cancellables)

        model.onBobbin.invert().assign(to: \.isHidden, on: onBobbinStackView).store(in: &cancellables)
        foreground.assign(to: \.tintColor, on: onBobbinImageView).store(in: &cancellables)
        foreground.assign(to: \.textColor, on: onBobbinLabel).store(in: &cancellables)

        model.outOfStock.invert().assign(to: \.isHidden, on: outOfStockStackView).store(in: &cancellables)
        foreground.assign(to: \.tintColor, on: outOfStockImageView).store(in: &cancellables)
        foreground.assign(to: \.textColor, on: outOfStockLabel).store(in: &cancellables)

        model.hasStatus.invert().assign(to: \.isHidden, on: statusStackView).store(in: &cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // hide top separator for this one
        for view in subviews {
            if view != contentView && view.frame.origin.y == 0.0 {
                view.isHidden = true
            }
        }
    }
}
