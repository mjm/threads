//
//  MyThreadsViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/27/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class MyThreadsViewModel: ViewModel {
    enum Section { case threads }

    typealias Item = CollectionThreadCellViewModel

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let threadsList: FetchedObjectList<Thread>

    @Published private(set) var threadViewModels: [Item] = []
    @Published var selectedCell: Item?

    override init(context: NSManagedObjectContext = .view) {
        threadsList
            = FetchedObjectList(
                fetchRequest: Thread.inCollectionFetchRequest(),
                managedObjectContext: context
            )

        super.init(context: context)

        $threadViewModels.applyingDifferences(threadsList.differences) { thread in
            CollectionThreadCellViewModel(thread: thread)
        }.assign(to: \.threadViewModels, on: self).store(in: &cancellables)
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        $threadViewModels.map { threadModels -> Snapshot in
            var snapshot = Snapshot()

            snapshot.appendSections([.threads])
            snapshot.appendItems(threadModels, toSection: .threads)

            return snapshot
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        $threadViewModels
            .map { $0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var selectedThread: Thread? { selectedCell?.thread }

    var userActivity: AnyPublisher<UserActivity, Never> {
        Just(.showMyThreads).eraseToAnyPublisher()
    }
}

// MARK: - Actions
extension MyThreadsViewModel {
    func buyPremium() {
        actionRunner.perform(BuyPremiumAction())
    }

    func addThreads() {
        actionRunner.perform(AddThreadAction(mode: .collection))
    }

    var canDeleteSelectedThread: Bool { selectedThread != nil }

    func deleteSelectedThread() {
        if let thread = selectedThread {
            actionRunner.perform(RemoveThreadAction(thread: thread))
        }
    }

    var canToggleSelectedThreadOnBobbin: Bool {
        (selectedThread?.amountInCollection ?? 0) > 0
    }

    func toggleSelectedThreadOnBobbin() {
        guard let thread = selectedThread, thread.amountInCollection > 0 else {
            return
        }

        if thread.onBobbin {
            actionRunner.perform(MarkOffBobbinAction(thread: thread))
        } else {
            actionRunner.perform(MarkOnBobbinAction(thread: thread))
        }
    }

    var canToggleSelectedThreadInStock: Bool { selectedThread != nil }

    func toggleSelectedThreadInStock() {
        guard let thread = selectedThread else {
            return
        }

        if thread.amountInCollection > 0 {
            actionRunner.perform(MarkOutOfStockAction(thread: thread))
        } else {
            actionRunner.perform(MarkInStockAction(thread: thread))
        }
    }
}

// MARK: - Context Menu Actions
extension MyThreadsViewModel {
    func markActions(for item: Item) -> [BoundUserAction<Void>] {
        let thread = item.thread

        if thread.amountInCollection == 0 {
            return [MarkInStockAction(thread: thread).bind(to: actionRunner)]
        } else {
            return [
                thread.onBobbin
                    ? MarkOffBobbinAction(thread: thread).bind(to: actionRunner)
                    : MarkOnBobbinAction(thread: thread).bind(to: actionRunner),
                MarkOutOfStockAction(thread: thread).bind(to: actionRunner),
            ]
        }
    }

    func projectActions(for item: Item) -> [BoundUserAction<Void>] {
        let thread = item.thread

        do {
            let request = Project.allProjectsFetchRequest()
            let projects = try context.fetch(request)

            return projects.map { project in
                AddToProjectAction(thread: thread, project: project, showBanner: true)
                    .bind(to: actionRunner, title: project.displayName)
            }
        } catch {
            presenter?.present(error: error)
            return []
        }
    }

    func addToShoppingListAction(for item: Item) -> BoundUserAction<Void> {
        AddToShoppingListAction(thread: item.thread, showBanner: true)
            .bind(to: actionRunner)
    }

    func removeAction(for item: Item) -> BoundUserAction<Void> {
        RemoveThreadAction(thread: item.thread)
            .bind(to: actionRunner,
                  title: Localized.removeFromCollection,
                  options: .destructive)
    }
}

// MARK: - Swipe Actions
extension MyThreadsViewModel {
    func bobbinAction(for item: Item) -> BoundUserAction<Void>? {
        guard item.thread.amountInCollection > 0 else {
            return nil
        }

        if item.thread.onBobbin {
            return MarkOffBobbinAction(thread: item.thread)
                .bind(to: actionRunner, title: Localized.offBobbin)
        } else {
            return MarkOnBobbinAction(thread: item.thread)
                .bind(to: actionRunner, title: Localized.onBobbin)
        }
    }

    func stockAction(for item: Item) -> BoundUserAction<Void> {
        if item.thread.amountInCollection == 0 {
            return MarkInStockAction(thread: item.thread)
                .bind(to: actionRunner, title: Localized.inStock)
        } else {
            return MarkOutOfStockAction(thread: item.thread)
                .bind(to: actionRunner, title: Localized.outOfStock, options: .destructive)
        }
    }
}

class AddThreadsToCollectionMode: AddThreadMode {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addThreadChoices() throws -> [Thread] {
        let request = Thread.notInCollectionFetchRequest()
        return try context.fetch(request)
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToCollectionAction(threads: threads))
    }
}
