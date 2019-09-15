//
//  ViewImageCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class ViewImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.layer.cornerRadius = 10
        imageView.layer.cornerCurve = .continuous
    }

    func populate(_ image: ProjectImage) {
        imageView.image = image.image
    }
}
