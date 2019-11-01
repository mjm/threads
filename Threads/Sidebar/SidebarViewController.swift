//
//  SidebarViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

extension SidebarViewModel.Item: ReusableCell {
    var cellIdentifier: String {
        "Cell"
    }
}

class SidebarViewController: ReactiveTableViewController<
    SidebarViewModel.Section, SidebarViewModel.Item
>
{
    let viewModel: SidebarViewModel

    required init?(coder: NSCoder) {
        viewModel = SidebarViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // This prevents the sidebar cells from becoming first responder, and keeps the selection appearance
        // having a vibrancy effect that looks good.
        //
        // https://github.com/mmackh/Catalyst-Helpers#blue-highlights-in-uitableviewcell-on-selection
        //
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
        tableView.addGestureRecognizer(tapRecognizer)
    }

    override func dataSourceWillInitialize() {
        dataSource.sectionTitle = { tableView, _, section in
            switch section {
            case .threads: return nil
            case .projects: return Localized.projects
            }
        }
    }

    override func subscribe() {
        viewModel.presenter = self

        viewModel.snapshot.apply(to: dataSource, animate: false).store(in: &cancellables)

        viewModel.$selectedItem.sink { [weak self] item in
            guard let self = self else { return }

            let indexPath = self.dataSource.indexPath(for: item)
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }.store(in: &cancellables)
    }

    override var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        [
            "Cell": .class(ReactiveTableViewCell.self),
        ]
    }

    override func populate(cell: UITableViewCell, item: SidebarViewModel.Item) {
        let cell = cell as! ReactiveTableViewCell

        switch item {
        case .collection:
            cell.imageView?.image = UIImage(systemName: "tray.full")
            cell.textLabel?.text = Localized.myThreads
        case .shoppingList:
            cell.imageView?.image = UIImage(systemName: "cart")
            cell.textLabel?.text = Localized.shoppingList
        case let .project(model):
            cell.imageView?.image = UIImage(systemName: "rectangle.3.offgrid.fill")
            cell.imageView?.tintColor = .systemGray
            model.name.assign(to: \.text, on: cell.textLabel!).store(in: &cell.cancellables)
        }
    }

    override func tableView(
        _ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard case let .project(model) = dataSource.itemIdentifier(for: indexPath),
            let cell = tableView.cellForRow(at: indexPath)
        else {
            return nil
        }

        let updateSelectionAfterDelete = viewModel.selectedItem == .project(model)

        return UIContextMenuConfiguration(identifier: model.project.objectID, previewProvider: nil) {
            suggestedActions in
            UIMenu(
                title: "",
                children: [
                    model.addToShoppingListAction.menuAction(image: UIImage(systemName: "cart.badge.plus")),
                    model.shareAction.menuAction(image: UIImage(systemName: "square.and.arrow.up"),
                                                 source: .view(cell)),
                    model.deleteAction.menuAction(image: UIImage(systemName: "trash")) {
                        if updateSelectionAfterDelete {
                            self.updateSelectionAfterDeletingProject(at: indexPath)
                        }
                    },
                ])
        }
    }

    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
            let item = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        viewModel.selectedItem = item
    }

    func selectionAfterDeletingItem(at indexPath: IndexPath) -> SidebarViewModel.Item {
        dataSource.itemIdentifier(
            for: IndexPath(
                row: indexPath.row,
                section: indexPath.section))
            ?? dataSource.itemIdentifier(
                for: IndexPath(
                    row: indexPath.row - 1,
                    section: indexPath.section)) ?? .collection
    }

    func updateSelectionAfterDeletingProject(at indexPath: IndexPath) {
        viewModel.selectedItem = selectionAfterDeletingItem(at: indexPath)
    }
}
