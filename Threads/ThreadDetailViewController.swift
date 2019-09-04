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
    }
    
    enum Cell {
        case label
        case collection
        case bobbin
        case colorBar
        
        var cellIdentifier: String {
            switch self {
            case .label: return "Label"
            case .collection, .bobbin: return "Status"
            case .colorBar: return "ColorBar"
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
        
        updateSnapshot()
    }
    
    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.label, .collection, .bobbin, .colorBar], toSection: .details)
        dataSource.apply(snapshot)
    }
}
