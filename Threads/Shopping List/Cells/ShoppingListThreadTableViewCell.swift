//
//  ShoppingListThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class ShoppingListThreadTableViewCell: ThreadTableViewCell<ShoppingListCellViewModel> {
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    private var model: ShoppingListCellViewModel?

    override func bind(_ model: ShoppingListCellViewModel) {
        bindCommonProperties(model)
        self.model = model

        model.amountText.assign(to: \.text, on: quantityLabel).store(in: &cancellables)

        model.willRemoveOnDecrement
            .map { $0 ? "trash" : "minus.square" }
            .map { UIImage(systemName: $0) }
            .sink { [decreaseButton] image in
                decreaseButton?.setImage(image, for: .normal)
            }.store(in: &cancellables)

        model.isPurchased.map { $0 ? "checkmark.square" : "square" }
            .map { UIImage(systemName: $0) }
            .sink { [checkButton] image in
                checkButton?.setImage(image, for: .normal)
            }.store(in: &cancellables)

        let isNotPurchased = model.isPurchased.map { !$0 }
        isNotPurchased.assign(to: \.isEnabled, on: decreaseButton).store(in: &cancellables)
        isNotPurchased.assign(to: \.isEnabled, on: increaseButton).store(in: &cancellables)

        model.isPurchased.map { $0 ? UIColor.secondarySystemBackground : UIColor.systemBackground }
            .assignWeakly(to: \.backgroundColor, on: self)
            .store(in: &cancellables)

        let purchasedSelected = model.isPurchased.combineLatest(selectedOrHighlighted)

        let labelColor = purchasedSelected.map { purchased, selected -> UIColor in
            if selected {
                return .lightText
            } else if purchased {
                return .secondaryLabel
            } else {
                return .label
            }
        }
        numberColorSubscription = labelColor.assign(to: \.textColor, on: numberLabel)
        labelColorSubscription = labelColor.assign(to: \.textColor, on: labelLabel)
        labelColor.assign(to: \.textColor, on: quantityLabel).store(in: &cancellables)

        let buttonTintColor = purchasedSelected.map { purchased, selected -> UIColor? in
            if selected {
                return .lightText
            } else if purchased {
                return .secondaryLabel
            } else {
                return nil
            }
        }
        buttonTintColor.assign(to: \.tintColor, on: checkButton).store(in: &cancellables)
        buttonTintColor.assign(to: \.tintColor, on: decreaseButton).store(in: &cancellables)
        buttonTintColor.assign(to: \.tintColor, on: increaseButton).store(in: &cancellables)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        model = nil
    }

    @IBAction func checkButtonPressed() {
        model?.togglePurchasedAction().perform()
    }

    @IBAction func increaseQuantity() {
        model?.increaseQuantityAction.perform()
    }

    @IBAction func decreaseQuantity() {
        model?.decreaseQuantityAction.perform()
    }
}
