//
//  EditImageCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class EditImageCollectionViewCell: ReactiveCollectionViewCell {
    @IBOutlet var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .systemGray4
        imageView.tintColor = .systemGray2
    }

    func bind(_ model: EditProjectImageCellViewModel) {
        imageView.contentMode = .scaleAspectFill
        model.thumbnail.assign(to: \.image, on: imageView).store(in: &cancellables)
    }

    func showPlaceholder() {
        imageView.image = UIImage(systemName: "camera.fill")
        imageView.contentMode = .center
    }
}
