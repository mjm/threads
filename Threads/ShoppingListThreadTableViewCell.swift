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

    override func populate(_ thread: Thread) {
        super.populate(thread)

        if thread.amountInShoppingList > 0 {
            let amount = thread.amountInShoppingList
            quantityLabel.text = "\(amount)"
        }
    }

    var isChecked = false

    @IBAction func checkButtonPressed() {
        // TODO add a delegate or block or something to handle this
        isChecked = !isChecked
        checkButton.setImage(UIImage(systemName: isChecked ? "checkmark.circle.fill" : "circle"), for: .normal)
    }
    
    static var nib = UINib(nibName: "ShoppingListThreadTableViewCell", bundle: nil)
}
