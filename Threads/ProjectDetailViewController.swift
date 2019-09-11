//
//  ProjectDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/9/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ProjectDetailViewController: UITableViewController {
    enum Section: CaseIterable {
        case threads
    }
    
    enum Cell: Hashable {
        case thread(Thread)
        case add
        
        var cellIdentifier: String {
            switch self {
            case .thread: return "Thread"
            case .add: return "Add"
            }
        }
        
        func populate(cell: UITableViewCell, project: Project) {
            switch self {
            case let .thread(thread):
                (cell as! CollectionThreadTableViewCell).populate(thread)
            case .add:
                cell.textLabel!.text = "Add Thread to Project"
                cell.imageView!.image = UIImage(systemName: "plus.circle")
            }
        }
    }
    
    let project: Project

    private var fetchedResultsController: NSFetchedResultsController<Thread>!
    private var dataSource: TableViewDiffableDataSource<Section, Cell>!
    
    init?(coder: NSCoder, project: Project) {
        self.project = project
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = project.name
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.fetchRequest(for: project),
                                       managedObjectContext: project.managedObjectContext!,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        tableView.register(CollectionThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Add")
        dataSource = TableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
            item.populate(cell: cell, project: self.project)
            return cell
        }
        
        dataSource.canEditRow = { _, _, item in
            item != .add
        }
        
        dataSource.sectionTitle = { [weak self] _, _, section in
            switch section {
            case .threads:
                guard let items = self?.fetchedResultsController.fetchedObjects?.count else {
                    return "Threads"
                }
                return "\(items) Thread\(items == 1 ? "" : "s")"
            }
        }
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot()
        } catch {
            NSLog("Could not load project threads: \(error)")
        }
    }
    
    func updateSnapshot() {
        let objects = fetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(objects.map { Cell.thread($0) }, toSection: .threads)
        snapshot.appendItems([.add], toSection: .threads)
        dataSource.apply(snapshot)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let item = dataSource.itemIdentifier(for: indexPath)
        return item == .add ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        if item == .add {
            NSLog("Adding a thread to a project")
        }
    }
}

extension ProjectDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
}
