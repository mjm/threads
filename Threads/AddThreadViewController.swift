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
    
    var managedObjectContext: NSManagedObjectContext!
    
    private var searchController: UISearchController!
    private var resultsViewController: ThreadResultsViewController!
    
    private var selectedThreads: [DMCThread] = []
    private var dataSource: UITableViewDiffableDataSource<Section, DMCThread>!

    override func viewDidLoad() {
        super.viewDidLoad()

        resultsViewController = ThreadResultsViewController()
        resultsViewController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
        
        dataSource = TableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath)
            cell.textLabel!.text = "\(item.number): \(item.label)"
            return cell
        }
        updateSnapshot()
    }
    
    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, DMCThread>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(selectedThreads, toSection: .threads)
        dataSource.apply(snapshot)
        
        // Also update the add button to reflect the quantity
        if let addButton = navigationItem.rightBarButtonItems?.first {
            if selectedThreads.isEmpty {
                addButton.title = "Add"
                addButton.isEnabled = false
            } else {
                addButton.title = "Add (\(selectedThreads.count))"
                addButton.isEnabled = true
            }
        }
    }
    
    private func getExistingThreads() throws -> [DMCThread] {
        let request: NSFetchRequest<Thread> = Thread.fetchRequest()
        let threads = try managedObjectContext.fetch(request)
        return threads.map { $0.dmcThread }
    }
    
    @IBAction func addToCollection() {
        for t in selectedThreads {
            _ = Thread(dmcThread: t, context: managedObjectContext)
        }
        
        AppDelegate.save()
        
        presentingViewController!.dismiss(animated: true)
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
            let delete = UIContextualAction(style: .destructive, title: "Don't Add") { action, view, completionHandler in
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
        var exclusions = Set(selectedThreads)
        do {
            exclusions.formUnion(try getExistingThreads())
        } catch {
            NSLog("Error fetching existing threads: \(error)")
        }
        
        resultsViewController.search(searchController.searchBar.text ?? "", excluding: exclusions)
    }
}

class ThreadResultsViewController: UITableViewController {
    enum Section: CaseIterable {
        case threads
    }
    
    var dataSource: UITableViewDiffableDataSource<Section, DMCThread>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Thread")
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath)
            cell.textLabel!.text = "\(item.number): \(item.label)"
            return cell
        }
    }
    
    func search(_ query: String, excluding: Set<DMCThread>) {
        let lowerQuery = query.lowercased()
        
        let items = DMCThread.all.filter {
            return !excluding.contains($0) &&
                ($0.number.lowercased().hasPrefix(lowerQuery) ||
                    $0.label.lowercased().contains(lowerQuery))
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, DMCThread>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(items, toSection: .threads)
        dataSource.apply(snapshot)
    }
    
    func thread(at indexPath: IndexPath) -> DMCThread? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}
