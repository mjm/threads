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
    
    static var nib = UINib(nibName: "ProjectCollectionViewCell", bundle: nil)
    
    class func makePrototype() -> ProjectCollectionViewCell {
        return nib.instantiate(withOwner: nil, options: nil).first as! ProjectCollectionViewCell
    }
}
