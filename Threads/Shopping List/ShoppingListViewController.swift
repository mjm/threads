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
        
        #if targetEnvironment(macCatalyst)
        tableView.tableHeaderView = nil
        #endif
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
        #if !targetEnvironment(macCatalyst)
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
        #endif
        
        // update the tab bar badge
        let unpurchasedItems = threadsList.objects.filter { !$0.purchased }.count
        navigationController?.tabBarItem.badgeValue = unpurchasedItems > 0 ? "\(unpurchasedItems)" : nil

        if threadsList.objects.isEmpty {
            let emptyView = EmptyView()
            emptyView.textLabel.text = Localized.emptyShoppingList
            emptyView.iconView.image = UIImage(named: "Bobbin")
            tableView.backgroundView = emptyView

            NSLayoutConstraint.activate([
                emptyView.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor),
                emptyView.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor),
                emptyView.topAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.topAnchor),
                emptyView.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor),
            ])

            tableView.tableFooterView = UIView() // hides the empty cell separators
        } else {
            if tableView.backgroundView != nil {
                tableView.backgroundView = nil
            }
            if tableView.tableFooterView != nil {
                tableView.tableFooterView = nil
            }
        }
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
    @IBAction func addThreads(_ sender: Any) {
        actionRunner.perform(AddThreadAction(mode: .shoppingList))
    }
    
    @IBAction func addCheckedToCollection(_ sender: Any) {
        actionRunner.perform(AddPurchasedToCollectionAction())
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if !super.canPerformAction(action, withSender: sender) {
            return false
        }
        
        switch action {
        case #selector(addCheckedToCollection(_:)):
            return !threadsList.objects.filter { $0.purchased }.isEmpty
        default:
            return true
        }
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

class AddThreadsToShoppingListDelegate: NSObject, AddThreadViewControllerDelegate {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func choicesForAddingThreads(_ addThreadViewController: AddThreadViewController) -> [Thread] {
        let request = Thread.notInShoppingListFetchRequest()
        guard let threads = try? context.fetch(request) else {
            NSLog("Could not fetch threads to search from")
            return []
        }
        
        return threads
    }
    
    func addThreadViewController(_ addThreadViewController: AddThreadViewController, performActionForAddingThreads threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToShoppingListAction(threads: threads))
    }
}
