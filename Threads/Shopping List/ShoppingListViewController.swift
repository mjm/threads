//
//  ShoppingListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: TableViewController<ShoppingListViewController.Section, ShoppingListViewController.Cell> {
    enum Section: CaseIterable {
        case unpurchased
        case purchased
    }

    enum Cell: ReusableCell {
        case thread(Thread)

        var cellIdentifier: String { "Thread" }
    }
    
    private var threadsList: FetchedObjectList<Thread>!
    
    private var purchaseDelayTimer: Timer?
    private var pendingPurchases = Set<Thread>()

    @IBOutlet var addCheckedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCheckedButton.imageView?.tintColor = .white
    }

    override var currentUserActivity: UserActivity? { .showShoppingList }

    override func dataSourceWillInitialize() {
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
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        var partitioned = threadsList.objects
        let p = partitioned.stablePartition { $0.purchased && !pendingPurchases.contains($0) }

        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(partitioned[..<p].map { .thread($0) }, toSection: .unpurchased)
        snapshot.appendItems(partitioned[p...].map { .thread($0) }, toSection: .purchased)
    }
    
    override func dataSourceDidUpdateSnapshot(animated: Bool) {
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

    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        ["Thread": .nib(ShoppingListThreadTableViewCell.self)]
    }

    override func populate(cell: UITableViewCell, item: ShoppingListViewController.Cell) {
        switch item {
        case let .thread(thread):
            let cell = cell as! ShoppingListThreadTableViewCell
            cell.populate(thread)
            cell.onCheckTapped = { [weak self] in
                self?.actionRunner.perform(TogglePurchasedAction(thread: thread), willPerform: {
                    self?.delayPurchase(thread)
                })
            }
            cell.onIncreaseQuantity = { [weak self] in
                self?.actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .increment), willPerform: {
                    self?.resetDelayedPurchaseTimer()
                })
            }
            cell.onDecreaseQuantity = { [weak self] in
                self?.actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .decrement), willPerform: {
                    self?.resetDelayedPurchaseTimer()
                })
            }
        }
    }

    func updateCell(_ thread: Thread) {
        cellForThread(thread)?.populate(thread)
    }

    private func cellForThread(_ thread: Thread) -> ShoppingListThreadTableViewCell? {
        dataSource.indexPath(for: .thread(thread)).flatMap { tableView.cellForRow(at: $0) as? ShoppingListThreadTableViewCell }
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
