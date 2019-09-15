//
//  ShoppingListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: UITableViewController {
    enum Section: CaseIterable {
        case unpurchased
        case purchased
    }
    
    private var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Thread>!
    private var dataSource: UITableViewDiffableDataSource<Section, Thread>!
    
    private var purchaseDelayTimer: Timer?
    private var pendingPurchases = Set<Thread>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.inShoppingListFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        tableView.register(ShoppingListThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! ShoppingListThreadTableViewCell
            cell.populate(item)
            cell.onCheckTapped = {
                self.toggleThreadChecked(item)
            }
            cell.onIncreaseQuantity = {
                self.increaseQuantity(item)
            }
            cell.onDecreaseQuantity = {
                self.decreaseQuantity(item)
            }
            return cell
        }
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot(animated: false)
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
        
        userActivity = UserActivity.showShoppingList.userActivity
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
        // update the rows of the table
        let objects = fetchedResultsController.fetchedObjects ?? []
        var partitioned = objects
        let p = partitioned.stablePartition { $0.purchased && !pendingPurchases.contains($0) }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(Array(partitioned[..<p]), toSection: .unpurchased)
        snapshot.appendItems(Array(partitioned[p...]), toSection: .purchased)
        dataSource.apply(snapshot, animatingDifferences: animated)

        // animate in/out the "Add Checked to Collection" button
        let anyChecked = !objects.filter { $0.purchased }.isEmpty
        let header = self.tableView.tableHeaderView!
        let height = anyChecked
            ? header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            : 0.0
        
        let changeHeight = {
            header.frame.size.height = height
            header.isHidden = !anyChecked
            header.layoutIfNeeded()
        }

        if animated {
            let animator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 0.3, animations: changeHeight)
            animator.startAnimation()
        } else {
            changeHeight()
        }
        
        // update the tab bar badge
        let unpurchasedItems = objects.filter { !$0.purchased }.count
        navigationController!.tabBarItem.badgeValue = unpurchasedItems > 0 ? "\(unpurchasedItems)" : nil
    }

    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindAddThread(segue: UIStoryboardSegue) {
        let addViewController = segue.source as! AddThreadViewController
        
        let threadCount = addViewController.selectedThreads.count
        undoManager?.setActionName(String.localizedStringWithFormat(Localized.addThreadUndoAction, threadCount))
        
        for thread in addViewController.selectedThreads {
            thread.addToShoppingList()
        }
        AppDelegate.save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                // only choose from threads that aren't already in the shopping list
                let threads: [Thread]
                do {
                    let request = Thread.notInShoppingListFetchRequest()
                    threads = try managedObjectContext.fetch(request)
                } catch {
                    NSLog("Could not fetch threads to search from")
                    threads = []
                }
                
                addController.choices = threads
            }
        }
    }
}

// MARK: - Actions
extension ShoppingListViewController {
    @IBAction func addCheckedToCollection() {
        let request = Thread.purchasedFetchRequest()
        do {
            undoManager?.setActionName(Localized.addToCollection)
            let threads = try managedObjectContext.fetch(request)
            for thread in threads {
                thread.removeFromShoppingList()
                thread.addToCollection()
            }
            AppDelegate.save()
        } catch {
            NSLog("Could not load purchased threads: \(error)")
        }
    }
    
    func toggleThreadChecked(_ thread: Thread) {
        undoManager?.setActionName(Localized.changePurchased)
        thread.togglePurchased()
        delayPurchase(thread)
        AppDelegate.save()
    }
    
    func increaseQuantity(_ thread: Thread) {
        undoManager?.setActionName(Localized.changeQuantity)
        resetDelayedPurchaseTimer()
        thread.amountInShoppingList += 1
        AppDelegate.save()
    }
    
    func decreaseQuantity(_ thread: Thread) {
        resetDelayedPurchaseTimer()
        if thread.amountInShoppingList == 1 {
            undoManager?.setActionName(Localized.removeFromShoppingList)
            thread.removeFromShoppingList()
        } else {
            undoManager?.setActionName(Localized.changeQuantity)
            thread.amountInShoppingList -= 1
        }
        AppDelegate.save()
    }
}

// MARK: - Purchase Delay
extension ShoppingListViewController {
    private func delayPurchase(_ thread: Thread) {
        if thread.purchased {
            pendingPurchases.insert(thread)
        }

        resetDelayedPurchaseTimer()
    }

    private func resetDelayedPurchaseTimer() {
        // if we had a previous timer going, cancel so we don't produce too much UI churn
        if let existingTimer = purchaseDelayTimer {
            existingTimer.invalidate()
        }

        purchaseDelayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.pendingPurchases.removeAll()
            self.updateSnapshot()
            self.purchaseDelayTimer = nil
        }
    }
}

// MARK: - Fetched Results Controller Delegate
extension ShoppingListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            let thread = anObject as! Thread

            // we rearrange things in our snapshot, so the fetched results controller lies about the
            // actual index path of the row
            guard let indexPath = dataSource.indexPath(for: thread) else {
                return
            }

            if let cell = tableView.cellForRow(at: indexPath) as? ShoppingListThreadTableViewCell {
                cell.populate(thread)
            }
        default:
            break
        }
    }
}
