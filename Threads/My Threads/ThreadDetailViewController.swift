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
        case shoppingList
        case projects
    }
    
    enum Cell: Hashable {
        case details
        case shoppingList
        case project(ProjectThread)
        
        var cellIdentifier: String {
            switch self {
            case .details: return "Details"
            case .shoppingList: return "ShoppingList"
            case .project: return "Project"
            }
        }
        
        func populate(cell: UITableViewCell, thread: Thread, controller: ThreadDetailViewController) {
            let actionRunner = controller.actionRunner!

            switch self {
            case .details:
                let cell = cell as! ThreadDetailsTableViewCell
                cell.populate(thread)
            case .shoppingList:
                let cell = cell as! ShoppingListThreadTableViewCell
                cell.populate(thread)
                cell.onCheckTapped = {
                    actionRunner.perform(TogglePurchasedAction(thread: thread))
                }
                cell.onDecreaseQuantity = {
                    actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .decrement))
                }
                cell.onIncreaseQuantity = {
                    actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .increment))
                }
            case let .project(projectThread):
                cell.textLabel?.text = projectThread.project?.name
            }
        }
    }
    
    let thread: Thread
    
    private var dataSource: TableViewDiffableDataSource<Section, Cell>!
    private var actionRunner: UserActionRunner!

    private var observers: [NSKeyValueObservation] = []
    
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

        ShoppingListThreadTableViewCell.registerNib(on: tableView, reuseIdentifier: "ShoppingList")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Project") // TODO maybe use a custom cell?
        dataSource = TableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
            item.populate(cell: cell, thread: self.thread, controller: self)
            return cell
        }

        dataSource.sectionTitle = { _, _, section in
            switch section {
            case .details:
                return nil
            case .shoppingList:
                return Localized.inShoppingList
            case .projects:
                return Localized.projects
            }
        }
        
        updateSnapshot(animated: false)

        observers.append(thread.observe(\.inShoppingList) { [weak self] _, _ in
            self?.updateSnapshot()
        })

        let updateShoppingListCell = { [weak self] (thread: Thread, _: Any) in
            guard let self = self else { return }

            guard let indexPath = self.dataSource.indexPath(for: .shoppingList),
                let cell = self.tableView.cellForRow(at: indexPath) as? ShoppingListThreadTableViewCell else {
                return
            }

            cell.populate(thread)
        }

        observers.append(thread.observe(\.amountInShoppingList, changeHandler: updateShoppingListCell))
        observers.append(thread.observe(\.purchased, changeHandler: updateShoppingListCell))
        
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
        snapshot.appendSections([.details])
        snapshot.appendItems([.details], toSection: .details)

        if thread.inShoppingList {
            snapshot.appendSections([.shoppingList])
            snapshot.appendItems([.shoppingList], toSection: .shoppingList)
        }

        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - Actions
extension ThreadDetailViewController {
    @IBAction func showActions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let deleteAction = actionRunner.alertAction(RemoveThreadAction(thread: thread), title: Localized.removeFromCollection, style: .destructive, willPerform: {
            self.userActivity = nil
        }) {
            self.performSegue(withIdentifier: "DeleteThread", sender: nil)
        }
        sheet.addAction(deleteAction)

        sheet.addAction(UIAlertAction(title: Localized.cancel, style: .cancel))

        present(sheet, animated: true)
    }
}

// MARK: - Table View Delegate
extension ThreadDetailViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        if case .project = item {
            return indexPath
        }

        return nil
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

        let projectCount = thread.projects?.count ?? 0
        projectsStackView.isHidden = projectCount == 0
        projectsImageView.tintColor = foreground
        projectsLabel.text = String.localizedStringWithFormat(Localized.usedInProjects, projectCount)
        projectsLabel.textColor = foreground

        // hide whole stack if none are visible
        statusStackView.isHidden = statusStackView.arrangedSubviews.allSatisfy { $0.isHidden }
    }
}
