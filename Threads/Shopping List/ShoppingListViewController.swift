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
    private var actionRunner: UserActionRunner!
    
    private var purchaseDelayTimer: Timer?
    private var pendingPurchases = Set<Thread>()

    @IBOutlet var addCheckedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCheckedButton.imageView?.tintColor = .white

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.inShoppingListFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        ShoppingListThreadTableViewCell.registerNib(on: tableView, reuseIdentifier: "Thread")
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! ShoppingListThreadTableViewCell
            cell.populate(item)
            cell.onCheckTapped = {
                self.actionRunner.perform(TogglePurchasedAction(thread: item), willPerform: { [weak self] in
                    self?.delayPurchase(item)
                })
            }
            cell.onIncreaseQuantity = {
                self.actionRunner.perform(ChangeShoppingListAmountAction(thread: item, change: .increment), willPerform: { [weak self] in
                    self?.resetDelayedPurchaseTimer()
                })
            }
            cell.onDecreaseQuantity = {
                self.actionRunner.perform(ChangeShoppingListAmountAction(thread: item, change: .decrement), willPerform: { [weak self] in
                    self?.resetDelayedPurchaseTimer()
                })
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
            let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.3, animations: changeHeight)
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

        let action = AddToShoppingListAction(threads: addViewController.selectedThreads)
        actionRunner.perform(action)
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
        actionRunner.perform(AddPurchasedToCollectionAction())
    }
}

// MARK: - Purchase Delay
extension ShoppingListViewController {
    private func delayPurchase(_ thread: Thread) {
        // Delaying will happen before `purchased` is toggled, so we're checking the start state, not the end state.
        if !thread.purchased {
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
