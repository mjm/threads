//
//  MyThreadsViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/27/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combinable
import CombinableCoreData
import CoreData
import UIKit
import UserActions

final class MyThreadsViewModel: ViewModel, SnapshotViewModel {
    enum Section { case threads }

    typealias Item = CollectionThreadCellViewModel

    @Published private(set) var threadViewModels: [Item] = []
    @Published var selection: Item?

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        let actionRunner = self.actionRunner

        $threadViewModels.applyingChanges(threadChanges.ignoreError()) { thread in
            CollectionThreadCellViewModel(thread: thread, actionRunner: actionRunner)
        }.assign(to: \.threadViewModels, on: self, weak: true).store(in: &cancellables)
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

    var selectedThread: Thread? { selection?.thread }

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
        actionRunner.perform(Thread.addToCollectionAction)
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

    func add(threads: [Thread], actionRunner: UserActions.Runner) {
        actionRunner.perform(threads.addToCollectionAction)
    }
}
