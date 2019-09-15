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

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let threadCount = addViewController.selectedThreads.count
        let name = String.localizedStringWithFormat(Localized.addThreadUndoAction, threadCount)
        
        managedObjectContext.act(name) {
            for thread in addViewController.selectedThreads {
                thread.addToCollection()
            }
        }
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

// MARK: - Actions
extension MyThreadsViewController {
    func markOffBobbin(_ thread: Thread) {
        thread.act(Localized.markOffBobbin) {
            thread.onBobbin = false
        }
    }
    
    func markOnBobbin(_ thread: Thread) {
        thread.act(Localized.markOnBobbin) {
            thread.onBobbin = true
        }
    }
    
    func markInStock(_ thread: Thread) {
        thread.act(Localized.markInStock) {
            thread.amountInCollection = 1
        }
    }
    
    func markOutOfStock(_ thread: Thread) {
        thread.act(Localized.markOutOfStock) {
            thread.amountInCollection = 0
            thread.onBobbin = false
        }
    }
    
    func addToShoppingList(_ thread: Thread) {
        thread.act(Localized.addToShoppingList) {
            thread.addToShoppingList()
        }
    }
    
    func removeFromCollection(_ thread: Thread) {
        UserActivity.showThread(thread).delete {
            thread.act(Localized.removeThread) {
                thread.removeFromCollection()
            }
        }
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
            bobbin = UIContextualAction(style: .normal, title: Localized.offBobbin) { action, view, completionHandler in
                self.markOffBobbin(thread)
                completionHandler(true)
            }
        } else {
            bobbin = UIContextualAction(style: .normal, title: Localized.onBobbin) { action, view, completionHandler in
                self.markOnBobbin(thread)
                completionHandler(true)
            }
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
            stock = UIContextualAction(style: .normal, title: Localized.inStock) { action, view, completionHandler in
                self.markInStock(thread)
                completionHandler(true)
            }
            stock.backgroundColor = UIColor(named: "InStockSwipe")
        } else {
            stock = UIContextualAction(style: .destructive, title: Localized.outOfStock) { action, view, completionHandler in
                self.markOutOfStock(thread)
                completionHandler(true)
            }
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
                markActions.append(UIAction(title: Localized.markInStock) { _ in
                    self.markInStock(thread)
                })
            } else {
                if thread.onBobbin {
                    markActions.append(UIAction(title: Localized.markOffBobbin) { _ in
                        self.markOffBobbin(thread)
                    })
                } else {
                    markActions.append(UIAction(title: Localized.markOnBobbin) { _ in
                        self.markOnBobbin(thread)
                    })
                }
                
                markActions.append(UIAction(title: Localized.markOutOfStock) { _ in
                    self.markOutOfStock(thread)
                })
            }
            
            return UIMenu(title: "", children: [
                UIAction(title: Localized.addToShoppingList,
                         image: UIImage(systemName: "cart.badge.plus"),
                         attributes: thread.inShoppingList ? .disabled : [])
                { _ in
                    self.addToShoppingList(thread)
                },
                UIMenu(title: "", options: .displayInline, children: markActions),
                UIAction(title: Localized.removeFromCollection, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self.removeFromCollection(thread)
                }
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
