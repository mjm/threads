//
//  CollectionThreadCellViewModelTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UserActions
import XCTest

@testable import Threads

final class CollectionThreadCellViewModelTests: ViewModelTestCase {
    var thread: Threads.Thread!
    var parent: MyThreadsViewModel!
    var subject: CollectionThreadCellViewModel!
    var actionRunner: UserActions.Runner!
    var fakeView: FakeView!

    override func setUp() {
        super.setUp()

        do {
            thread = try getThread("10")
            thread.addToCollection()

            parent = MyThreadsViewModel()
            subject
                = CollectionThreadCellViewModel(thread: thread, actionRunner: parent.actionRunner)
            fakeView = FakeView()
        } catch {
            XCTFail("Unexpected error setting up test: \(error)")
        }
    }

    func testOutOfStock() {
        subject.isOutOfStock.assign(to: \.outOfStock, on: fakeView).store(in: &cancellables)

        XCTAssertFalse(fakeView.outOfStock)

        subject.stockAction.perform()
        await(fakeView.outOfStock)

        subject.stockAction.perform()
        await(!fakeView.outOfStock)
    }

    func testStatus() {
        subject.status.assign(to: \.status, on: fakeView).store(in: &cancellables)
        nextLoop()

        XCTAssertNil(fakeView.status)

        XCTAssertNotNil(subject.bobbinAction)
        subject.bobbinAction?.perform()
        await(fakeView.status == .onBobbin)

        subject.stockAction.perform()
        await(fakeView.status == .outOfStock)
        XCTAssertNil(subject.bobbinAction)

        subject.stockAction.perform()
        await(fakeView.status == nil)

        subject.bobbinAction!.perform()
        await(fakeView.status == .onBobbin)

        subject.bobbinAction!.perform()
        await(fakeView.status == nil)
    }

    @objcMembers class FakeView: NSObject {
        var outOfStock = false
        var status: CollectionThreadCellViewModel.Status?
    }
}
