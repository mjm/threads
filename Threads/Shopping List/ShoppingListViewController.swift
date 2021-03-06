//
//  ShoppingListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import CoreData
import UIKit

extension ShoppingListViewModel.Item: BindableCell {
    enum Identifier: String, CaseIterable, CellIdentifier {
        case thread = "Thread"

        var cellType: RegisteredCellType<UITableViewCell> {
            .nib(ShoppingListThreadTableViewCell.self)
        }
    }

    var cellIdentifier: Identifier { .thread }

    func bind(to cell: UITableViewCell) {
        let cell = cell as! ShoppingListThreadTableViewCell
        cell.bind(self)
    }
}

class ShoppingListViewController: ReactiveTableViewController<ShoppingListViewModel> {
    let viewModel: ShoppingListViewModel

    @IBOutlet var addCheckedButton: UIButton!
    private var canAddPurchased = false

    required init?(coder: NSCoder) {
        self.viewModel = ShoppingListViewModel()
        super.init(coder: coder)
    }

    init?(coder: NSCoder, viewModel: ShoppingListViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addCheckedButton.imageView?.tintColor = .white

        #if targetEnvironment(macCatalyst)
        tableView.tableHeaderView = nil
        tableView.allowsSelection = true
        #endif
    }

    override func subscribe() {
        viewModel.presenter = self

        dataSource
            = DataSource(tableView)
            .bound(to: viewModel.snapshot, animate: $animate, on: RunLoop.main)

        viewModel.isEmpty.sink { [weak self] isEmpty in
            self?.setShowEmptyView(isEmpty)
        }.store(in: &cancellables)

        viewModel.userActivity.map { $0.userActivity }
            .assign(to: \.userActivity, on: self, weak: true)
            .store(in: &cancellables)

        #if !targetEnvironment(macCatalyst)
        viewModel.canAddPurchasedToCollection.withLatestFrom($animate).receive(on: RunLoop.main)
            .sink
        {
            [weak self] showButton, animate in
            self?.setShowAddToCollectionButton(showButton, animated: animate)
        }.store(in: &cancellables)

        viewModel.unpurchasedCount.sink { [weak self] count in
            self?.setTabBarCount(unpurchased: count)
        }.store(in: &cancellables)
        #else
        viewModel.canAddPurchasedToCollection.assign(to: \.canAddPurchased, on: self, weak: true)
            .store(
                in: &cancellables)
        #endif
    }

    #if !targetEnvironment(macCatalyst)
    private func setShowAddToCollectionButton(_ showButton: Bool, animated: Bool) {
        let header = self.tableView.tableHeaderView!
        let height = showButton
            ? header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            : 0.0

        let changeHeight = {
            header.frame.size.height = height
            header.isHidden = !showButton
            header.layoutIfNeeded()
        }

        if animated {
            let animator = UIViewPropertyAnimator(
                duration: 0.5, dampingRatio: 0.3, animations: changeHeight)
            animator.startAnimation()
        } else {
            changeHeight()
        }
    }

    private func setTabBarCount(unpurchased: Int) {
        navigationController?.tabBarItem.badgeValue = unpurchased > 0 ? "\(unpurchased)" : nil
    }
    #endif

    private func setShowEmptyView(_ showEmptyView: Bool) {
        if showEmptyView {
            let emptyView = EmptyView()
            emptyView.textLabel.text = Localized.emptyShoppingList
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
            if tableView.backgroundView != nil {
                tableView.backgroundView = nil
            }
            if tableView.tableFooterView != nil {
                tableView.tableFooterView = nil
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selection = dataSource.itemIdentifier(for: indexPath)
    }

    override func tableView(
        _ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                UIStoryboard(name: "MyThreads", bundle: nil).instantiateViewController(
                    identifier: "ThreadPreview"
                ) { coder in
                    ThreadPreviewViewController(coder: coder, thread: item.thread)
                }
            }
        ) { suggestedActions in
            let purchased = item.togglePurchasedAction(immediate: true)
                .menuAction(state: item.thread.purchased ? .on : .off)

            let increase = item.increaseQuantityAction.menuAction()
            let decrease = item.decreaseQuantityAction.menuAction()

            let remove = item.removeAction
                .menuAction(image: UIImage(systemName: "trash"))

            if item.isDecreaseRemove {
                return UIMenu(
                    title: "",
                    children: [
                        purchased,
                        increase,
                        remove,
                    ])
            } else {
                return UIMenu(
                    title: "",
                    children: [
                        purchased,
                        UIMenu(title: "", options: .displayInline, children: [increase, decrease]),
                        remove,
                    ])
            }
        }

    }
}

// MARK: - Actions
extension ShoppingListViewController {
    @IBAction func addThreads(_ sender: Any) {
        viewModel.addThreads()
    }

    @IBAction func addCheckedToCollection(_ sender: Any) {
        viewModel.addPurchasedThreadsToCollection()
    }

    @objc func toggleThreadPurchased(_ sender: Any) {
        let immediate = sender is UIKeyCommand
        viewModel.selection?.togglePurchasedAction(immediate: immediate).perform()
    }

    @objc func incrementThreadQuantity(_ sender: Any) {
        viewModel.selection?.increaseQuantityAction.perform()
    }

    @objc func decrementThreadQuantity(_ sender: Any) {
        viewModel.selection?.decreaseQuantityAction.perform()
    }

    override func delete(_ sender: Any?) {
        viewModel.selection?.removeAction.perform()
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
        case #selector(addCheckedToCollection(_:)):
            return canAddPurchased
        case #selector(incrementThreadQuantity(_:)):
            return viewModel.selection?.increaseQuantityAction.canPerform ?? false
        case #selector(delete(_:)):
            return viewModel.selection?.removeAction.canPerform ?? false
        default:
            return true
        }
    }

    override func validate(_ command: UICommand) {
        super.validate(command)

        switch command.action {
        case #selector(toggleThreadPurchased(_:)):
            command.state = (viewModel.selectedThread?.purchased ?? false) ? .on : .off
            command.update(viewModel.selection?.togglePurchasedAction())
        case #selector(decrementThreadQuantity(_:)):
            command.update(viewModel.selection?.decreaseQuantityAction, updateTitle: true)
        default:
            return
        }
    }
}
