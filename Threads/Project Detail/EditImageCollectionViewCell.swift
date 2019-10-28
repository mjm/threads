//
//  EditImageCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class EditImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .systemGray4
        imageView.tintColor = .systemGray2
    }

    func populate(_ image: ProjectImage) {
        imageView.image = image.thumbnailImage
        imageView.contentMode = .scaleAspectFill
    }

    func showPlaceholder() {
        imageView.image = UIImage(systemName: "camera.fill")
        imageView.contentMode = .center
    }
}
