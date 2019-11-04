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

final class ShoppingListViewModel: ViewModel, SnapshotViewModel {
    enum Section: CaseIterable {
        case unpurchased
        case purchased
    }

    typealias Item = ShoppingListCellViewModel

    @Published private(set) var threadViewModels: [Item] = []
    @Published var selection: Item?
    @Published private var pendingPurchases = Set<Thread>()
    @Published private(set) var willRemoveSelectedOnDecrement = false

    private let pendingPurchaseTick = PassthroughSubject<(), Never>()
    private let purchaseChanged = CurrentValueSubject<(), Never>(())

    private let purchaseDelay: TimeInterval

    init(context: NSManagedObjectContext = .view, purchaseDelay: TimeInterval = 3.0) {
        self.purchaseDelay = purchaseDelay
        super.init(context: context)

        let actionRunner = self.actionRunner
        let purchaseChanged = self.purchaseChanged
        $threadViewModels.applyingChanges(threadChanges.ignoreError()) { [weak self] thread in
            let model = ShoppingListCellViewModel(thread: thread, actionRunner: actionRunner)

            model.actions.sink { [weak self] action in
                self?.handleAction(action, for: thread)
            }.store(in: &model.cancellables)

            model.isPurchased.map { _ in }.subscribe(purchaseChanged).store(in: &model.cancellables)

            return model
        }.assignWeakly(to: \.threadViewModels, on: self).store(in: &cancellables)

        resetPendingPurchases.assignWeakly(to: \.pendingPurchases, on: self).store(
            in: &cancellables)

        $selection.flatMap { itemModel -> AnyPublisher<Bool, Never> in
            itemModel?.willRemoveOnDecrement ?? Just(false).eraseToAnyPublisher()
        }.assignWeakly(to: \.willRemoveSelectedOnDecrement, on: self).store(in: &cancellables)
    }

    var threadChanges: ManagedObjectChangesPublisher<Thread> {
        context.changesPublisher(for: Thread.inShoppingListFetchRequest())
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        sectionedItems.map { itemsBySection in
            var snapshot = Snapshot()

            for section in Section.allCases {
                if let items = itemsBySection[section] {
                    snapshot.appendSections([section])
                    snapshot.appendItems(items, toSection: section)
                }
            }

            return snapshot
        }.eraseToAnyPublisher()
    }

    private var sectionedItems: AnyPublisher<[Section: [Item]], Never> {
        $threadViewModels.combineLatest($pendingPurchases, purchaseChanged) {
            items, pendingPurchases, _ in

            Dictionary(grouping: items) { item in
                if item.thread.purchased && !pendingPurchases.contains(item.thread) {
                    return .purchased
                } else {
                    return .unpurchased
                }
            }
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        $threadViewModels.map { $0.isEmpty }.eraseToAnyPublisher()
    }

    var canAddPurchasedToCollection: AnyPublisher<Bool, Never> {
        $threadViewModels.combineLatest(purchaseChanged).map { models, _ in
            !models.filter { $0.thread.purchased }.isEmpty
        }.eraseToAnyPublisher()
    }

    var unpurchasedCount: AnyPublisher<Int, Never> {
        $threadViewModels.combineLatest(purchaseChanged).map { models, _ in
            models.filter { !$0.thread.purchased }.count
        }.eraseToAnyPublisher()
    }

    var userActivity: AnyPublisher<UserActivity, Never> {
        Just(.showShoppingList).eraseToAnyPublisher()
    }

    var selectedThread: Thread? {
        selection.flatMap { $0.thread }
    }

    func addThreads() {
        actionRunner.perform(Thread.addToShoppingListAction)
    }

    func addPurchasedThreadsToCollection() {
        actionRunner.perform(AddPurchasedToCollectionAction())
    }

    private var resetPendingPurchases: AnyPublisher<Set<Thread>, Never> {
        let toggleTicks = $pendingPurchases.filter { !$0.isEmpty }.map { _ -> Set<Thread> in [] }
        let quantityTicks = pendingPurchaseTick.map { _ -> Set<Thread> in [] }

        let allTicks = toggleTicks.merge(with: quantityTicks)
        return allTicks.debounce(for: .init(purchaseDelay), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private func handleAction(_ action: ShoppingListCellViewModel.Action, for thread: Thread) {
        switch action {
        case .togglePurchased(immediate: false):
            pendingPurchases.insert(thread)
        case .togglePurchased(immediate: true):
            return  // nothing to do
        case .increment, .decrement:
            pendingPurchaseTick.send()
        }
    }
}

// MARK: - Toolbar
#if targetEnvironment(macCatalyst)

extension ShoppingListViewModel: ToolbarItemProviding {
    var title: AnyPublisher<String, Never> {
        Just("Shopping List").eraseToAnyPublisher()
    }

    var leadingToolbarItems: AnyPublisher<[NSToolbarItem.Identifier], Never> {
        Just([.addCheckedToCollection]).eraseToAnyPublisher()
    }
}

#endif

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
        actionRunner.perform(threads.addToShoppingListAction)
    }
}
