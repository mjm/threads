//
//  AddThreadViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

class AddThreadViewController: ReactiveTableViewController<
    AddThreadViewModel.Section, AddThreadViewModel.Cell
>
{
    var onDismiss: (() -> Void)!

    private(set) var canDismiss = true

    private var searchController: UISearchController!
    @IBOutlet var keyboardAccessoryView: UIToolbar!
    @IBOutlet var quickAddButton: UIBarButtonItem!

    let viewModel: AddThreadViewModel

    required init?(coder: NSCoder) {
        viewModel = AddThreadViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false

        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.placeholder = Localized.searchForNewThreads
        searchController.searchBar.keyboardType = .asciiCapableNumberPad
        searchController.searchBar.inputAccessoryView = keyboardAccessoryView
        searchController.searchBar.delegate = self
        searchController.searchBar.searchTextField.delegate = self

        super.viewDidLoad()

        #if targetEnvironment(macCatalyst)
        tableView.tableHeaderView = searchController.searchBar
        #else
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        #endif
    }

    override func subscribe() {
        viewModel.presenter = self

        viewModel.snapshot.apply(to: dataSource, animate: false).store(in: &cancellables)

        viewModel.$query.removeDuplicates().map { q -> String? in q }.assign(
            to: \.searchBar.text, on: searchController).store(in: &cancellables)

        viewModel.canQuickSelect.assign(to: \.isEnabled, on: quickAddButton).store(
            in: &cancellables)

        let addButton = navigationItem.rightBarButtonItems!.first!

        viewModel.canAddSelected.assign(to: \.isEnabled, on: addButton).store(in: &cancellables)
        viewModel.canAddSelected.map { !$0 }.assign(to: \.canDismiss, on: self).store(
            in: &cancellables)

        viewModel.$selectedThreads.map { threads in
            String.localizedStringWithFormat(Localized.addBatchButton, threads.count)
        }.assign(to: \.title, on: addButton).store(in: &cancellables)
    }

    override func dataSourceWillInitialize() {
        dataSource.canEditRow = { _, _, _ in true }

        dataSource.sectionTitle = { _, _, section in
            switch section {
            case .filtered: return NSLocalizedString("Matching Threads", comment: "")
            case .selected: return NSLocalizedString("Threads to Add", comment: "")
            }
        }
    }

    override var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        ["Thread": .nib(CollectionThreadTableViewCell.self)]
    }

    override func populate(cell: UITableViewCell, item: AddThreadViewModel.Cell) {
        let cell = cell as! CollectionThreadTableViewCell
        cell.bind(item.thread)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        RunLoop.main.schedule {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }

    @IBAction func tapKeyboardShortcut(sender: UIBarButtonItem) {
        viewModel.query = sender.title!
    }

    @IBAction func quickAddThread() {
        viewModel.quickSelect()
    }

    @IBAction func cancel() {
        onDismiss()
    }

    @IBAction func add() {
        viewModel.addSelected()
        onDismiss()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard super.canPerformAction(action, withSender: sender) else {
            return false
        }

        switch action {
        case #selector(add):
            return !viewModel.selectedThreads.isEmpty
        default:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath)
        -> IndexPath?
    {
        guard let item = dataSource.itemIdentifier(for: indexPath), item.section == .filtered else {
            return nil
        }

        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath), item.section == .filtered else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.select(thread: item.thread)
    }

    override func tableView(
        _ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if tableView == self.tableView {
            let delete = UIContextualAction(style: .destructive, title: Localized.dontAdd) {
                action, view, completionHandler in
                self.viewModel.deselect(at: indexPath.row)
                completionHandler(true)
            }
            delete.image = UIImage(systemName: "nosign")

            let config = UISwipeActionsConfiguration(actions: [delete])
            config.performsFirstActionWithFullSwipe = true
            return config
        }

        return nil
    }
}

extension AddThreadViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.query = searchController.searchBar.text ?? ""
    }
}

extension AddThreadViewController: UISearchBarDelegate {
}

extension AddThreadViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.quickSelect()
        return false
    }

    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string == " " {
            guard let existingText = textField.text as NSString? else {
                return false
            }

            if range.location == existingText.length {
                // a space at the end of the text means quick add thread
                viewModel.quickSelect()
            }

            return false
        }

        return true
    }
}
