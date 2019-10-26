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
    
    override func bind(_ thread: Thread) {
        super.bind(thread)
        
        let isPurchased = thread.publisher(for: \.purchased)
        let amount = thread.publisher(for: \.amountInShoppingList)
        
        amount.map { "\($0)" }
            .assign(to: \.text, on: quantityLabel)
            .store(in: &cancellables)
        
        amount.map { $0 == 1 ? "trash" : "minus.square" }
            .map { UIImage(systemName: $0) }
            .sink { [decreaseButton] image in
                decreaseButton?.setImage(image, for: .normal)
            }.store(in: &cancellables)
        
        isPurchased.map { $0 ? "checkmark.square" : "square" }
            .map { UIImage(systemName: $0) }
            .sink { [checkButton] image in
                checkButton?.setImage(image, for: .normal)
            }.store(in: &cancellables)
        
        let isNotPurchased = isPurchased.map { !$0 }
        isNotPurchased.assign(to: \.isEnabled, on: decreaseButton).store(in: &cancellables)
        isNotPurchased.assign(to: \.isEnabled, on: increaseButton).store(in: &cancellables)
        
        isPurchased.map { $0 ? UIColor.secondarySystemBackground : UIColor.systemBackground }
            .assign(to: \.backgroundColor, on: self)
            .store(in: &cancellables)
        
        let purchasedSelected = isPurchased.combineLatest(selectedOrHighlighted)
        
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
