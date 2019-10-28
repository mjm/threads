//
//  MyThreadsViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

class MyThreadsViewController: ReactiveTableViewController<
    MyThreadsViewModel.Section, MyThreadsViewModel.Cell
>
{
    let viewModel: MyThreadsViewModel

    override var currentUserActivity: UserActivity? { .showMyThreads }

    required init?(coder: NSCoder) {
        viewModel = MyThreadsViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem
            = UIBarButtonItem(
                image: UIImage(systemName: "dollarsign.circle.fill"), style: .plain, target: self,
                action: #selector(buyPremium(_:)))
    }

    override func subscribe() {
        viewModel.presenter = self

        viewModel.snapshot.combineLatest($animate).apply(to: dataSource).store(in: &cancellables)

        viewModel.isEmpty.sink { [weak self] isEmpty in
            self?.setShowEmptyView(isEmpty)
        }.store(in: &cancellables)
    }

    override func dataSourceWillInitialize() {
        dataSource.canEditRow = { _, _, _ in true }
    }

    private func setShowEmptyView(_ showEmptyView: Bool) {
        if showEmptyView {
            let emptyView = EmptyView()
            emptyView.textLabel.text = Localized.emptyCollection
            emptyView.iconView.image = UIImage(named: "Bobbin")
            tableView.backgroundView = emptyView

            NSLayoutConstraint.activate([
                emptyView.leadingAnchor.constraint(
                    equalTo: tableView.safeAreaLayoutGuide.leadingAnchor),
                emptyView.trailingAnchor.constraint(
                    equalTo: tableView.safeAreaLayoutGuide.trailingAnchor),
                emptyView.topAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.topAnchor),
                emptyView.bottomAnchor.constraint(
                    equalTo: tableView.safeAreaLayoutGuide.bottomAnchor),
            ])

            tableView.tableFooterView = UIView()  // hides the empty cell separators
        } else {
            tableView.backgroundView = nil
            tableView.tableFooterView = nil
        }
    }

    override var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        ["Thread": .nib(CollectionThreadTableViewCell.self)]
    }

    override func populate(cell: UITableViewCell, item: MyThreadsViewModel.Cell) {
        let cell = cell as! CollectionThreadTableViewCell
        cell.bind(item.thread)
    }

    @objc func buyPremium(_ sender: Any) {
        viewModel.buyPremium()
    }

    @IBAction func addThreads(_ sender: Any) {
        viewModel.addThreads()
    }

    override func delete(_ sender: Any?) {
        viewModel.deleteSelectedThread()
    }

    @objc func toggleOnBobbin(_ sender: Any?) {
        viewModel.toggleSelectedThreadOnBobbin()
    }

    @objc func toggleInStock(_ sender: Any?) {
        viewModel.toggleSelectedThreadInStock()
    }

    @IBAction func unwindDeleteThread(segue: UIStoryboardSegue) {
    }

    @IBSegueAction func makeDetailController(coder: NSCoder, sender: Thread) -> UIViewController? {
        return ThreadDetailViewController(coder: coder, thread: sender)
    }

    func showDetail(for thread: Thread) {
        performSegue(withIdentifier: "ThreadDetail", sender: thread)
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(title: "Delete", action: #selector(delete(_:)), input: "\u{8}"),  // Delete key
        ]
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard super.canPerformAction(action, withSender: sender) else {
            return false
        }

        switch action {
        case #selector(delete(_:)):
            return viewModel.canDeleteSelectedThread
        default:
            return true
        }
    }

    override func validate(_ command: UICommand) {
        super.validate(command)

        switch command.action {
        case #selector(toggleOnBobbin(_:)):
            command.state = (viewModel.selectedThread?.onBobbin ?? false) ? .on : .off
            command.attributes = viewModel.canToggleSelectedThreadOnBobbin ? [] : .disabled
        case #selector(toggleInStock(_:)):
            command.state = (viewModel.selectedThread?.amountInCollection ?? 0) > 0 ? .on : .off
            command.attributes = viewModel.canToggleSelectedThreadInStock ? [] : .disabled
        default:
            return
        }
    }
}

