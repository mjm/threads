//
//  ProjectPreviewViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/18/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ProjectPreviewViewController: UIViewController {
    let project: Project

    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var notesLabel: UILabel!

    init?(coder: NSCoder, project: Project) {
        self.project = project
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("ProjectPreviewViewController should be created in an IBSegueAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundImageView.image = project.primaryImage?.image
        nameLabel.font = nameFont
        nameLabel.text = project.name ?? Localized.unnamedProject
        notesLabel.attributedText = project.notes?.replacing(font: .preferredFont(forTextStyle: .body), color: .label)
    }

    var nameFont: UIFont {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }
}
