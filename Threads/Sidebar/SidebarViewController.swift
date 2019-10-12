//
//  SidebarViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class SidebarViewController: TableViewController<SidebarViewController.Section, SidebarViewController.Cell> {
    enum Section: CaseIterable {
        case threads
        case projects
    }
    
    enum Cell: ReusableCell {
        case collection
        case shoppingList
        case project(Project)
        
        var cellIdentifier: String {
            "Cell"
        }
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
    
    override func populate(cell: UITableViewCell, item: SidebarViewController.Cell) {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        switch item {
        case .collection:
            performSegue(withIdentifier: "ShowMyThreads", sender: nil)
        case .shoppingList:
            performSegue(withIdentifier: "ShowShoppingList", sender: nil)
        case let .project(project):
            performSegue(withIdentifier: "ShowProject", sender: project)
        }
    }
    
    @IBSegueAction func makeProjectDetailController(coder: NSCoder, sender: Project) -> UIViewController? {
        ProjectDetailViewController(coder: coder, project: sender)
    }
}
