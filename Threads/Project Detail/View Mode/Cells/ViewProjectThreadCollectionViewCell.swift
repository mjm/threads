//
//  ProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ViewProjectThreadCollectionViewCell: ProjectThreadCollectionViewCell {
    @IBOutlet var separatorLeadingConstraint: NSLayoutConstraint!

    func bind(_ model: ViewProjectThreadCellViewModel) {
        bindCommonProperties(model)

        model.isNeeded.map {
            $0 ? UIColor.systemBackground : UIColor.secondarySystemGroupedBackground
        }
            .assign(to: \.backgroundColor, on: self, weak: true)
            .store(in: &cancellables)

        let labelColor = model.isNeeded.map { $0 ? UIColor.label : UIColor.secondaryLabel }
        labelColor.assign(to: \.textColor, on: numberLabel).store(in: &cancellables)
        labelColor.assign(to: \.textColor, on: labelLabel).store(in: &cancellables)
        labelColor.assign(to: \.textColor, on: quantityLabel).store(in: &cancellables)

        model.$isLastItem.map { $0 ? 0 : 15 }
            .assign(to: \.constant, on: separatorLeadingConstraint)
            .store(in: &cancellables)
    }
}
