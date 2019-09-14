//
//  EditProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class EditProjectThreadCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    var onDecreaseQuantity: () -> Void = { }
    var onIncreaseQuantity: () -> Void = { }

    func populate(_ projectThread: ProjectThread) {
        let thread = projectThread.thread!
        colorView.color = thread.color ?? .systemBackground

        if let number = thread.number {
            numberLabel.text = "DMC \(number)"
        } else {
            numberLabel.text = ""
        }
        labelLabel.text = thread.label ?? ""

        let amount = projectThread.amount
        quantityLabel.text = "\(amount)"

        decreaseButton.setImage(UIImage(systemName: amount == 1 ? "trash" : "minus.square"), for: .normal)
    }

    @IBAction func increaseQuantity() {
        onIncreaseQuantity()
    }

    @IBAction func decreaseQuantity() {
        onDecreaseQuantity()
    }
    
    static var nib = UINib(nibName: "EditProjectThreadCollectionViewCell", bundle: nil)

}
