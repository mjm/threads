//
//  ThreadPreviewViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/14/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadPreviewViewController: UIViewController {
    let thread: Thread

    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var statusStackView: UIStackView!
    @IBOutlet var onBobbinStackView: UIStackView!
    @IBOutlet var onBobbinImageView: UIImageView!
    @IBOutlet var onBobbinLabel: UILabel!
    @IBOutlet var outOfStockStackView: UIStackView!
    @IBOutlet var outOfStockImageView: UIImageView!
    @IBOutlet var outOfStockLabel: UILabel!
    @IBOutlet var shoppingListStackView: UIStackView!
    @IBOutlet var shoppingListImageView: UIImageView!
    @IBOutlet var shoppingListLabel: UILabel!
    @IBOutlet var projectsStackView: UIStackView!
    @IBOutlet var projectsImageView: UIImageView!
    @IBOutlet var projectsLabel: UILabel!

    init?(coder: NSCoder, thread: Thread) {
        self.thread = thread
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("ThreadPreviewViewController should be created in an IBSegueAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        numberLabel.text = String(format: Localized.dmcNumber, thread.number!)
        numberLabel.font = numberFont
        labelLabel.text = thread.label

        let background = thread.color ?? .systemBackground
        view.backgroundColor = background

        let foreground = background.labelColor
        numberLabel.textColor = foreground
        labelLabel.textColor = foreground

        onBobbinStackView.isHidden = !thread.onBobbin
        onBobbinImageView.tintColor = foreground
        onBobbinLabel.textColor = foreground

        outOfStockStackView.isHidden = thread.amountInCollection > 0
        outOfStockImageView.tintColor = foreground
        outOfStockLabel.textColor = foreground

        shoppingListStackView.isHidden = !thread.inShoppingList
        shoppingListImageView.tintColor = foreground
        shoppingListLabel.text
            = String.localizedStringWithFormat(
                Localized.numberInShoppingList, thread.amountInShoppingList)
        shoppingListLabel.textColor = foreground

        let projectCount = thread.projects?.count ?? 0
        projectsStackView.isHidden = projectCount == 0
        projectsImageView.tintColor = foreground
        projectsLabel.text
            = String.localizedStringWithFormat(Localized.usedInProjects, projectCount)
        projectsLabel.textColor = foreground

        // hide whole stack if none are visible
        statusStackView.isHidden = statusStackView.arrangedSubviews.allSatisfy { $0.isHidden }
    }

    var numberFont: UIFont {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .heavy)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }
}
