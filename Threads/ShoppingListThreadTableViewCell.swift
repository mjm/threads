//
//  ShoppingListThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ShoppingListThreadTableViewCell: ThreadTableViewCell {

    @IBOutlet var checkButton: UIButton!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    var onDecreaseQuantity: () -> Void = { }
    var onIncreaseQuantity: () -> Void = { }
    var onCheckTapped: () -> Void = { }

    override func populate(_ thread: Thread) {
        super.populate(thread)

        backgroundColor = .systemBackground

        let amount = thread.amountInShoppingList
        quantityLabel.text = "\(amount)"
        quantityLabel.textColor = .label

        decreaseButton.setImage(UIImage(systemName: amount == 1 ? "trash" : "minus.square"), for: .normal)
        checkButton.setImage(UIImage(systemName: thread.purchased ? "checkmark.square" : "square"), for: .normal)
        let buttonTintColor = thread.purchased ? UIColor.secondaryLabel : nil
        checkButton.tintColor = buttonTintColor
        decreaseButton.tintColor = buttonTintColor
        increaseButton.tintColor = buttonTintColor

        decreaseButton.isEnabled = !thread.purchased
        increaseButton.isEnabled = !thread.purchased

        if thread.purchased {
            numberLabel.textColor = .secondaryLabel
            labelLabel.textColor = .secondaryLabel
            quantityLabel.textColor = .secondaryLabel
            backgroundColor = .secondarySystemBackground
        }
    }

    var isChecked = false

    @IBAction func checkButtonPressed() {
        onCheckTapped()
    }

    @IBAction func increaseQuantity() {
        onIncreaseQuantity()
    }

    @IBAction func decreaseQuantity() {
        onDecreaseQuantity()
    }
    
    static var nib = UINib(nibName: "ShoppingListThreadTableViewCell", bundle: nil)
}
