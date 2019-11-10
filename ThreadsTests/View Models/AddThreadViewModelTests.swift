//
//  AddThreadViewModelTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import UserActions
import XCTest

@testable import Threads

private let choiceNumbers = [
    "1",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "150",
    "151",
    "152",
    "900",
    "902",
    "904",
]

final class AddThreadViewModelTests: ViewModelTestCase {
    var subject: AddThreadViewModel!
    var fakeView: FakeView!
    var fakeMode: FakeAddThreadMode!

    var choices: [Threads.Thread]!

    override func setUp() {
        super.setUp()
        subject = AddThreadViewModel(context: context)
        fakeView = FakeView()
        fakeMode = FakeAddThreadMode(context: context)

        subject.mode = fakeMode
    }

    func testStartsEmpty() {
        bindView()
        await(fakeView.hasSnapshot)

        XCTAssertEqual(fakeView.snapshot?.numberOfSections, 0)
        XCTAssertEqual(fakeView.snapshot?.numberOfItems, 0)
    }

    func testSnapshotUpdatesWithQueryChanges() {
        bindView()

        // A prefix of "1" should grab all of our choices
        subject.query = "1"
        await(fakeView.filteredCount == 10)
        XCTAssertTrue(fakeView.filteredThreads.allSatisfy { $0.number!.first == "1" })

        // Updating it to "15" should filter the results some more
        subject.query = "15"
        await(fakeView.filteredCount == 4)
        XCTAssertEqual(fakeView.filteredThreads.map { $0.number! }, ["15", "150", "151", "152"])

        // Updating it to "151" should get us down to a single thread
        subject.query = "151"
        await(fakeView.filteredCount == 1)
        XCTAssertEqual(fakeView.filteredThreads.first?.number, "151")

        // Backspacing to "15" should give the earlier results back
        subject.query = "15"
        await(fakeView.filteredCount == 4)
        XCTAssertEqual(fakeView.filteredThreads.map { $0.number! }, ["15", "150", "151", "152"])

        // Emptying the query should put us back in the start state
        subject.query = ""
        await(fakeView.filteredCount == 0)
    }

    func testSelectThread() {
        bindView()

        subject.query = "15"
        await(fakeView.filteredCount == 4)
        XCTAssertFalse(fakeView.canAdd)

        subject.select(thread: fakeView.filteredThreads.first { $0.number == "150" }!)
        await(
            fakeView.filteredCount == 0 && fakeView.selectedCount == 1 && fakeView.queryText == "")
        XCTAssertEqual(fakeView.selectedThreads.map { $0.number! }, ["150"])
        XCTAssertTrue(fakeView.canAdd)
    }

    func testQuickSelect() {
        bindView()

        // can't quick select with no query
        await(fakeView.hasSnapshot)
        XCTAssertFalse(fakeView.canQuickSelect)

        // can't quick select when the query is just a prefix
        subject.query = "90"
        await(fakeView.filteredCount == 3)
        XCTAssertFalse(fakeView.canQuickSelect)

        // can't quick select a thread that isn't there
        subject.query = "901"
        await(fakeView.filteredCount == 0)
        XCTAssertFalse(fakeView.canQuickSelect)

        // can only quick select when query text matches thread number exactly
        subject.query = "902"
        await(fakeView.filteredCount == 1)
        XCTAssertTrue(fakeView.canQuickSelect)

        subject.quickSelect()
        await(fakeView.filteredCount == 0 && fakeView.selectedCount == 1)
        XCTAssertFalse(fakeView.canQuickSelect)
        XCTAssertEqual(fakeView.queryText, "")

        // can quick select even if there is more than one filtered thread
        subject.query = "15"
        await(fakeView.filteredCount == 4)
        XCTAssertTrue(fakeView.canQuickSelect)

        subject.quickSelect()
        await(fakeView.filteredCount == 0 && fakeView.selectedCount == 2)
        XCTAssertFalse(fakeView.canQuickSelect)
        XCTAssertEqual(fakeView.queryText, "")
    }

    func testFilterExcludesAlreadySelected() {
        bindView()

        subject.select(thread: subject.choices.first { $0.thread.number == "15" }!.thread)
        subject.select(thread: subject.choices.first { $0.thread.number == "151" }!.thread)

        subject.query = "15"
        await(fakeView.filteredCount == 2)
        XCTAssertEqual(fakeView.filteredThreads.map { $0.number! }, ["150", "152"])
    }

    func testAddSelected() {
        bindView()

        subject.select(thread: subject.choices.first { $0.thread.number == "15" }!.thread)
        subject.select(thread: subject.choices.first { $0.thread.number == "151" }!.thread)

        subject.addSelected()

        XCTAssertEqual(fakeMode.addedThreads.count, 2)
    }

    private func bindView() {
        subject.snapshot.map { s -> AddThreadViewModel.Snapshot? in s }.assign(
            to: \.snapshot, on: fakeView).store(in: &cancellables)
        subject.$query.assign(to: \.queryText, on: fakeView).store(in: &cancellables)
        subject.canAddSelected.assign(to: \.canAdd, on: fakeView).store(in: &cancellables)
        subject.canQuickSelect.assign(to: \.canQuickSelect, on: fakeView).store(in: &cancellables)
    }

    @objcMembers class FakeView: NSObject {
        var snapshot: AddThreadViewModel.Snapshot?
        var queryText = ""
        var canAdd = false
        var canQuickSelect = false

        var hasSnapshot: Bool {
            snapshot != nil
        }

        var filteredThreads: [Threads.Thread] {
            snapshot?.itemIdentifiers(inSection: .filtered).map { $0.thread } ?? []
        }

        var filteredCount: Int {
            guard let snapshot = snapshot,
                snapshot.sectionIdentifiers.contains(.filtered)
            else { return 0 }

            return snapshot.numberOfItems(inSection: .filtered)
        }

        var selectedThreads: [Threads.Thread] {
            snapshot?.itemIdentifiers(inSection: .selected).map { $0.thread } ?? []
        }

        var selectedCount: Int {
            guard let snapshot = snapshot,
                snapshot.sectionIdentifiers.contains(.selected)
            else { return 0 }

            return snapshot.numberOfItems(inSection: .selected)
        }
    }

    class FakeAddThreadMode: AddThreadMode {
        let context: NSManagedObjectContext
        var addedThreads: [Threads.Thread] = []

        init(context: NSManagedObjectContext) {
            self.context = context
        }

        func addThreadChoices() throws -> [Threads.Thread] {
            let request = Threads.Thread.sortedByNumberFetchRequest()
            request.predicate = NSPredicate(format: "number IN %@", choiceNumbers)
            return try context.fetch(request)
        }

        func add(threads: [Threads.Thread], actionRunner: UserActions.Runner) {
            addedThreads.append(contentsOf: threads)
        }
    }
}
