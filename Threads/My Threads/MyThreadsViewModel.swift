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

    struct Cell: Hashable, ReusableCell {
        var thread: Thread

        var cellIdentifier: String { "Thread" }
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Cell>

    private let threadsList: FetchedObjectList<Thread>

    @Published var selectedCell: Cell?

    override init(context: NSManagedObjectContext = .view) {
        threadsList
            = FetchedObjectList(
                fetchRequest: Thread.inCollectionFetchRequest(),
                managedObjectContext: context
            )

        super.init(context: context)
    }

    var threads: AnyPublisher<[Thread], Never> {
        threadsList.objectsPublisher()
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        threads.map { threads -> Snapshot in
            var snapshot = Snapshot()

            snapshot.appendSections([.threads])
            snapshot.appendItems(threads.map { Cell(thread: $0) }, toSection: .threads)

            return snapshot
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        threads
            .map { $0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var selectedThread: Thread? { selectedCell?.thread }
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
