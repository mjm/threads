//
//  CollectionThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class CollectionThreadTableViewCell: ThreadTableViewCell {
    @IBOutlet var statusLabel: UILabel!
    
    override func bind(_ thread: Thread) {
        super.bind(thread)
        
        let inCollection = thread.publisher(for: \.inCollection)
        let isOutOfStock = inCollection.combineLatest(thread.publisher(for: \.amountInCollection)) { inCollection, amount in
            inCollection && amount == 0
        }
        let onBobbin = thread.publisher(for: \.onBobbin)
        
        isOutOfStock.combineLatest(onBobbin) { !($0 || $1) }
            .assign(to: \.isHidden, on: statusLabel)
            .store(in: &cancellables)
        isOutOfStock.combineLatest(onBobbin) { outOfStock, onBobbin in
            if onBobbin {
                return Localized.onBobbin
            } else if outOfStock {
                return Localized.outOfStock
            } else {
                return nil
            }
        }.assign(to: \.text, on: statusLabel).store(in: &cancellables)
        
        isOutOfStock.map { $0 ? UIColor.secondarySystemBackground : UIColor.systemBackground }
            .assign(to: \.backgroundColor, on: self)
            .store(in: &cancellables)
        
        selectedOrHighlighted.map { $0 ? UIColor.lightText : UIColor.secondaryLabel }
            .assign(to: \.textColor, on: statusLabel)
            .store(in: &cancellables)
        
        let labelColor = isOutOfStock.combineLatest(selectedOrHighlighted) { outOfStock, selected -> UIColor in
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
