//
//  ProjectCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/8/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class ProjectCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: RoundedShadowImageView!
    @IBOutlet var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.5)

        imageView.imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 45)
        imageView.imageView.tintColor = UIColor { traitCollection in
            UIColor.systemBackground
                .withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.6)
        }
    }
    
    func populate(_ project: Project) {
        nameLabel.text = project.name

        if let image = project.primaryImage?.thumbnailImage {
            imageView.imageView.contentMode = .scaleAspectFill
            imageView.imageView.image = image
        } else {
            imageView.imageView.contentMode = .center
            imageView.imageView.image = UIImage(systemName: "photo")
        }

        imageView.setNeedsLayout()
    }
}
