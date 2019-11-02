//
//  SplitViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

class SplitViewController: UISplitViewController {
    let viewModel: SplitViewModel

    required init?(coder: NSCoder) {
        viewModel = SplitViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        primaryBackgroundStyle = .sidebar

        viewModel.presenter = self

        viewModel.bind(to: sidebarViewController.viewModel)
        viewModel.bind(to: detailViewController.viewModel)
    }

    private var toolbarSubscriptions = Set<AnyCancellable>()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if targetEnvironment(macCatalyst)
        toolbarSubscriptions.removeAll()

        viewModel.toolbarViewModel.items.sink { [weak self] items in
            self?.updateToolbarItems(items)
        }.store(in: &toolbarSubscriptions)

        viewModel.toolbarViewModel.$title.sink { [weak self] title in
            self?.updateToolbarTitle(title)
        }.store(in: &toolbarSubscriptions)
        #endif
    }

    @objc func addProject(_ sender: Any) {
        viewModel.addProject()
    }

    @objc func viewMyThreads(_ sender: Any) {
        viewModel.selection = .collection
    }

    @objc func viewShoppingList(_ sender: Any) {
        viewModel.selection = .shoppingList
    }

    @objc func buyPremium(_ sender: Any) {
        viewModel.buyPremium()
    }

    var sidebarViewController: SidebarViewController! {
        guard viewControllers.count >= 1 else { return nil }
        return viewControllers[0] as? SidebarViewController
    }

    var detailViewController: DetailViewController! {
        guard viewControllers.count >= 2 else { return nil }
        return viewControllers[1] as? DetailViewController
    }

    var projectDetailViewController: ProjectDetailViewController? {
        if case .project = viewModel.selection {
            return detailViewController?.projectDetailViewController
        }

        return nil
    }

    #if targetEnvironment(macCatalyst)
    private var toolbar: NSToolbar? {
        view.window?.windowScene?.titlebar?.toolbar
    }

    private func updateToolbarItems(_ items: [NSToolbarItem.Identifier]) {
        guard let toolbar = toolbar else {
            return
        }

        toolbar.setItemIdentifiers(items)
    }

    private func updateToolbarTitle(_ title: String) {
        guard let toolbar = toolbar else {
            return
        }

        if let titleIdentifier = toolbar.centeredItemIdentifier,
            let titleItem = toolbar.items.first(where: { $0.itemIdentifier == titleIdentifier })
        {
            titleItem.title = title
        }
    }
    #endif
}

extension SplitViewController: UIActivityItemsConfigurationReading {
    var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
        if let project = projectDetailViewController?.viewModel.project {
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

extension SplitViewController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title, .flexibleSpace, .addThreads, .share]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title, .addThreads, .edit, .doneEditing, .share, .addCheckedToCollection]
    }

    func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
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
            item.action = #selector(MyThreadsViewController.addThreads(_:))
            return item
        case .edit:
            let item = NSToolbarItem(itemIdentifier: .edit)
            item.toolTip = "Edit this project"
            item.image = UIImage(systemName: "pencil")
            item.isBordered = true
            item.action = #selector(ProjectDetailViewController.toggleEditingProject(_:))
            return item
        case .doneEditing:
            let item = NSToolbarItem(itemIdentifier: .doneEditing)
            item.toolTip = "Stop editing this project"
            item.title = "Done"
            item.isBordered = true
            item.action = #selector(ProjectDetailViewController.toggleEditingProject(_:))
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
