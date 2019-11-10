//
//  MyThreadsViewModelTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UserActions
import XCTest

@testable import Threads

final class MyThreadsViewModelTests: ViewModelTestCase {
    var subject: MyThreadsViewModel!
    var fakeView: FakeView!

    var actionRunner: UserActions.Runner { subject.actionRunner }

    override func setUp() {
        super.setUp()
        subject = MyThreadsViewModel(context: context)
        fakeView = FakeView()
    }

    func testShowEmptyView() throws {
        XCTAssertFalse(fakeView.showEmptyView)

        subject.isEmpty.assign(to: \.showEmptyView, on: fakeView).store(in: &cancellables)
        await(fakeView.showEmptyView)

        // now add a thread to our collection and it shouldn't show the empty view anymore
        let allThreads = try context.fetch(Threads.Thread.notInCollectionFetchRequest())
        actionRunner.perform(AddToCollectionAction(threads: [allThreads[0]]))

        await(!fakeView.showEmptyView)
    }

    func testSnapshot() throws {
        XCTAssertNil(fakeView.snapshot)

        subject.snapshot.map { s -> MyThreadsViewModel.Snapshot? in s }.assign(
            to: \.snapshot, on: fakeView).store(in: &cancellables)

        await(fakeView.hasSnapshot && fakeView.threadCount == 0)

        // now add a thread to our collection and it should update the snapshot
        let allThreads = try context.fetch(Threads.Thread.notInCollectionFetchRequest())
        let thread = allThreads[0]
        actionRunner.perform(AddToCollectionAction(threads: [thread]))

        await(fakeView.threadCount == 1)

        // removing the thread from the collection should update the snapshot
        actionRunner.perform(RemoveThreadAction(thread: thread))

        await(fakeView.hasSnapshot && fakeView.threadCount == 0)
    }

    @objcMembers class FakeView: NSObject {
        var showEmptyView = false
        var snapshot: MyThreadsViewModel.Snapshot?

        var hasSnapshot: Bool {
            snapshot != nil
        }

        var threadCount: Int {
            snapshot?.numberOfItems ?? 0
        }
    }
}
