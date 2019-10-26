//
//  ShoppingListThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import Combine

class ShoppingListThreadTableViewCell: ThreadTableViewCell {
    enum Action {
        case purchase
        case increment
        case decrement
    }

    @IBOutlet var checkButton: UIButton!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!
    
    private let onAction = PassthroughSubject<Action, Never>()
    
    var isPurchased = false

    override func populate(_ thread: Thread) {
        isPurchased = thread.purchased
        super.populate(thread)

        let amount = thread.amountInShoppingList
        quantityLabel.text = "\(amount)"

        decreaseButton.setImage(UIImage(systemName: amount == 1 ? "trash" : "minus.square"), for: .normal)
        checkButton.setImage(UIImage(systemName: thread.purchased ? "checkmark.square" : "square"), for: .normal)

        decreaseButton.isEnabled = !thread.purchased
        increaseButton.isEnabled = !thread.purchased
    }
    
    override func updateColors(selected: Bool) {
        super.updateColors(selected: selected)
        
        backgroundColor = isPurchased ? .secondarySystemBackground : .systemBackground
        let labelColor: UIColor = selected ? .lightText : (isPurchased ? .secondaryLabel : .label)
        numberLabel.textColor = labelColor
        labelLabel.textColor = labelColor
        quantityLabel.textColor = labelColor
        
        let buttonTintColor: UIColor? = selected ? .lightText : (isPurchased ? .secondaryLabel : nil)
        checkButton.tintColor = buttonTintColor
        decreaseButton.tintColor = buttonTintColor
        increaseButton.tintColor = buttonTintColor
    }
    
    func actionPublisher() -> AnyPublisher<Action, Never> {
        onAction.eraseToAnyPublisher()
    }

    @IBAction func checkButtonPressed() {
        onAction.send(.purchase)
    }

    @IBAction func increaseQuantity() {
        onAction.send(.increment)
    }

    @IBAction func decreaseQuantity() {
        onAction.send(.decrement)
    }
}
