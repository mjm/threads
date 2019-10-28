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

    override init(context: NSManagedObjectContext = .view) {
        threadsList
            = FetchedObjectList(
                fetchRequest: Thread.inCollectionFetchRequest(),
                managedObjectContext: context
            )

        super.init(context: context)
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        threadsList.objectsPublisher().map { threads -> Snapshot in
            var snapshot = Snapshot()

            snapshot.appendSections([.threads])
            snapshot.appendItems(threads.map { Cell(thread: $0) }, toSection: .threads)

            return snapshot
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        threadsList.objectsPublisher()
            .map { $0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
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

    func delete(cell: Cell) {
        actionRunner.perform(RemoveThreadAction(thread: cell.thread))
    }

    func toggleOnBobbin(cell: Cell) {
        guard cell.thread.amountInCollection > 0 else {
            return
        }

        if cell.thread.onBobbin {
            actionRunner.perform(MarkOffBobbinAction(thread: cell.thread))
        } else {
            actionRunner.perform(MarkOnBobbinAction(thread: cell.thread))
        }
    }

    func toggleInStock(cell: Cell) {
        if cell.thread.amountInCollection > 0 {
            actionRunner.perform(MarkOutOfStockAction(thread: cell.thread))
        } else {
            actionRunner.perform(MarkInStockAction(thread: cell.thread))
        }
    }
}
