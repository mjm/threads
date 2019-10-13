//
//  SplitViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

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
    
    @objc func viewMyThreads(_ sender: Any) {
        selection = .collection
    }
    
    @objc func viewShoppingList(_ sender: Any) {
        selection = .shoppingList
    }
    
    @objc func showProject(_ sender: Any) {
        guard let project = sender as? Project else {
            preconditionFailure("Sender for showProject(_:) should be a Project")
        }
        
        selection = .project(project)
    }
    
    @objc func addThreads(_ sender: Any) {
        guard let currentController = detailViewController.selectedViewController else {
            return
        }
        
        let action = #selector(addThreads(_:))
        if currentController.canPerformAction(action, withSender: sender) {
            currentController.perform(action, with: sender)
        }
    }
    
    @objc func toggleEditingProject(_ sender: Any) {
        guard let controller = projectDetailViewController else {
            return
        }
        
        controller.setEditing(!controller.isEditing, animated: true)
    }
    
    @objc func shareProject(_ sender: Any) {
        guard let controller = projectDetailViewController else {
            return
        }
        
        controller.shareProject(sender)
    }
    
    @objc func addProjectToShoppingList(_ sender: Any) {
        guard let controller = projectDetailViewController else {
            return
        }
        
        controller.addProjectToShoppingList(sender)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard super.canPerformAction(action, withSender: sender) else {
            return false
        }

        switch action {
        case #selector(shareProject(_:)),
             #selector(addProjectToShoppingList(_:)):
            return projectDetailViewController != nil
        case #selector(addThreads(_:)):
            guard let currentController = detailViewController.selectedViewController else {
                return false
            }
            
            return currentController.canPerformAction(action, withSender: sender)
        default:
            return true
        }
    }
    
    override func validate(_ command: UICommand) {
        super.validate(command)
        
        switch command.action {
        case #selector(toggleEditingProject(_:)):
            if let controller = projectDetailViewController {
                command.title = controller.isEditing ? "Stop Editing" : "Edit"
                command.attributes = []
            } else {
                command.title = "Edit"
                command.attributes = .disabled
            }
        default:
            return
        }
    }
    
    var sidebarViewController: SidebarViewController {
        viewControllers[0] as! SidebarViewController
    }
    
    var detailViewController: DetailViewController {
        viewControllers[1] as! DetailViewController
    }
    
    var projectDetailViewController: ProjectDetailViewController? {
        if case .project = selection {
            return detailViewController.projectDetailViewController
        }
        
        return nil
    }
    
    func updateToolbar() {
        #if targetEnvironment(macCatalyst)
        guard let scene = view.window?.windowScene, let titlebar = scene.titlebar, let toolbar = titlebar.toolbar else {
            return
        }
        
        let currentState = toolbar.items.map { $0.itemIdentifier }
        var desiredState: [NSToolbarItem.Identifier] = [.addProject, .title, .flexibleSpace, .addThreads]
        if let projectController = projectDetailViewController {
            if projectController.isEditing {
                desiredState.append(contentsOf: [.doneEditing])
            } else {
                desiredState.append(contentsOf: [.edit, .share])
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
        #endif
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
}
