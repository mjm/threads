//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!

    func populate(_ thread: Thread) {
        colorView.color = thread.color ?? .systemBackground

        if let number = thread.number {
            numberLabel.text = String(format: Localized.dmcNumber, number)
        } else {
            numberLabel.text = Localized.dmcNumberUnknown
        }
        labelLabel.text = thread.label ?? ""
        
        updateColors(selected: isSelected || isHighlighted)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateColors(selected: selected || isHighlighted)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateColors(selected: highlighted || isSelected)
    }
    
    func updateColors(selected: Bool) {
        backgroundColor = .systemBackground
        numberLabel.textColor = selected ? .lightText : .label
        labelLabel.textColor = selected ? .lightText : .label
    }
}
