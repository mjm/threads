//
//  ViewImageCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import UIKit

@IBDesignable
class ViewImageCollectionViewCell: CombinableCollectionViewCell {
    @IBOutlet var imageView: RoundedShadowImageView!

    func bind(_ model: ViewProjectImageCellViewModel) {
        imageView.imageView.contentMode = .scaleAspectFill
        model.thumbnail.assign(to: \.image, on: imageView.imageView).store(in: &cancellables)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.imageView.image = nil
    }
}
