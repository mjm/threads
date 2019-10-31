//
//  ProjectCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/8/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

@IBDesignable
class ProjectCollectionViewCell: ReactiveCollectionViewCell {
    @IBOutlet var imageView: RoundedShadowImageView!
    @IBOutlet var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.5)

        imageView.imageView.preferredSymbolConfiguration
            = UIImage.SymbolConfiguration(pointSize: 45)
        imageView.imageView.tintColor
            = UIColor { traitCollection in
                UIColor.systemBackground
                    .withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.6)
            }
    }

    func bind(_ model: ProjectCellViewModel) {
        model.name.assign(to: \.text, on: nameLabel).store(in: &cancellables)

        model.image.sink { [weak self] image in
            if let image = image {
                self?.imageView.imageView.contentMode = .scaleAspectFill
                self?.imageView.imageView.image = image
            } else {
                self?.imageView.imageView.contentMode = .center
                self?.imageView.imageView.image = UIImage(systemName: "photo")
            }

            self?.imageView.setNeedsLayout()
        }.store(in: &cancellables)
    }
}
