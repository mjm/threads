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
    @IBOutlet var imageView: RoundedShadowImageView!

    func populate(_ image: ProjectImage) {
        imageView.imageView.contentMode = .scaleAspectFill
        imageView.imageView.image = image.thumbnailImage
    }
}
