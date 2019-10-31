//
//  CollectionThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class CollectionThreadTableViewCell: ThreadTableViewCell<CollectionThreadCellViewModel> {
    @IBOutlet var statusLabel: UILabel!

    override func bind(_ model: CollectionThreadCellViewModel) {
        bindCommonProperties(model)

        model.status.map { $0 == nil }
            .assign(to: \.isHidden, on: statusLabel)
            .store(in: &cancellables)

        model.status.map { $0?.labelText }
            .assign(to: \.text, on: statusLabel)
            .store(in: &cancellables)

        model.isOutOfStock.map { $0 ? UIColor.secondarySystemBackground : UIColor.systemBackground }
            .assign(to: \.backgroundColor, on: self)
            .store(in: &cancellables)

        selectedOrHighlighted.map { $0 ? UIColor.lightText : UIColor.secondaryLabel }
            .assign(to: \.textColor, on: statusLabel)
            .store(in: &cancellables)

        let labelColor = model.isOutOfStock.combineLatest(selectedOrHighlighted) {
            outOfStock, selected -> UIColor in
            if selected {
                return .lightText
            } else if outOfStock {
                return .secondaryLabel
            } else {
                return .label
            }
        }
        numberColorSubscription = labelColor.assign(to: \.textColor, on: numberLabel)
        labelColorSubscription = labelColor.assign(to: \.textColor, on: labelLabel)
    }
}

extension CollectionThreadCellViewModel.Status {
    var labelText: String {
        switch self {
        case .onBobbin:
            return Localized.onBobbin
        case .outOfStock:
            return Localized.outOfStock
        }
    }
}
