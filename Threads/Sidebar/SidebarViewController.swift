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
                self?.updateCell(project)
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
    
    func updateCell(_ project: Project) {
        let cell = cellForProject(project)
        cell?.textLabel?.text = project.name ?? Localized.unnamedProject
    }

    private func cellForProject(_ project: Project) -> UITableViewCell? {
        dataSource.indexPath(for: .project(project)).flatMap { tableView.cellForRow(at: $0) }
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
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard case let .project(project) = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: project.objectID, previewProvider: nil) { suggestedActions in
            UIMenu(title: "", children: [
                self.actionRunner.menuAction(AddProjectToShoppingListAction(project: project),
                                             image: UIImage(systemName: "cart.badge.plus")),
                self.actionRunner.menuAction(ShareProjectAction(project: project),
                                             title: Localized.share,
                                             image: UIImage(systemName: "square.and.arrow.up")),
                self.actionRunner.menuAction(DeleteProjectAction(project: project),
                                             title: Localized.delete,
                                             image: UIImage(systemName: "trash"),
                                             attributes: .destructive)
            ])
        }
    }
    
    func setSelection(_ selection: SidebarSelection) {
        let indexPath = dataSource.indexPath(for: selection)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
    }
    
    private var rootViewController: SplitViewController {
        splitViewController as! SplitViewController
    }
}

extension SidebarViewController {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if !super.canPerformAction(action, withSender: sender) {
            return false
        }
        
        switch action {
        case #selector(delete(_:)):
            if case .project = rootViewController.selection {
                return true
            }
            
            return false
        default:
            return true
        }
    }
    
    override func delete(_ sender: Any?) {
        guard case let .project(project) = rootViewController.selection else {
            return
        }
        
        guard let indexPath = dataSource.indexPath(for: .project(project)) else {
            return
        }
        
        let nextSelection: SidebarSelection
        if let selection = dataSource.itemIdentifier(for: IndexPath(row: indexPath.row + 1, section: indexPath.section)) {
            nextSelection = selection
        } else if let selection = dataSource.itemIdentifier(for: IndexPath(row: indexPath.row - 1, section: indexPath.section)) {
            nextSelection = selection
        } else {
            nextSelection = .collection
        }
        
        actionRunner.perform(DeleteProjectAction(project: project)) {
            self.rootViewController.selection = nextSelection
        }
    }
}

extension SidebarSelection: ReusableCell {
    var cellIdentifier: String {
        "Cell"
    }
}
