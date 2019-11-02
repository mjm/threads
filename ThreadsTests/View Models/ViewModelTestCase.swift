//
//  ViewModelTestCase.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import Events
import XCTest

@testable import Threads

class ViewModelTestCase: XCTestCase {
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!

    var cancellables = Set<AnyCancellable>()

    override class func setUp() {
        super.setUp()

        Event.global[.environment] = AppEnvironment.test
    }

    override func setUp() {
        super.setUp()

        persistentContainer = createPersistentContainer()
        context = persistentContainer.viewContext

        cancellables = []
    }

    override func tearDown() {
        cancellables.removeAll()

        super.tearDown()
    }

    func await(
        _ test: @autoclosure () -> Bool, timeout: TimeInterval = 5.0, file: StaticString = #file,
        line: UInt = #line
    ) {
        let endDate = Date(timeIntervalSinceNow: timeout)
        while Date() < endDate {
            if test() {
                return
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        XCTFail("Timed out waiting for assertion to evaluate to true", file: file, line: line)
    }

    func getThread(_ number: String) throws -> Threads.Thread {
        try Threads.Thread.withNumber(number, context: context)!
    }
}

extension Event.Key {
    static let environment: Event.Key = "env"
}

enum AppEnvironment: String, Encodable {
    case production
    case test
}
