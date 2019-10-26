//
//  ThreadDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData
import Combine

class ThreadDetailViewController: ReactiveTableViewController<ThreadDetailViewController.Section, ThreadDetailViewController.Cell> {
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
    
    @IBOutlet var actionsButtonItem: UIBarButtonItem!
    
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
            appearance.largeTitleTextAttributes[.font] = {
                let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
                let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .heavy)
                return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
            }()
            appearance.buttonAppearance.normal.titleTextAttributes[.foregroundColor] = textColor
            navigationItem.standardAppearance = appearance.copy()

            appearance.shadowColor = nil
            navigationItem.scrollEdgeAppearance = appearance.copy()
        }
    }
    
    override func subscribe() {
        projectsList = FetchedObjectList(
            fetchRequest: ProjectThread.fetchRequest(for: thread),
            managedObjectContext: thread.managedObjectContext!
        )
        
        let projectThreads = projectsList.objectsPublisher()
        let inShoppingList = thread.publisher(for: \.inShoppingList)
        
        // Updating the snapshot, even if it hasn't changed, causes the table view
        // to animate the potential height change in the details cell.
        let updateDetails = thread.publisher(for: \.onBobbin)
            .combineLatest(thread.publisher(for: \.amountInCollection)) { _, _ in }
        
        let updateProject = projectsList.objectPublisher()
            .merge(with: managedObjectContext.publisher(type: Project.self).compactMap { project in
                self.projectsList.objects.first { $0.project == project }
            })
        
        projectThreads.combineLatest(inShoppingList, updateDetails) { projectThreads, inShoppingList, _ in
            var snapshot = Snapshot()
            
            snapshot.appendSections([.details])
            snapshot.appendItems([.details], toSection: .details)

            if inShoppingList {
                snapshot.appendSections([.shoppingList])
                snapshot.appendItems([.shoppingList], toSection: .shoppingList)
            }

            if !projectThreads.isEmpty {
                snapshot.appendSections([.projects])
                snapshot.appendItems(projectThreads.map { .project($0) }, toSection: .projects)
            }
            
            return snapshot
        }.combineLatest($animate).apply(to: dataSource).store(in: &cancellables)
        
        updateDetails.sink { [weak self] _ in
            self?.updateDetails()
        }.store(in: &cancellables)
        updateProject.sink { [weak self] projectThread in
            self?.updateCell(projectThread)
        }.store(in: &cancellables)
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
    }

    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        [
            "ShoppingList": .nib(ShoppingListThreadTableViewCell.self),
            "Project": .class(UITableViewCell.self),
        ]
    }
    
    private var shoppingListSubscription: AnyCancellable?

    override func populate(cell: UITableViewCell, item: ThreadDetailViewController.Cell) {
        let thread = self.thread

        switch item {

        case .details:
            let cell = cell as! ThreadDetailsTableViewCell
            cell.populate(thread)
            
        case .shoppingList:
            let cell = cell as! ShoppingListThreadTableViewCell
            cell.bind(thread)
            
            shoppingListSubscription = cell.actionPublisher().sink { [weak self] action in
                switch action {
                case .purchase:
                    self?.actionRunner.perform(TogglePurchasedAction(thread: thread))
                case .increment:
                    self?.actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .increment))
                case .decrement:
                    self?.actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .decrement))
                }
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

    func updateDetails() {
        guard let cell = dataSource.indexPath(for: .details).flatMap({ tableView.cellForRow(at: $0) as? ThreadDetailsTableViewCell }) else {
            return
        }

        cell.populate(thread)
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
        let sheet = UIAlertController(actionRunner: actionRunner, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.barButtonItem = actionsButtonItem

        if !thread.inShoppingList {
            sheet.addAction(AddToShoppingListAction(thread: thread))
        }

        // TODO add to project

        if thread.amountInCollection == 0 {
            sheet.addAction(MarkInStockAction(thread: thread))
        } else {
            if thread.onBobbin {
                sheet.addAction(MarkOffBobbinAction(thread: thread))
            } else {
                sheet.addAction(MarkOnBobbinAction(thread: thread))
            }

            sheet.addAction(MarkOutOfStockAction(thread: thread))
        }
        
        sheet.addAction(
            RemoveThreadAction(thread: thread),
            title: Localized.removeFromCollection,
            style: .destructive,
            willPerform: {
                self.userActivity = nil
            }
        ) {
            self.performSegue(withIdentifier: "DeleteThread", sender: nil)
        }

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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
        case let .project(projectThread):
            guard let project = projectThread.project,
                let scene = view.window?.windowScene else {
                return
            }

            let activity = UserActivity.showProject(project)
            let sceneDelegate = scene.delegate as! SceneDelegate
            sceneDelegate.scene(scene, continue: activity.userActivity)

        default:
            return
        }
    }
}

// MARK: -
class ThreadDetailsTableViewCell: UITableViewCell {
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var statusStackView: UIStackView!
    @IBOutlet var onBobbinStackView: UIStackView!
    @IBOutlet var onBobbinImageView: UIImageView!
    @IBOutlet var onBobbinLabel: UILabel!
    @IBOutlet var outOfStockStackView: UIStackView!
    @IBOutlet var outOfStockImageView: UIImageView!
    @IBOutlet var outOfStockLabel: UILabel!

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

        // hide whole stack if none are visible
        statusStackView.isHidden = statusStackView.arrangedSubviews.allSatisfy { $0.isHidden }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // hide top separator for this one
        for view in subviews {
            if view != contentView && view.frame.origin.y == 0.0 {
                view.isHidden = true
            }
        }
    }
}
