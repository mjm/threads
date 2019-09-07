//
//  ShoppingListThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ShoppingListThreadTableViewCell: UITableViewCell {
    
    @IBOutlet var smallColorStackView: UIStackView!
    @IBOutlet var smallColorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var checkButton: UIButton!

    func populate(_ thread: Thread) {
        backgroundColor = UIColor.systemBackground

        smallColorView.color = thread.color ?? .systemBackground

        if let number = thread.number {
            numberLabel.text = "DMC \(number)"
        } else {
            numberLabel.text = ""
        }
        labelLabel.text = thread.label ?? ""
        
        numberLabel.textColor = UIColor.label
        labelLabel.textColor = UIColor.label

        if thread.amountInShoppingList > 0 {
            let amount = thread.amountInShoppingList
            // TODO show quantity
        }
    }

    var isChecked = false

    @IBAction func checkButtonPressed() {
        // TODO add a delegate or block or something to handle this
        isChecked = !isChecked
        checkButton.setImage(UIImage(systemName: isChecked ? "checkmark.circle.fill" : "circle"), for: .normal)
        checkButton.tintColor = isChecked ? UIColor.systemBlue : UIColor.systemGray2
    }
    
    static var nib = UINib(nibName: "ShoppingListThreadTableViewCell", bundle: nil)
}
