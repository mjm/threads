//
//  ThreadDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadDetailViewController: UITableViewController {
    enum Section: CaseIterable {
        case details
        case actions
    }
    
    enum Cell {
        case label
        case collection
        case bobbin
        case colorBar
        
        case delete
        
        var cellIdentifier: String {
            switch self {
            case .label: return "Label"
            case .collection, .bobbin: return "Status"
            case .colorBar: return "ColorBar"

            case .delete: return "Action"
            }
        }
        
        func populate(cell: UITableViewCell, thread: Thread) {
            switch self {
            case .label:
                cell.textLabel!.text = thread.label
            case .collection:
                if thread.amountInCollection > 0 {
                    cell.textLabel!.text = "In Stock"
                    cell.textLabel!.textColor = UIColor.label
                    cell.imageView!.image = UIImage(systemName: "tray.full")
                    cell.imageView!.tintColor = UIColor.label
                } else {
                    cell.textLabel!.text = "Out of Stock"
                    cell.textLabel!.textColor = UIColor.secondaryLabel
                    cell.imageView!.image = UIImage(systemName: "tray")
                    cell.imageView!.tintColor = UIColor.secondaryLabel
                }
            case .bobbin:
                if thread.onBobbin {
                    cell.textLabel!.text = "On Bobbin"
                    cell.textLabel!.textColor = UIColor.label
                    cell.imageView!.image = UIImage(systemName: "checkmark.circle")
                    cell.imageView!.tintColor = UIColor.label
                } else {
                    cell.textLabel!.text = "Not On Bobbin"
                    cell.textLabel!.textColor = UIColor.secondaryLabel
                    cell.imageView!.image = UIImage(systemName: "circle")
                    cell.imageView!.tintColor = UIColor.secondaryLabel
                }
            case .colorBar:
                cell.backgroundColor = thread.color
                
            case .delete:
                cell.textLabel!.text = "Remove from Collection"
                cell.textLabel!.textColor = UIColor.systemRed
            }
        }
    }
    
    let thread: Thread
    
    var dataSource: UITableViewDiffableDataSource<Section, Cell>!
    
    init?(coder: NSCoder, thread: Thread) {
        self.thread = thread
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "DMC \(thread.number!)"
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
            item.populate(cell: cell, thread: self.thread)
            return cell
        }
        
        updateSnapshot(animated: false)
        
        userActivity = UserActivity.showThread(thread).userActivity
    }
    
    func updateSnapshot(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.label, .collection, .bobbin, .colorBar], toSection: .details)
        snapshot.appendItems([.delete], toSection: .actions)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = dataSource.itemIdentifier(for: indexPath)
        if identifier == .delete {
            deleteThread(indexPath: indexPath)
        }
    }
    
    func deleteThread(indexPath: IndexPath) {
        let alert = UIAlertController(title: "Remove Thread", message: "Are you sure you want to remove this thread from your collection?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.tableView.deselectRow(at: indexPath, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            self.thread.removeFromCollection()
            AppDelegate.save()
            
            self.performSegue(withIdentifier: "DeleteThread", sender: nil)
        })
        
        present(alert, animated: true)
    }
}
