//
//  SplitViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData
import Combine

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
    
    @Published var selection: SidebarSelection = .collection
    private var toolbarSubscription: AnyCancellable?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        toolbarSubscription = $selection.sink { [weak self] selection in
            self?.updateToolbar(selection)
        }
    }
    
    @objc func addProject(_ sender: Any) {
        actionRunner.perform(CreateProjectAction()).ignoreError().handle { project in
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
    
    @objc func buyPremium(_ sender: Any) {
        actionRunner.perform(BuyPremiumAction())
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
    
    func updateToolbar(_ selection: SidebarSelection? = nil) {
        #if targetEnvironment(macCatalyst)
        guard let scene = view.window?.windowScene, let titlebar = scene.titlebar, let toolbar = titlebar.toolbar else {
            return
        }
        
        let selection = selection ?? self.selection
        
        var desiredState: [NSToolbarItem.Identifier] = [.addProject, .title, .flexibleSpace, .addThreads, .share]
        if selection == .shoppingList {
            desiredState.insert(.addCheckedToCollection, at: desiredState.index(desiredState.endIndex, offsetBy: -2))
        }
        if case .project = selection {
            if projectDetailViewController?.isEditing ?? false {
                desiredState.append(contentsOf: [.doneEditing])
            } else {
                desiredState.append(contentsOf: [.edit])
            }
        }
        
        toolbar.setItemIdentifiers(desiredState)
        
        if let titleIdentifier = toolbar.centeredItemIdentifier, let titleItem = toolbar.items.first(where: { $0.itemIdentifier == titleIdentifier }) {
            titleItem.title = selection.toolbarTitle
        }
        #endif
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
}

extension SplitViewController: UIActivityItemsConfigurationReading {
    var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
        if let project = projectDetailViewController?.project {
            return [project.itemProvider]
        }
        
        return []
    }
    
    // This method doesn't seem to *ever* get called, so I don't see a way to support custom app activities
    // for the toolbar or menu item. But this is how we would implement it if it did work, so maybe in some
    // update, it'll start working.
    var applicationActivitiesForActivityItemsConfiguration: [UIActivity]? {
        [OpenInSafariActivity()]
    }
}

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
    static let addProject = NSToolbarItem.Identifier("addProject")
    static let title = NSToolbarItem.Identifier("title")
    static let addThreads = NSToolbarItem.Identifier("addThreads")
    static let edit = NSToolbarItem.Identifier("edit")
    static let doneEditing = NSToolbarItem.Identifier("doneEditing")
    static let share = NSToolbarItem.Identifier("share")
    static let addCheckedToCollection = NSToolbarItem.Identifier("addCheckedToCollection")
}

extension SplitViewController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title, .flexibleSpace, .addThreads, .share]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title, .addThreads, .edit, .doneEditing, .share, .addCheckedToCollection]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .addProject:
            let item = NSToolbarItem(itemIdentifier: .addProject)
            item.toolTip = "Create a new project"
            item.image = UIImage(systemName: "rectangle.stack.badge.plus")
            item.isBordered = true
            item.action = #selector(addProject(_:))
            return item
        case .title:
            let item = NSToolbarItem(itemIdentifier: .title)
            item.title = "Threads"
            return item
        case .addThreads:
            let item = NSToolbarItem(itemIdentifier: .addThreads)
            item.toolTip = "Add threads"
            item.image = UIImage(systemName: "plus")
            item.isBordered = true
            item.action = #selector(addThreads(_:))
            return item
        case .edit:
            let item = NSToolbarItem(itemIdentifier: .edit)
            item.toolTip = "Edit this project"
            item.image = UIImage(systemName: "pencil")
            item.isBordered = true
            item.action = #selector(toggleEditingProject(_:))
            return item
        case .doneEditing:
            let item = NSToolbarItem(itemIdentifier: .doneEditing)
            item.toolTip = "Stop editing this project"
            item.title = "Done"
            item.isBordered = true
            item.action = #selector(toggleEditingProject(_:))
            return item
        case .share:
            let item = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
            item.toolTip = "Publish and share this project"
            item.activityItemsConfiguration = self
            return item
        case .addCheckedToCollection:
            let item = NSToolbarItem(itemIdentifier: .addCheckedToCollection)
            item.toolTip = "Add all checked threads to My Threads"
            item.image = UIImage(systemName: "tray.and.arrow.down")
            item.isBordered = true
            item.action = #selector(ShoppingListViewController.addCheckedToCollection(_:))
            return item
        default:
            fatalError("unexpected toolbar item identifier \(itemIdentifier)")
        }
    }
}

extension NSToolbar {
    func setItemIdentifiers(_ identifiers: [NSToolbarItem.Identifier]) {
        let currentIdentifiers = items.map { $0.itemIdentifier }
        
        for change in identifiers.difference(from: currentIdentifiers) {
            switch change {
            case let .insert(offset: i, element: element, associatedWith: _):
                insertItem(withItemIdentifier: element, at: i)
            case let .remove(offset: i, element: _, associatedWith: _):
                removeItem(at: i)
            }
        }
    }
}

#endif
