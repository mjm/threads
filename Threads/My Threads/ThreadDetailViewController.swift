//
//  ThreadDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ThreadDetailViewController: TableViewController<ThreadDetailViewController.Section, ThreadDetailViewController.Cell> {
    enum Section: CaseIterable {
        case details
        case shoppingList
        case projects
    }
    
    enum Cell: ReusableCell {
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
    }
    
    let thread: Thread

    private var projectsList: FetchedObjectList<ProjectThread>!

    private var observers: [NSKeyValueObservation] = []
    private var projectsObserver: Any!
    
    init?(coder: NSCoder, thread: Thread) {
        self.thread = thread
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override var managedObjectContext: NSManagedObjectContext {
        thread.managedObjectContext!
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

        // Ensure we update the project names correctly.
        //
        // Watch all Core Data object changes, and whenever anything changes about a project, update the cell for the affected project thread.
        projectsObserver = managedObjectContext.observeChanges(type: Project.self) { [weak self] affectedProjects in
            guard let self = self else {
                return
            }

            let interestingProjects = Dictionary(uniqueKeysWithValues: self.projectsList.objects.compactMap { projectThread in
                projectThread.project.flatMap { ($0, projectThread) }
            })

            for project in affectedProjects {
                if let projectThread = interestingProjects[project] {
                    self.updateCell(projectThread)
                }
            }
        }

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
    }

    deinit {
        if let observer = projectsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override var currentUserActivity: UserActivity? { .showThread(thread) }

    override func dataSourceWillInitialize() {
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

        projectsList = FetchedObjectList(
            fetchRequest: ProjectThread.fetchRequest(for: thread),
            managedObjectContext: thread.managedObjectContext!,
            updateSnapshot: { [weak self] in
                self?.updateSnapshot()
            },
            updateCell: { [weak self] projectThread in
                self?.updateCell(projectThread)
            }
        )
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        snapshot.appendSections([.details])
        snapshot.appendItems([.details], toSection: .details)

        if thread.inShoppingList {
            snapshot.appendSections([.shoppingList])
            snapshot.appendItems([.shoppingList], toSection: .shoppingList)
        }

        let projectThreads = projectsList.objects
        if !projectThreads.isEmpty {
            snapshot.appendSections([.projects])
            snapshot.appendItems(projectThreads.map { .project($0) }, toSection: .projects)
        }
    }

    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        [
            "ShoppingList": .nib(ShoppingListThreadTableViewCell.self),
            "Project": .class(UITableViewCell.self),
        ]
    }

    override func populate(cell: UITableViewCell, item: ThreadDetailViewController.Cell) {
        let thread = self.thread

        switch item {

            case .details:
                let cell = cell as! ThreadDetailsTableViewCell
                cell.populate(thread)

            case .shoppingList:
                let cell = cell as! ShoppingListThreadTableViewCell
                cell.populate(thread)
                cell.onCheckTapped = { [weak self] in
                    self?.actionRunner.perform(TogglePurchasedAction(thread: thread))
                }
                cell.onDecreaseQuantity = { [weak self] in
                    self?.actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .decrement))
                }
                cell.onIncreaseQuantity = { [weak self] in
                    self?.actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .increment))
                }

            case let .project(projectThread):
                cell.textLabel?.text = projectThread.project?.name
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = nil
    }

    func updateCell(_ projectThread: ProjectThread) {
        guard let cell = cellForProjectThread(projectThread) else {
            return
        }

        cell.textLabel?.text = projectThread.project?.name
    }

    private func cellForProjectThread(_ projectThread: ProjectThread) -> UITableViewCell? {
        guard let indexPath = dataSource.indexPath(for: .project(projectThread)) else {
            return nil
        }

        return tableView.cellForRow(at: indexPath)
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
