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
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = 10
        imageView.layer.cornerCurve = .continuous

        imageView.tintColor = UIColor { traitCollection in
            UIColor.systemBackground
                .withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.6)
        }
    }
    
    func populate(_ project: Project) {
        nameLabel.text = project.name

        if let image = project.primaryImage?.image {
            imageView.backgroundColor = nil
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
        } else {
            imageView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.5)
            imageView.contentMode = .center
            imageView.image = UIImage(systemName: "photo")
        }
    }
}
