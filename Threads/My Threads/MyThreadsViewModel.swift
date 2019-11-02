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

final class MyThreadsViewModel: ViewModel, SnapshotViewModel {
    enum Section { case threads }

    typealias Item = CollectionThreadCellViewModel

    @Published private(set) var threadViewModels: [Item] = []
    @Published var selectedCell: Item?

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        let actionRunner = self.actionRunner

        $threadViewModels.applyingDifferences(threadChanges.ignoreError()) { thread in
            CollectionThreadCellViewModel(thread: thread, actionRunner: actionRunner)
        }.assign(to: \.threadViewModels, on: self).store(in: &cancellables)
    }

    var threadChanges: ManagedObjectChangesPublisher<Thread> {
        context.changesPublisher(for: Thread.inCollectionFetchRequest())
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

    func identifier(for item: Item) -> NSCopying {
        item.thread.objectID
    }

    func thread(for identifier: NSCopying) -> Thread? {
        context.object(with: identifier as! NSManagedObjectID) as? Thread
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
            actionRunner.perform(thread.removeFromCollectionAction)
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
            actionRunner.perform(thread.markOffBobbinAction)
        } else {
            actionRunner.perform(thread.markOnBobbinAction)
        }
    }

    var canToggleSelectedThreadInStock: Bool { selectedThread != nil }

    func toggleSelectedThreadInStock() {
        guard let thread = selectedThread else {
            return
        }

        if thread.amountInCollection > 0 {
            actionRunner.perform(thread.markOutOfStockAction)
        } else {
            actionRunner.perform(thread.markInStockAction)
        }
    }
}

// MARK: - Toolbar
#if targetEnvironment(macCatalyst)

extension MyThreadsViewModel: ToolbarItemProviding {
    var title: AnyPublisher<String, Never> {
        Just("My Threads").eraseToAnyPublisher()
    }
}

#endif

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
        actionRunner.perform(threads.addToCollectionAction)
    }
}
