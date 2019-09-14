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
        
        tableView.register(CollectionThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
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
        undoManager?.setActionName(String.localizedStringWithFormat(Localized.addThreadUndoAction, threadCount))
        for thread in addViewController.selectedThreads {
            thread.addToCollection()
        }
        AppDelegate.save()
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
                self.undoManager?.setActionName(Localized.markOffBobbin)
                thread.onBobbin = false
                AppDelegate.save()
                completionHandler(true)
            }
        } else {
            bobbin = UIContextualAction(style: .normal, title: Localized.onBobbin) { action, view, completionHandler in
                self.undoManager?.setActionName(Localized.markOffBobbin)
                thread.onBobbin = true
                AppDelegate.save()
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
                thread.amountInCollection = 1
                AppDelegate.save()
                completionHandler(true)
            }
            stock.backgroundColor = UIColor(named: "InStockSwipe")
        } else {
            stock = UIContextualAction(style: .destructive, title: Localized.outOfStock) { action, view, completionHandler in
                thread.amountInCollection = 0
                thread.onBobbin = false
                AppDelegate.save()
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
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            self.storyboard!.instantiateViewController(identifier: "ThreadDetail") { coder in
                self.makeDetailController(coder: coder, sender: thread)
            }
        }) { suggestedActions in
            var markActions: [UIMenuElement] = []
            
            if thread.amountInCollection == 0 {
                markActions.append(UIAction(title: Localized.markInStock) { _ in
                    thread.amountInCollection = 1
                    AppDelegate.save()
                })
            } else {
                if thread.onBobbin {
                    markActions.append(UIAction(title: Localized.markOffBobbin) { _ in
                        thread.onBobbin = false
                        AppDelegate.save()
                    })
                } else {
                    markActions.append(UIAction(title: Localized.markOnBobbin) { _ in
                        thread.onBobbin = true
                        AppDelegate.save()
                    })
                }
                
                markActions.append(UIAction(title: Localized.markOutOfStock) { _ in
                    thread.amountInCollection = 0
                    thread.onBobbin = false
                    AppDelegate.save()
                })
            }
            
            return UIMenu(title: "", children: [
                UIAction(title: Localized.addToShoppingList,
                         image: UIImage(systemName: "cart.badge.plus"),
                         attributes: thread.inShoppingList ? .disabled : []) { _ in
                    thread.addToShoppingList()
                },
                UIMenu(title: "", options: .displayInline, children: markActions),
                UIAction(title: Localized.removeFromCollection, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    thread.removeFromCollection()
                    UserActivity.showThread(thread).delete {
                        AppDelegate.save()
                    }
                }
            ])
        }
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        let vc = animator.previewViewController!
        animator.addAnimations {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

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
