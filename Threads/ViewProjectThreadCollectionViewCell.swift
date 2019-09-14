//
//  ProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ViewProjectThreadCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var separatorLeadingConstraint: NSLayoutConstraint!

    func populate(_ projectThread: ProjectThread, isLastItem: Bool = false) {
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
        
        separatorLeadingConstraint.constant = isLastItem ? 0 : 15
    }
    
    static var nib = UINib(nibName: "ViewProjectThreadCollectionViewCell", bundle: nil)
}
