//
//  AddThreadViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class AddThreadViewController: UITableViewController {
    enum Section: CaseIterable {
        case threads
    }
    
    var choices: [Thread] = []
    
    private var searchController: UISearchController!
    private var resultsViewController: ThreadResultsViewController!
    
    private(set) var selectedThreads: [Thread] = []
    private var dataSource: TableViewDiffableDataSource<Section, Thread>!
    
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
        
        tableView.register(CollectionThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
        dataSource = TableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! CollectionThreadTableViewCell
            cell.populate(item)
            return cell
        }
        
        dataSource.canEditRow = { _, _, _ in true }
        
        updateSnapshot()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.searchBar.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(selectedThreads, toSection: .threads)
        dataSource.apply(snapshot)
        
        // Also update the add button to reflect the quantity
        if let addButton = navigationItem.rightBarButtonItems?.first {
            addButton.title = String.localizedStringWithFormat(Localized.addBatchButton, selectedThreads.count)
            addButton.isEnabled = !selectedThreads.isEmpty
        }
    }
    
    @IBAction func tapKeyboardShortcut(sender: UIBarButtonItem) {
        searchController.searchBar.text = sender.title!
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

class ThreadResultsViewController: UITableViewController {
    enum Section: CaseIterable {
        case threads
    }
    
    let threads: [Thread]
    var dataSource: UITableViewDiffableDataSource<Section, Thread>!
    
    init(choices: [Thread]) {
        self.threads = choices
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(CollectionThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! CollectionThreadTableViewCell
            cell.populate(item)
            return cell
        }
    }
    
    func search(_ query: String, excluding: Set<Thread>) {
        let lowerQuery = query.lowercased()
        
        let items = threads.filter {
            return !excluding.contains($0) &&
                $0.number!.lowercased().hasPrefix(lowerQuery)
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(items, toSection: .threads)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func thread(at indexPath: IndexPath) -> Thread? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}
