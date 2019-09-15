//
//  ProjectCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/8/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ProjectCollectionViewCell: UICollectionViewCell {
    // TODO: make this a more custom view
    @IBOutlet var colorView: UIView!
    @IBOutlet var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorView.layer.cornerRadius = 10
    }
    
    func populate(_ project: Project) {
        nameLabel.text = project.name
        colorView.backgroundColor = .systemOrange
    }
}
