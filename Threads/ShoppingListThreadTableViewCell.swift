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

    var onDecreaseQuantity: () -> Void = { }
    var onIncreaseQuantity: () -> Void = { }
    var onCheckTapped: () -> Void = { }

    override func populate(_ thread: Thread) {
        super.populate(thread)

        let amount = thread.amountInShoppingList
        quantityLabel.text = "\(amount)"

        if amount == 1 {
            decreaseButton.setImage(UIImage(systemName: "trash"), for: .normal)
        } else {
            decreaseButton.setImage(UIImage(systemName: "minus.square"), for: .normal)
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
