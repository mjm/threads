//
//  ThreadDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadDetailViewController: UITableViewController {
    enum Section: CaseIterable {
        case details
        case actions
    }
    
    enum Cell {
        case details
        case delete
        
        var cellIdentifier: String {
            switch self {
            case .details: return "Details"
            case .delete: return "Action"
            }
        }
        
        func populate(cell: UITableViewCell, thread: Thread) {
            switch self {
            case .details:
                let cell = cell as! ThreadDetailsTableViewCell
                cell.populate(thread)
                
            case .delete:
                cell.textLabel!.text = Localized.removeFromCollection
                cell.textLabel!.textColor = UIColor.systemRed
            }
        }
    }
    
    let thread: Thread
    
    private var dataSource: UITableViewDiffableDataSource<Section, Cell>!
    private var actionRunner: UserActionRunner!
    
    init?(coder: NSCoder, thread: Thread) {
        self.thread = thread
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String(format: Localized.dmcNumber, thread.number!)

        if let color = thread.color {
            let textColor = color.labelColor

            let appearance = navigationController!.navigationBar.standardAppearance.copy()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            appearance.titleTextAttributes[.foregroundColor] = textColor
            appearance.largeTitleTextAttributes[.foregroundColor] = textColor
            appearance.buttonAppearance.normal.titleTextAttributes[.foregroundColor] = textColor
            navigationItem.standardAppearance = appearance.copy()

            appearance.shadowColor = nil
            navigationItem.scrollEdgeAppearance = appearance.copy()
        }

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: thread.managedObjectContext!)
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
            item.populate(cell: cell, thread: self.thread)
            return cell
        }
        
        updateSnapshot(animated: false)
        
        userActivity = UserActivity.showThread(thread).userActivity
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let textColor = thread.color?.labelColor, textColor == .white {
            return .lightContent
        } else {
            return .darkContent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = thread.color?.labelColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()

        navigationController?.navigationBar.tintColor = nil
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }

    override var undoManager: UndoManager? {
        thread.managedObjectContext?.undoManager
    }
    
    func updateSnapshot(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.details], toSection: .details)
        snapshot.appendItems([.delete], toSection: .actions)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = dataSource.itemIdentifier(for: indexPath)
        if identifier == .delete {
            tableView.deselectRow(at: indexPath, animated: true)
            actionRunner.perform(RemoveThreadAction(thread: thread), willPerform: {
                self.userActivity = nil
            }) {
                self.performSegue(withIdentifier: "DeleteThread", sender: nil)
            }
        }
    }
}

class ThreadDetailsTableViewCell: UITableViewCell {
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

    func populate(_ thread: Thread) {
        labelLabel.text = thread.label

        let background = thread.color ?? .systemBackground
        backgroundColor = background

        let foreground = background.labelColor
        labelLabel.textColor = foreground

        onBobbinStackView.isHidden = !thread.onBobbin
        onBobbinImageView.tintColor = foreground
        onBobbinLabel.textColor = foreground

        outOfStockStackView.isHidden = thread.amountInCollection > 0
        outOfStockImageView.tintColor = foreground
        outOfStockLabel.textColor = foreground

        shoppingListStackView.isHidden = !thread.inShoppingList
        shoppingListImageView.tintColor = foreground
        shoppingListLabel.text = String.localizedStringWithFormat(Localized.numberInShoppingList, thread.amountInShoppingList)
        shoppingListLabel.textColor = foreground

        let projectCount = thread.projects?.count ?? 0
        projectsStackView.isHidden = projectCount == 0
        projectsImageView.tintColor = foreground
        projectsLabel.text = String.localizedStringWithFormat(Localized.usedInProjects, projectCount)
        projectsLabel.textColor = foreground

        // hide whole stack if none are visible
        statusStackView.isHidden = statusStackView.arrangedSubviews.allSatisfy { $0.isHidden }
    }
}
