//
//  AddThreadViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class AddThreadViewController: TableViewController<AddThreadViewController.Section, AddThreadViewController.Cell> {
    enum Section: CaseIterable {
        case threads
    }

    enum Cell: ReusableCell {
        case thread(Thread)

        var cellIdentifier: String { "Thread" }
    }
    
    var choices: [Thread] = []
    var onCancel: (() -> Void)!
    var onAdd: (([Thread]) -> Void)!
    
    private var searchController: UISearchController!
    private var resultsViewController: ThreadResultsViewController!
    
    private var selectedThreads: [Thread] = []
    
    @IBOutlet var keyboardAccessoryView: UIToolbar!

    override func viewDidLoad() {
        super.viewDidLoad()

        resultsViewController = ThreadResultsViewController(choices: choices)
        resultsViewController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.placeholder = Localized.searchForNewThreads
        searchController.searchBar.keyboardType = .asciiCapableNumberPad
        searchController.searchBar.inputAccessoryView = keyboardAccessoryView
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
    }

    override func dataSourceWillInitialize() {
        dataSource.canEditRow = { _, _, _ in true }
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(selectedThreads.map { .thread($0) }, toSection: .threads)
    }

    override func dataSourceDidUpdateSnapshot(animated: Bool) {
        // Update the add button to reflect the quantity
        if let addButton = navigationItem.rightBarButtonItems?.first {
            addButton.title = String.localizedStringWithFormat(Localized.addBatchButton, selectedThreads.count)
            addButton.isEnabled = !selectedThreads.isEmpty
        }
    }

    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        ["Thread": .nib(CollectionThreadTableViewCell.self)]
    }

    override func populate(cell: UITableViewCell, item: AddThreadViewController.Cell) {
        switch item {
        case let .thread(thread):
            let cell = cell as! CollectionThreadTableViewCell
            cell.populate(thread)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.searchBar.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    @IBAction func tapKeyboardShortcut(sender: UIBarButtonItem) {
        searchController.searchBar.text = sender.title!
    }

    @IBAction func cancel() {
        onCancel()
    }

    @IBAction func add() {
        onAdd(selectedThreads)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView == self.tableView {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(tableView == resultsViewController.tableView)
        
        guard let thread = resultsViewController.thread(at: indexPath) else {
            return
        }
        
        selectedThreads.append(thread)
        updateSnapshot()
        
        searchController.searchBar.text = ""
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tableView == self.tableView {
            let delete = UIContextualAction(style: .destructive, title: Localized.dontAdd) { action, view, completionHandler in
                self.selectedThreads.remove(at: indexPath.row)
                self.updateSnapshot()
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
        let exclusions = Set(selectedThreads)
        resultsViewController.search(searchController.searchBar.text ?? "", excluding: exclusions)
    }
}

class ThreadResultsViewController: TableViewController<ThreadResultsViewController.Section, AddThreadViewController.Cell> {
    enum Section: CaseIterable {
        case threads
    }
    
    let threads: [Thread]
    var query = ""
    var exclusions = Set<Thread>()

    var filteredThreads: [Thread] {
        if query.isEmpty {
            return []
        } else {
            return threads.filter {
                return !exclusions.contains($0) &&
                    $0.number!.lowercased().hasPrefix(query)
            }
        }
    }

    init(choices: [Thread]) {
        self.threads = choices
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override var canBecomeFirstResponder: Bool {
        false
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(filteredThreads.map { .thread($0) }, toSection: .threads)
    }

    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        ["Thread": .nib(CollectionThreadTableViewCell.self)]
    }

    override func populate(cell: UITableViewCell, item: AddThreadViewController.Cell) {
        switch item {
        case let .thread(thread):
            let cell = cell as! CollectionThreadTableViewCell
            cell.populate(thread)
        }
    }
    
    func search(_ query: String, excluding: Set<Thread>) {
        self.query = query.lowercased()
        self.exclusions = excluding

        updateSnapshot(animated: false)
    }
    
    func thread(at indexPath: IndexPath) -> Thread? {
        if case let .thread(thread) = dataSource.itemIdentifier(for: indexPath) {
            return thread
        }

        return nil
    }
}
