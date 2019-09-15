//
//  ProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ViewProjectThreadCollectionViewCell: ProjectThreadCollectionViewCell {
    @IBOutlet var separatorLeadingConstraint: NSLayoutConstraint!

    func populate(_ projectThread: ProjectThread, isLastItem: Bool = false) {
        super.populate(projectThread)
        
        separatorLeadingConstraint.constant = isLastItem ? 0 : 15
    }
    
    static var nib = UINib(nibName: "ViewProjectThreadCollectionViewCell", bundle: nil)
}
