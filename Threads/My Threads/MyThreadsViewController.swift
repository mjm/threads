//
//  MyThreadsViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class MyThreadsViewController: UITableViewController {
    
    enum Section {
        case threads
    }
    
    private var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Thread>!
    private var dataSource: TableViewDiffableDataSource<Section, Thread>!

    private var actionRunner: UserActionRunner!

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.inCollectionFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        CollectionThreadTableViewCell.registerNib(on: tableView, reuseIdentifier: "Thread")
        dataSource = TableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! CollectionThreadTableViewCell
            cell.populate(item)
            return cell
        }
        
        dataSource.canEditRow = { _, _, _ in true }
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot(animated: false)
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
        
        userActivity = UserActivity.showMyThreads.userActivity
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }

    override var undoManager: UndoManager? {
        managedObjectContext.undoManager
    }
    
    func updateSnapshot(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections([.threads])
        let objects = fetchedResultsController.fetchedObjects ?? []
        NSLog("updating snapshot with objects: \(objects)")
        snapshot.appendItems(objects, toSection: .threads)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindAddThread(segue: UIStoryboardSegue) {
        let addViewController = segue.source as! AddThreadViewController

        let action = AddToCollectionAction(threads: addViewController.selectedThreads)
        actionRunner.perform(action)
    }
    
    @IBAction func unwindDeleteThread(segue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                // only choose from threads that aren't already in the collection
                let threads: [Thread]
                do {
                    let request = Thread.notInCollectionFetchRequest()
                    threads = try managedObjectContext.fetch(request)
                } catch {
                    NSLog("Could not fetch threads to search from")
                    threads = []
                }
                
                addController.choices = threads
            }
        }
    }
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: Thread) -> ThreadDetailViewController? {
        return ThreadDetailViewController(coder: coder, thread: sender)
    }
    
    func showDetail(for thread: Thread) {
        performSegue(withIdentifier: "ThreadDetail", sender: thread)
    }
}

// MARK: - Table View Delegate
extension MyThreadsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let thread = dataSource.itemIdentifier(for: indexPath)!
        showDetail(for: thread)
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let thread = self.fetchedResultsController.object(at: indexPath)
        if thread.amountInCollection == 0 {
            return nil
        }

        let bobbin: UIContextualAction
        if thread.onBobbin {
            bobbin = actionRunner.contextualAction(MarkOffBobbinAction(thread: thread), title: Localized.offBobbin)
        } else {
            bobbin = actionRunner.contextualAction(MarkOnBobbinAction(thread: thread), title: Localized.onBobbin)
        }
        bobbin.backgroundColor = UIColor(named: "BobbinSwipe")
        
        let config = UISwipeActionsConfiguration(actions: [bobbin])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let thread = self.fetchedResultsController.object(at: indexPath)
        
        let stock: UIContextualAction
        if thread.amountInCollection == 0 {
            stock = actionRunner.contextualAction(MarkInStockAction(thread: thread), title: Localized.inStock)
            stock.backgroundColor = UIColor(named: "InStockSwipe")
        } else {
            stock = actionRunner.contextualAction(MarkOutOfStockAction(thread: thread), title: Localized.outOfStock, style: .destructive)
        }
        
        let config = UISwipeActionsConfiguration(actions: [stock])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let thread = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: thread.objectID, previewProvider: {
            self.storyboard!.instantiateViewController(identifier: "ThreadPreview") { coder in
                ThreadPreviewViewController(coder: coder, thread: thread)
            }
        }) { suggestedActions in
            var markActions: [UIMenuElement] = []
            
            if thread.amountInCollection == 0 {
                markActions.append(self.actionRunner.menuAction(MarkInStockAction(thread: thread)))
            } else {
                if thread.onBobbin {
                    markActions.append(self.actionRunner.menuAction(MarkOffBobbinAction(thread: thread)))
                } else {
                    markActions.append(self.actionRunner.menuAction(MarkOnBobbinAction(thread: thread)))
                }

                markActions.append(self.actionRunner.menuAction(MarkOutOfStockAction(thread: thread)))
            }
            let markMenu = UIMenu(title: "", options: .displayInline, children: markActions)

            // Load projects for submenu
            let addToProjectMenu: UIMenuElement
            do {
                let request = Project.allProjectsFetchRequest()
                let projects = try self.managedObjectContext.fetch(request)
                addToProjectMenu = UIMenu(title: Localized.addToProjectMenu, image: UIImage(systemName: "rectangle.3.offgrid"), children: projects.map { project in
                    let action = AddToProjectAction(thread: thread, project: project)
                    return self.actionRunner.menuAction(action,
                                                        title: project.name ?? Localized.unnamedProject,
                                                        state: action.canPerform ? .off : .on)
                })
            } catch {
                NSLog("Error fetching projects for context menu: \(error)")
                addToProjectMenu = UIAction(title: Localized.addToProjectMenu, image: UIImage(systemName: "rectangle.3.offgrid"), attributes: .disabled) { _ in }
            }
            
            return UIMenu(title: "", children: [
                self.actionRunner.menuAction(AddToShoppingListAction(thread: thread),
                                             image: UIImage(systemName: "cart.badge.plus")),
                addToProjectMenu,
                markMenu,
                self.actionRunner.menuAction(RemoveThreadAction(thread: thread),
                                             title: Localized.removeFromCollection,
                                             image: UIImage(systemName: "trash"),
                                             attributes: .destructive)
            ])
        }
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        let thread = managedObjectContext.object(with: configuration.identifier as! NSManagedObjectID) as! Thread
        animator.addAnimations {
            self.showDetail(for: thread)
        }
    }
}

// MARK: - Fetched Results Controller Delegate
extension MyThreadsViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            let thread = anObject as! Thread
            if let cell = tableView.cellForRow(at: indexPath!) as? CollectionThreadTableViewCell {
                cell.populate(thread)
            }
        default:
            break
        }
    }
}
