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

extension MyThreadsViewModel.Item: ReusableCell {
    var cellIdentifier: String { "Thread" }
}

class MyThreadsViewController: ReactiveTableViewController<MyThreadsViewModel> {
    let viewModel: MyThreadsViewModel

    required init?(coder: NSCoder) {
        self.viewModel = MyThreadsViewModel()
        super.init(coder: coder)
    }

    init?(coder: NSCoder, viewModel: MyThreadsViewModel) {
        self.viewModel = viewModel
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

        viewModel.snapshot.apply(to: dataSource, animate: $animate).store(in: &cancellables)

        viewModel.isEmpty.sink { [weak self] isEmpty in
            self?.setShowEmptyView(isEmpty)
        }.store(in: &cancellables)

        viewModel.userActivity.map { $0.userActivity }.assign(to: \.userActivity, on: self).store(
            in: &cancellables)
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

    override func populate(cell: UITableViewCell, item: MyThreadsViewModel.Item) {
        let cell = cell as! CollectionThreadTableViewCell
        cell.bind(item)
    }

    @objc func buyPremium(_ sender: Any) {
        viewModel.buyPremium()
    }

    @IBAction func addThreads(_ sender: Any) {
        viewModel.addThreads()
    }

    override func delete(_ sender: Any?) {
        viewModel.selection?.removeAction.perform()
    }

    @objc func toggleOnBobbin(_ sender: Any?) {
        viewModel.selection?.bobbinAction?.perform()
    }

    @objc func toggleInStock(_ sender: Any?) {
        viewModel.selection?.stockAction.perform()
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
            return viewModel.selection?.removeAction.canPerform ?? false
        default:
            return true
        }
    }

    override func validate(_ command: UICommand) {
        super.validate(command)

        switch command.action {
        case #selector(toggleOnBobbin(_:)):
            command.state = (viewModel.selectedThread?.onBobbin ?? false) ? .on : .off
            command.update(viewModel.selection?.bobbinAction)
        case #selector(toggleInStock(_:)):
            command.state = (viewModel.selectedThread?.amountInCollection ?? 0) > 0 ? .on : .off
            command.update(viewModel.selection?.stockAction)
        default:
            return
        }
    }
}

// MARK: - Table View Delegate
extension MyThreadsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selection = dataSource.itemIdentifier(for: indexPath)

        #if !targetEnvironment(macCatalyst)
        if let thread = viewModel.selectedThread {
            showDetail(for: thread)
        }
        #endif
    }

    override func tableView(
        _ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath),
            let bobbinAction = item.bobbinAction
        else {
            return nil
        }

        let bobbin = bobbinAction.contextualAction()
        bobbin.backgroundColor = UIColor(named: "BobbinSwipe")

        let config = UISwipeActionsConfiguration(actions: [bobbin])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    override func tableView(
        _ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        let stockAction = item.stockAction
        let stock = stockAction.contextualAction()
        if !stockAction.isDestructive {
            stock.backgroundColor = UIColor(named: "InStockSwipe")
        }

        let config = UISwipeActionsConfiguration(actions: [stock])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    override func tableView(
        _ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: viewModel.identifier(for: item),
            previewProvider: {
                self.storyboard!.instantiateViewController(identifier: "ThreadPreview") { coder in
                    ThreadPreviewViewController(coder: coder, thread: item.thread)
                }
            }
        ) { suggestedActions in

            let addToShoppingList = item.addToShoppingListAction
                .menuAction(image: UIImage(systemName: "cart.badge.plus"))

            // Load projects for submenu
            let addToProjectMenu: UIMenuElement
            let projectImage = UIImage(systemName: "rectangle.3.offgrid")

            let projectActions = item.projectActions
            if projectActions.isEmpty {
                addToProjectMenu
                    = UIAction(
                        title: Localized.addToProjectMenu,
                        image: projectImage,
                        attributes: .disabled
                    ) { _ in }
            } else {
                addToProjectMenu
                    = UIMenu(
                        title: Localized.addToProjectMenu,
                        image: projectImage,
                        children: projectActions.map { action in
                            action.menuAction(
                                image: projectImage,
                                state: action.canPerform ? .off : .on)
                        })
            }

            let markMenu = UIMenu(
                title: "", options: .displayInline,
                children: item.markActions.map {
                    var action = $0
                    action.isDestructive = false
                    return action.menuAction()
                })

            let remove = item.removeAction
                .menuAction(image: UIImage(systemName: "trash"))

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
        guard let thread = viewModel.thread(for: configuration.identifier) else {
            return
        }

        animator.addAnimations {
            self.showDetail(for: thread)
        }
    }
}
