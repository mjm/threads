//
//  ShoppingListViewModelTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 11/1/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import XCTest

@testable import Threads

final class ShoppingListViewModelTests: ViewModelTestCase {
    var subject: ShoppingListViewModel!
    var fakeView: FakeView!

    var actionRunner: UserActionRunner { subject.actionRunner }

    override func setUp() {
        super.setUp()
        subject = ShoppingListViewModel(context: context, purchaseDelay: 0.05)
        fakeView = FakeView()
    }

    func testCanAddPurchased() throws {
        let thread1 = try getThread("10")
        let thread2 = try getThread("12")

        thread1.addToShoppingList()
        thread2.addToShoppingList()

        subject.canAddPurchasedToCollection.assign(to: \.canAddPurchased, on: fakeView).store(in: &cancellables)
        XCTAssertFalse(fakeView.canAddPurchased)

        thread1.purchased = true
        await(fakeView.canAddPurchased)

        thread1.purchased = false
        await(!fakeView.canAddPurchased)
    }

    func testTogglePurchasedWithDelay() throws {
        let thread1 = try getThread("10")
        let thread2 = try getThread("12")

        thread1.addToShoppingList()
        thread2.addToShoppingList()

        subject.snapshot.optionally().assign(to: \.snapshot, on: fakeView).store(in: &cancellables)
        await(fakeView.threadCount == 2)

        XCTAssertEqual(subject.threadViewModels[0].thread, thread1)
        subject.threadViewModels[0].togglePurchased()
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        XCTAssertEqual(fakeView.unpurchasedThreads.count, 2)

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.06))
        XCTAssertEqual(fakeView.unpurchasedThreads.count, 1)
        XCTAssertEqual(fakeView.purchasedThreads.count, 1)
        XCTAssertEqual(fakeView.purchasedThreads[0].number, "10")
    }

    func testTogglePurchasedImmediately() throws {
        let thread1 = try getThread("10")
        let thread2 = try getThread("12")

        thread1.addToShoppingList()
        thread2.addToShoppingList()

        subject.snapshot.optionally().assign(to: \.snapshot, on: fakeView).store(in: &cancellables)
        await(fakeView.threadCount == 2)

        XCTAssertEqual(subject.threadViewModels[0].thread, thread1)
        subject.selectedItem = subject.threadViewModels[0]
        subject.togglePurchasedSelected(immediate: true)

        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        XCTAssertEqual(fakeView.unpurchasedThreads.count, 1)
        XCTAssertEqual(fakeView.purchasedThreads.count, 1)
        XCTAssertEqual(fakeView.purchasedThreads[0].number, "10")
    }

    @objcMembers class FakeView: NSObject {
        var showEmptyView = false
        var snapshot: ShoppingListViewModel.Snapshot?
        var canAddPurchased = false

        var hasSnapshot: Bool {
            snapshot != nil
        }

        var threadCount: Int {
            snapshot?.numberOfItems ?? 0
        }

        var unpurchasedThreads: [Threads.Thread] {
            (snapshot?.itemIdentifiers(inSection: .unpurchased) ?? []).map { $0.thread }
        }

        var purchasedThreads: [Threads.Thread] {
            (snapshot?.itemIdentifiers(inSection: .purchased) ?? []).map { $0.thread }
        }
    }
}
