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
    
    var isOutOfStock = false

    override func populate(_ thread: Thread) {
        isOutOfStock = thread.inCollection && thread.amountInCollection == 0
        super.populate(thread)

        statusLabel.isHidden = true
        
        if thread.inCollection {
            if thread.onBobbin {
                statusLabel.isHidden = false
                statusLabel.text = Localized.onBobbin
            } else if thread.amountInCollection == 0 {
                isOutOfStock = true
                
                statusLabel.isHidden = false
                statusLabel.text = Localized.outOfStock
            }
        }
    }
    
    override func updateColors(selected: Bool) {
        super.updateColors(selected: selected)
        statusLabel.textColor = selected ? .lightText : .secondaryLabel
        
        numberLabel.textColor = selected ? .lightText : (isOutOfStock ? .secondaryLabel : .label)
        labelLabel.textColor = selected ? .lightText : (isOutOfStock ? .secondaryLabel : .label)
        backgroundColor = isOutOfStock ? .secondarySystemBackground : .systemBackground
    }
}
