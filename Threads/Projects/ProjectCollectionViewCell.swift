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
    @IBOutlet var shadowView: UIView!
    @IBOutlet var roundedView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        roundedView.layer.masksToBounds = true
        roundedView.layer.cornerRadius = 10
        roundedView.layer.cornerCurve = .continuous
        roundedView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.5)
        imageView.backgroundColor = .clear

        imageView.tintColor = UIColor { traitCollection in
            UIColor.systemBackground
                .withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.6)
        }

        shadowView.clipsToBounds = false
        shadowView.layer.cornerRadius = 10
        shadowView.layer.cornerCurve = .continuous
        shadowView.layer.shadowRadius = 8
        shadowView.layer.shadowOpacity = 0.9
        shadowView.layer.shadowColor = shadowColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
    }
    
    func populate(_ project: Project) {
        nameLabel.text = project.name

        if let image = project.primaryImage?.image {
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
        } else {
            imageView.contentMode = .center
            imageView.image = UIImage(systemName: "photo")
        }
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.layer.bounds,
                                                   cornerRadius: 10).cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        shadowView.layer.shadowColor = shadowColor
    }

    private var shadowColor: CGColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.systemGray4.cgColor
            : UIColor.systemGray.cgColor
    }
}
