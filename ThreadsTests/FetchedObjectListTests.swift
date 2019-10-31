//
//  FetchedObjectListTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import XCTest

@testable import Threads

final class FetchedObjectListTests: XCTestCase {
    var subject: FetchedObjectList<Threads.Thread>!

    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!

    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        persistentContainer = createPersistentContainer()
        context = persistentContainer.viewContext
        cancellables = []

        let request = Threads.Thread.sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "number < \"153\"")
        subject = FetchedObjectList(fetchRequest: request, managedObjectContext: context)
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    var currentDiff: CollectionDifference<Threads.Thread>?

    func testInitialLoadDiff() {
        subject.differences.optionally().assign(to: \.currentDiff, on: self).store(
            in: &cancellables)
        XCTAssertNotNil(currentDiff)
        XCTAssertEqual(currentDiff!.removals.count, 0)
        XCTAssertEqual(currentDiff!.insertions.count, 10)
    }

    func testDiffRespondsToChanges() {
        subject.differences.optionally().assign(to: \.currentDiff, on: self).store(
            in: &cancellables)

        // delete the 4th thread from the list.
        context.delete(subject.objects[3])
        RunLoop.main.run(until: .init(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(currentDiff)
        XCTAssertEqual(currentDiff!.count, 1)
        if case .remove(3, let thread, _) = currentDiff!.first {
            XCTAssertEqual(thread.number, "12")
        } else {
            XCTFail("Unexpected item in diff: \(currentDiff!.first!)")
        }

        let newThread = Threads.Thread(context: context)
        newThread.number = "14a"
        RunLoop.main.run(until: .init(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(currentDiff)
        XCTAssertEqual(currentDiff!.count, 1)
        if case .insert(5, let thread, _) = currentDiff!.first {
            XCTAssertEqual(thread, newThread)
        } else {
            XCTFail("Unexpected item in diff: \(currentDiff!.first!)")
        }
    }

    func testDiffDoesNotRespondToInPlaceItemChanges() {
        subject.differences.optionally().assign(to: \.currentDiff, on: self).store(
            in: &cancellables)
        XCTAssertNotNil(currentDiff)
        let initialDiff = currentDiff!

        // update properties of an item in the list
        subject.objects[4].amountInCollection = 1
        RunLoop.main.run(until: .init(timeIntervalSinceNow: 0.2))

        XCTAssertNotNil(currentDiff)
        XCTAssertEqual(currentDiff, initialDiff)
    }
}
