//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    enum Mode: String {
        case collection = "Collection"
        case shoppingList = "ShoppingList"
    }
    
    var mode: Mode = .collection
    
    @IBOutlet var colorStackView: UIStackView!
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var smallColorStackView: UIStackView!
    @IBOutlet var smallColorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var checkButton: UIButton!

    func populate(_ thread: Thread) {
        backgroundColor = UIColor.systemBackground

        colorView.color = thread.color ?? .systemBackground
        smallColorView.color = thread.color ?? .systemBackground

        smallColorStackView.isHidden = mode == .collection
        colorStackView.isHidden = mode != .collection

        checkButton.isHidden = mode == .collection
        
        if let number = thread.number {
            numberLabel.text = "DMC \(number)"
        } else {
            numberLabel.text = ""
        }
        labelLabel.text = thread.label ?? ""
        
        numberLabel.textColor = UIColor.label
        labelLabel.textColor = UIColor.label

        statusLabel.isHidden = true
        
        if mode == .collection && thread.inCollection {
            if thread.onBobbin {
                statusLabel.isHidden = false
                statusLabel.text = "On Bobbin"
            } else if thread.amountInCollection == 0 {
                statusLabel.isHidden = false
                statusLabel.text = "Out of Stock"
                
                numberLabel.textColor = UIColor.secondaryLabel
                labelLabel.textColor = UIColor.secondaryLabel
                
                backgroundColor = UIColor.secondarySystemBackground
            }
        }
        
        if mode == .shoppingList && thread.amountInShoppingList > 0 {
            let amount = thread.amountInShoppingList
            statusLabel.isHidden = false
            statusLabel.text = "\(amount) Skein\(amount == 1 ? "" : "s")"
        }
    }

    var isChecked = false

    @IBAction func checkButtonPressed() {
        // TODO add a delegate or block or something to handle this
        isChecked = !isChecked
        checkButton.setImage(UIImage(systemName: isChecked ? "checkmark.circle.fill" : "circle"), for: .normal)
        checkButton.tintColor = isChecked ? UIColor.systemBlue : UIColor.systemGray2
    }
    
    static var nib = UINib(nibName: "ThreadTableViewCell", bundle: nil)
}
