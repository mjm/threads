//
//  ShoppingListViewModelTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 11/1/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UserActions
import XCTest

@testable import Threads

final class ShoppingListViewModelTests: ViewModelTestCase {
    var subject: ShoppingListViewModel!
    var fakeView: FakeView!

    var actionRunner: UserActions.Runner { subject.actionRunner }

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

        subject.canAddPurchasedToCollection.assign(to: \.canAddPurchased, on: fakeView).store(
            in: &cancellables)
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
        subject.threadViewModels[0].togglePurchasedAction().perform()
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
        subject.selection = subject.threadViewModels[0]
        subject.selection?.togglePurchasedAction(immediate: true).perform()

        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        XCTAssertEqual(fakeView.unpurchasedThreads.count, 1)
        XCTAssertEqual(fakeView.purchasedThreads.count, 1)
        XCTAssertEqual(fakeView.purchasedThreads[0].number, "10")
    }

    func testUnpurchasedCount() throws {
        let thread1 = try getThread("10")
        let thread2 = try getThread("12")

        thread1.addToShoppingList()
        thread2.addToShoppingList()

        subject.unpurchasedCount.assign(to: \.unpurchasedCount, on: fakeView).store(
            in: &cancellables)
        await(fakeView.unpurchasedCount == 2)

        thread1.togglePurchased()
        await(fakeView.unpurchasedCount == 1)

        thread2.togglePurchased()
        await(fakeView.unpurchasedCount == 0)

        thread1.togglePurchased()
        await(fakeView.unpurchasedCount == 1)

        try getThread("11").addToShoppingList()
        await(fakeView.unpurchasedCount == 2)

        thread2.removeFromShoppingList()
        nextLoop()
        XCTAssertEqual(fakeView.unpurchasedCount, 2)

        thread1.removeFromShoppingList()
        await(fakeView.unpurchasedCount == 1)
    }

    func testCanInteractWithSelectedItem() throws {
        let thread1 = try getThread("10")
        let thread2 = try getThread("12")

        thread1.addToShoppingList()
        thread2.addToShoppingList()

        subject.snapshot.optionally().assign(to: \.snapshot, on: fakeView).store(in: &cancellables)
        await(fakeView.threadCount == 2)

        XCTAssertNil(subject.selection?.togglePurchasedAction())
        XCTAssertNil(subject.selection?.increaseQuantityAction)
        XCTAssertNil(subject.selection?.decreaseQuantityAction)
        XCTAssertNil(subject.selection?.removeAction)

        subject.selection = subject.threadViewModels[0]

        XCTAssertTrue(subject.selection?.togglePurchasedAction().canPerform ?? false)
        XCTAssertTrue(subject.selection?.increaseQuantityAction.canPerform ?? false)
        XCTAssertTrue(subject.selection?.decreaseQuantityAction.canPerform ?? false)
        XCTAssertTrue(subject.selection?.removeAction.canPerform ?? false)

        subject.selection = nil

        XCTAssertFalse(subject.selection?.togglePurchasedAction().canPerform ?? false)
        XCTAssertFalse(subject.selection?.increaseQuantityAction.canPerform ?? false)
        XCTAssertFalse(subject.selection?.decreaseQuantityAction.canPerform ?? false)
        XCTAssertFalse(subject.selection?.removeAction.canPerform ?? false)
    }

    func testAddPurchasedToCollection() throws {
        let thread1 = try getThread("10")
        let thread2 = try getThread("11")
        let thread3 = try getThread("12")

        thread1.addToShoppingList()
        thread2.addToShoppingList()
        thread3.addToShoppingList()

        subject.snapshot.optionally().assign(to: \.snapshot, on: fakeView).store(in: &cancellables)
        await(fakeView.threadCount == 3)

        thread1.togglePurchased()
        thread3.togglePurchased()
        await(fakeView.purchasedThreads.count == 2)

        subject.addPurchasedThreadsToCollection()
        await(fakeView.purchasedThreads.count == 0 && fakeView.unpurchasedThreads.count == 1)

        XCTAssertTrue(thread1.inCollection)
        XCTAssertEqual(thread1.amountInCollection, 1)
        XCTAssertTrue(thread3.inCollection)
        XCTAssertEqual(thread3.amountInCollection, 1)
    }

    @objcMembers class FakeView: NSObject {
        var showEmptyView = false
        var snapshot: ShoppingListViewModel.Snapshot?
        var canAddPurchased = false
        var unpurchasedCount: Int = 0

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
