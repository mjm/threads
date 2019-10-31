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

    func await(_ predicateString: String, view: Any, timeout: TimeInterval = 5.0) {
        let exp = expectation(for: NSPredicate(format: predicateString), evaluatedWith: view)
        wait(for: [exp], timeout: timeout)
    }
}

extension Event.Key {
    static let environment: Event.Key = "env"
}

enum AppEnvironment: String, Encodable {
    case production
    case test
}