// MARK: - Table View Delegate
extension MyThreadsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedCell = dataSource.itemIdentifier(for: indexPath)

        #if !targetEnvironment(macCatalyst)
        if case let .thread(thread) = dataSource.itemIdentifier(for: indexPath)! {
            showDetail(for: thread)
        }
        #endif
    }

    override func tableView(
        _ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let thread = dataSource.itemIdentifier(for: indexPath)?.thread else {
            return nil
        }

        if thread.amountInCollection == 0 {
            return nil
        }

        let bobbin: UIContextualAction
        if thread.onBobbin {
            bobbin
                = actionRunner.contextualAction(
                    MarkOffBobbinAction(thread: thread), title: Localized.offBobbin)
        } else {
            bobbin
                = actionRunner.contextualAction(
                    MarkOnBobbinAction(thread: thread), title: Localized.onBobbin)
        }
        bobbin.backgroundColor = UIColor(named: "BobbinSwipe")

        let config = UISwipeActionsConfiguration(actions: [bobbin])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    override func tableView(
        _ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let thread = dataSource.itemIdentifier(for: indexPath)?.thread else {
            return nil
        }

        let stock: UIContextualAction
        if thread.amountInCollection == 0 {
            stock
                = actionRunner.contextualAction(
                    MarkInStockAction(thread: thread), title: Localized.inStock)
            stock.backgroundColor = UIColor(named: "InStockSwipe")
        } else {
            stock
                = actionRunner.contextualAction(
                    MarkOutOfStockAction(thread: thread), title: Localized.outOfStock,
                    style: .destructive)
        }

        let config = UISwipeActionsConfiguration(actions: [stock])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    override func tableView(
        _ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let cell = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        let thread = cell.thread

        return UIContextMenuConfiguration(
            identifier: thread.objectID,
            previewProvider: {
                self.storyboard!.instantiateViewController(identifier: "ThreadPreview") { coder in
                    ThreadPreviewViewController(coder: coder, thread: thread)
                }
            }
        ) { suggestedActions in

            let addToShoppingListAction = self.viewModel.addToShoppingListAction(for: cell)
            let addToShoppingList = UIAction(
                title: addToShoppingListAction.title,
                image: UIImage(systemName: "cart.badge.plus"),
                attributes: addToShoppingListAction.canPerform() ? [] : .disabled
            ) { _ in
                addToShoppingListAction.perform()
            }

            // Load projects for submenu
            let addToProjectMenu: UIMenuElement

            let projectActions = self.viewModel.projectActions(for: cell)
            if projectActions.isEmpty {
                addToProjectMenu
                    = UIAction(
                        title: Localized.addToProjectMenu,
                        image: UIImage(systemName: "rectangle.3.offgrid"),
                        attributes: .disabled
                    ) { _ in }
            } else {
                addToProjectMenu
                    = UIMenu(
                        title: Localized.addToProjectMenu,
                        image: UIImage(systemName: "rectangle.3.offgrid"),
                        children: projectActions.map { action in
                            UIAction(
                                title: action.title,
                                image: UIImage(systemName: "rectangle.3.offgrid"),
                                attributes: action.canPerform() ? [] : .disabled,
                                state: action.canPerform() ? .off : .on
                            ) { _ in
                                action.perform()
                            }
                        })
            }

            let markMenu = UIMenu(
                title: "", options: .displayInline,
                children: self.viewModel.markActions(for: cell).map { action in
                    UIAction(
                        title: action.title,
                        attributes: action.canPerform() ? [] : .disabled
                    ) { _ in
                        action.perform()
                    }
                })

            let removeAction = self.viewModel.removeAction(for: cell)
            let remove = UIAction(
                title: removeAction.title,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                removeAction.perform()
            }

            return UIMenu(
                title: "",
                children: [
                    addToShoppingList,
                    addToProjectMenu,
                    markMenu,
                    remove,
                ])
        }
    }

    override func tableView(
        _ tableView: UITableView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        let thread
            = managedObjectContext.object(with: configuration.identifier as! NSManagedObjectID)
            as! Thread
        animator.addAnimations {
            self.showDetail(for: thread)
        }
    }
}

class AddThreadsToCollectionDelegate: NSObject, AddThreadViewControllerDelegate {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func choicesForAddingThreads(_ addThreadViewController: AddThreadViewController) throws
        -> [Thread]
    {
        let request = Thread.notInCollectionFetchRequest()
        return try context.fetch(request)
    }

    func addThreadViewController(
        _ addThreadViewController: AddThreadViewController,
        performActionForAddingThreads threads: [Thread], actionRunner: UserActionRunner
    ) {
        actionRunner.perform(AddToCollectionAction(threads: threads))
    }
}
