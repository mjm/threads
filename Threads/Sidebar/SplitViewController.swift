//
//  SplitViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

enum SidebarSelection: Hashable {
    case collection
    case shoppingList
    case project(Project)
    
    var toolbarTitle: String {
        switch self {
        case .collection: return "My Threads"
        case .shoppingList: return "Shopping List"
        case let .project(project): return project.name ?? Localized.unnamedProject
        }
    }
}

class SplitViewController: UISplitViewController {
    private var actionRunner: UserActionRunner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)
        
        primaryBackgroundStyle = .sidebar
    }
    
    var selection: SidebarSelection = .collection {
        didSet {
            sidebarViewController.setSelection(selection)
            detailViewController.setSelection(selection)
            updateToolbar()
        }
    }
    
    @objc func addProject(_ sender: Any) {
        actionRunner.perform(CreateProjectAction()) { project in
            self.showProject(project)
        }
    }
    
    @objc func showProject(_ sender: Any) {
        guard let project = sender as? Project else {
            preconditionFailure("Sender for showProject(_:) should be a Project")
        }
        
        selection = .project(project)
    }
    
    var sidebarViewController: SidebarViewController {
        viewControllers[0] as! SidebarViewController
    }
    
    var detailViewController: DetailViewController {
        viewControllers[1] as! DetailViewController
    }
    
    func updateToolbar() {
        guard let scene = view.window?.windowScene, let titlebar = scene.titlebar, let toolbar = titlebar.toolbar else {
            return
        }
        
        let currentState = toolbar.items.map { $0.itemIdentifier }
        var desiredState: [NSToolbarItem.Identifier] = [.addProject, .title]
        if case .project = selection {
            if detailViewController.projectDetailViewController!.isEditing {
                desiredState.append(contentsOf: [.flexibleSpace, .doneEditing])
            } else {
                desiredState.append(contentsOf: [.flexibleSpace, .edit])
            }
        }
        
        for change in desiredState.difference(from: currentState) {
            switch change {
            case let .insert(offset: i, element: element, associatedWith: _):
                toolbar.insertItem(withItemIdentifier: element, at: i)
            case let .remove(offset: i, element: _, associatedWith: _):
                toolbar.removeItem(at: i)
            }
        }
        
        if let titleIdentifier = toolbar.centeredItemIdentifier, let titleItem = toolbar.items.first(where: { $0.itemIdentifier == titleIdentifier }) {
            titleItem.title = selection.toolbarTitle
        }
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
}
