//
//  SidebarViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class SidebarViewController: TableViewController<SidebarViewController.Section, SidebarSelection> {
    enum Section: CaseIterable {
        case threads
        case projects
    }
    
    private var projectsList: FetchedObjectList<Project>!
    
    override func dataSourceWillInitialize() {
        dataSource.sectionTitle = { tableView, _, section in
            switch section {
            case .threads: return nil
            case .projects: return Localized.projects
            }
        }
        
        projectsList = FetchedObjectList(
            fetchRequest: Project.allProjectsFetchRequest(),
            managedObjectContext: managedObjectContext,
            updateSnapshot: { [weak self] in
                self?.updateSnapshot()
            },
            updateCell: { [weak self] project in
//                self?.updateCell(project)
            }
        )
    }
    
    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.collection, .shoppingList], toSection: .threads)
        snapshot.appendItems(projectsList.objects.map { .project($0) })
    }
    
    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        [
            "Cell": .class(UITableViewCell.self),
        ]
    }
    
    override func populate(cell: UITableViewCell, item: SidebarSelection) {
        switch item {
        case .collection:
            cell.imageView?.image = UIImage(systemName: "tray.full")
            cell.textLabel?.text = Localized.myThreads
        case .shoppingList:
            cell.imageView?.image = UIImage(systemName: "cart")
            cell.textLabel?.text = Localized.shoppingList
        case let .project(project):
            cell.imageView?.image = UIImage(systemName: "rectangle.3.offgrid.fill")
            cell.imageView?.tintColor = .systemGray
            cell.textLabel?.text = project.name ?? Localized.unnamedProject
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setSelection(rootViewController.selection)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        rootViewController.selection = item
    }
    
    func setSelection(_ selection: SidebarSelection) {
        let indexPath = dataSource.indexPath(for: selection)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
    }
    
    private var rootViewController: SplitViewController {
        splitViewController as! SplitViewController
    }
}

extension SidebarSelection: ReusableCell {
    var cellIdentifier: String {
        "Cell"
    }
}
