//
//  AddThreadViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class AddThreadViewModel: ViewModel {
    enum Section {
        case filtered
        case selected
    }

    struct Item: Hashable {
        var thread: Thread
        var section: Section
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    @Published var choices: [Thread] = []
    @Published var threadToSelect: Thread?
    @Published var query = ""
    @Published var selectedThreads: [Thread] = []

    var mode: AddThreadMode = NoOpAddThreadMode() {
        didSet {
            do {
                choices = try mode.addThreadChoices()
            } catch {
                presenter?.present(error: error)
                choices = []
            }
        }
    }

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        normalizedQuery.combineLatest(filteredThreads) { query, threads -> Thread? in
            threads.first { $0.number?.lowercased() == query }
        }.assign(to: \.threadToSelect, on: self).store(in: &cancellables)
    }

    var normalizedQuery: AnyPublisher<String, Never> {
        $query.map { $0.lowercased() }.eraseToAnyPublisher()
    }

    var filteredThreads: AnyPublisher<[Thread], Never> {
        normalizedQuery.combineLatest($choices, $selectedThreads) {
            query, choices, selectedThreads -> [Thread] in
            if query.isEmpty {
                return []
            } else {
                return choices.filter {
                    return !selectedThreads.contains($0) && $0.number!.lowercased().hasPrefix(query)
                }
            }
        }.eraseToAnyPublisher()
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        $selectedThreads.combineLatest(filteredThreads).map { input in
            let (selected, filtered) = input
            var snapshot = Snapshot()

            if !filtered.isEmpty {
                snapshot.appendSections([.filtered])
                snapshot.appendItems(
                    filtered.map { Item(thread: $0, section: .filtered) }, toSection: .filtered)
            }

            if !selected.isEmpty {
                snapshot.appendSections([.selected])
                snapshot.appendItems(
                    selected.map { Item(thread: $0, section: .selected) }, toSection: .selected)
            }

            return snapshot
        }.eraseToAnyPublisher()
    }

    var canQuickSelect: AnyPublisher<Bool, Never> {
        $threadToSelect.map { $0 != nil }.eraseToAnyPublisher()
    }

    var canAddSelected: AnyPublisher<Bool, Never> {
        $selectedThreads.map { !$0.isEmpty }.eraseToAnyPublisher()
    }

    func select(thread: Thread) {
        selectedThreads.insert(thread, at: 0)
        query = ""
    }

    func deselect(at row: Int) {
        selectedThreads.remove(at: row)
    }

    func quickSelect() {
        if let thread = threadToSelect {
            select(thread: thread)
        }
    }

    func addSelected() {
        mode.add(threads: selectedThreads, actionRunner: actionRunner)
    }
}

protocol AddThreadMode {
    func addThreadChoices() throws -> [Thread]
    func add(threads: [Thread], actionRunner: UserActionRunner)
}

fileprivate final class NoOpAddThreadMode: AddThreadMode {
    func addThreadChoices() throws -> [Thread] {
        []
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
    }
}
