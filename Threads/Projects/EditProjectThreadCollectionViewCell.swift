//
//  EditProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class EditProjectThreadCollectionViewCell: ProjectThreadCollectionViewCell {
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    var onDecreaseQuantity: () -> Void = { }
    var onIncreaseQuantity: () -> Void = { }

    override func populate(_ projectThread: ProjectThread) {
        super.populate(projectThread)

        decreaseButton.setImage(UIImage(systemName: projectThread.amount == 1 ? "trash" : "minus.square"), for: .normal)
    }

    @IBAction func increaseQuantity() {
        onIncreaseQuantity()
    }

    @IBAction func decreaseQuantity() {
        onDecreaseQuantity()
    }
}
