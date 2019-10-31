//
//  ShoppingListViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class ShoppingListViewModel: ViewModel {
    enum Section {
        case unpurchased
        case purchased
    }

    typealias Item = ShoppingListCellViewModel

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let threadsList: FetchedObjectList<Thread>

    @Published private(set) var threadViewModels: [Item] = []
    @Published var selectedItem: Item?
    @Published private var pendingPurchases = Set<Thread>()
    @Published private(set) var willRemoveSelectedOnDecrement = false

    private let pendingPurchaseTick = PassthroughSubject<(), Never>()

    override init(context: NSManagedObjectContext = .view) {
        threadsList
            = FetchedObjectList(
                fetchRequest: Thread.inShoppingListFetchRequest(), managedObjectContext: context)

        super.init(context: context)

        $threadViewModels.applyingDifferences(threadsList.differences) { thread in
            let model = ShoppingListCellViewModel(thread: thread)
            model.actions.sink { [weak self] action in
                self?.handleAction(action, for: thread)
            }.store(in: &model.cancellables)
            return model
        }.assign(to: \.threadViewModels, on: self).store(in: &cancellables)

        resetPendingPurchases.assign(to: \.pendingPurchases, on: self).store(in: &cancellables)

        $selectedItem.flatMap { itemModel -> AnyPublisher<Bool, Never> in
            itemModel?.willRemoveOnDecrement ?? Just(false).eraseToAnyPublisher()
        }.assign(to: \.willRemoveSelectedOnDecrement, on: self).store(in: &cancellables)
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        partitionedItems.map { (unpurchased, purchased) in
            var snapshot = Snapshot()

            snapshot.appendSections([.unpurchased, .purchased])
            snapshot.appendItems(unpurchased, toSection: .unpurchased)
            snapshot.appendItems(purchased, toSection: .purchased)

            return snapshot
        }.eraseToAnyPublisher()
    }

    private var partitionedItems: AnyPublisher<([Item], [Item]), Never> {
        $threadViewModels.combineLatest($pendingPurchases) {
            items, pendingPurchases in
            var partitioned = items
            let pivot = partitioned.stablePartition {
                $0.thread.purchased && !pendingPurchases.contains($0.thread)
            }

            let unpurchased = Array(partitioned[..<pivot])
            let purchased = Array(partitioned[pivot...])
            return (unpurchased, purchased)
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        $threadViewModels.map { $0.isEmpty }.eraseToAnyPublisher()
    }

    var canAddPurchasedToCollection: AnyPublisher<Bool, Never> {
        $threadViewModels.map { models in
            !models.filter { $0.thread.purchased }.isEmpty
        }.eraseToAnyPublisher()
    }

    var unpurchasedCount: AnyPublisher<Int, Never> {
        $threadViewModels.map { models in
            models.filter { !$0.thread.purchased }.count
        }.eraseToAnyPublisher()
    }

    var userActivity: AnyPublisher<UserActivity, Never> {
        Just(.showShoppingList).eraseToAnyPublisher()
    }

    var selectedThread: Thread? {
        selectedItem.flatMap { $0.thread }
    }

    func addThreads() {
        actionRunner.perform(AddThreadAction(mode: .shoppingList))
    }

    func addPurchasedThreadsToCollection() {
        actionRunner.perform(AddPurchasedToCollectionAction())
    }

    var canTogglePurchasedSelected: Bool { selectedThread != nil }

    func togglePurchasedSelected(immediate: Bool = false) {
        if let thread = selectedThread {
            togglePurchased(thread, immediate: immediate)
        }
    }

    var canIncrementQuantityOfSelected: Bool { selectedThread != nil }

    func incrementQuantityOfSelected() {
        if let thread = selectedThread {
            incrementQuantity(thread)
        }
    }

    var canDecrementQuantityOfSelected: Bool { selectedThread != nil }

    func decrementQuantityOfSelected() {
        if let thread = selectedThread {
            decrementQuantity(thread)
        }
    }

    var canRemoveSelected: Bool { selectedThread != nil }

    func removeSelected() {
        if let thread = selectedThread {
            actionRunner.perform(RemoveFromShoppingListAction(thread: thread))
        }
    }

    private var resetPendingPurchases: AnyPublisher<Set<Thread>, Never> {
        let toggleTicks = $pendingPurchases.filter { !$0.isEmpty }.map { _ -> Set<Thread> in [] }
        let quantityTicks = pendingPurchaseTick.map { _ -> Set<Thread> in [] }

        let allTicks = toggleTicks.merge(with: quantityTicks)
        return allTicks.debounce(for: 3.0, scheduler: RunLoop.main).eraseToAnyPublisher()
    }

    private func handleAction(_ action: ShoppingListCellViewModel.Action, for thread: Thread) {
        switch action {
        case .togglePurchased:
            togglePurchased(thread)
        case .increment:
            incrementQuantity(thread)
        case .decrement:
            decrementQuantity(thread)
        }
    }

    private func togglePurchased(_ thread: Thread, immediate: Bool = false) {
        let willPerform = immediate ? {} : { self.pendingPurchases.insert(thread) }

        actionRunner.perform(TogglePurchasedAction(thread: thread), willPerform: willPerform)
    }

    private func incrementQuantity(_ thread: Thread) {
        actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .increment)) {
            self.pendingPurchaseTick.send()
        }
    }

    private func decrementQuantity(_ thread: Thread) {
        actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .decrement)) {
            self.pendingPurchaseTick.send()
        }
    }
}

class AddThreadsToShoppingListMode: AddThreadMode {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addThreadChoices() throws -> [Thread] {
        let request = Thread.notInShoppingListFetchRequest()
        return try context.fetch(request)
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToShoppingListAction(threads: threads))
    }
}
