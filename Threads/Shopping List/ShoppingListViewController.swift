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
    
    private var threadsList: FetchedObjectList<Thread>!
    private var dataSource: UITableViewDiffableDataSource<Section, Thread>!
    private var actionRunner: UserActionRunner!
    
    private var purchaseDelayTimer: Timer?
    private var pendingPurchases = Set<Thread>()

    @IBOutlet var addCheckedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCheckedButton.imageView?.tintColor = .white

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)
        
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
        
        threadsList = FetchedObjectList(
            fetchRequest: Thread.inShoppingListFetchRequest(),
            managedObjectContext: managedObjectContext,
            updateSnapshot: { [weak self] in
                self?.updateSnapshot()
            },
            updateCell: { [weak self] thread in
                self?.updateCell(thread)
            }
        )

        updateSnapshot(animated: false)
        
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
        var partitioned = threadsList.objects
        let p = partitioned.stablePartition { $0.purchased && !pendingPurchases.contains($0) }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(Array(partitioned[..<p]), toSection: .unpurchased)
        snapshot.appendItems(Array(partitioned[p...]), toSection: .purchased)
        dataSource.apply(snapshot, animatingDifferences: animated)

        // animate in/out the "Add Checked to Collection" button
        let anyChecked = !threadsList.objects.filter { $0.purchased }.isEmpty
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
        let unpurchasedItems = threadsList.objects.filter { !$0.purchased }.count
        navigationController!.tabBarItem.badgeValue = unpurchasedItems > 0 ? "\(unpurchasedItems)" : nil
    }

    func updateCell(_ thread: Thread) {
        cellForThread(thread)?.populate(thread)
    }

    private func cellForThread(_ thread: Thread) -> ShoppingListThreadTableViewCell? {
        dataSource.indexPath(for: thread).flatMap { tableView.cellForRow(at: $0) as? ShoppingListThreadTableViewCell }
    }
}

// MARK: - Actions
extension ShoppingListViewController {
    @IBAction func addThread() {
        let request = Thread.notInShoppingListFetchRequest()
        guard let threads = try? managedObjectContext.fetch(request) else {
            NSLog("Could not fetch threads to search from")
            return
        }

        let action = AddThreadAction(choices: threads) { AddToShoppingListAction(threads: $0) }
        actionRunner.perform(action)
    }
    
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
