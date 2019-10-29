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
@testable import Threads
import XCTest

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

        do {
            createContainer()
            try importThreads()
        } catch {
            XCTFail("Error setting up test: \(error)")
        }

        cancellables = []
    }

    override func tearDown() {
        cancellables.removeAll()

        super.tearDown()
    }

    private func createContainer() {
        let managedObjectModel = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.managedObjectModel

        persistentContainer = NSPersistentContainer(name: "Threads",
                                                    managedObjectModel: managedObjectModel)

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        context = persistentContainer.viewContext
    }

    private func importThreads() throws {
        var event = EventBuilder()
        try Thread.importThreads(DMCThread.all, context: context, event: &event)
        try context.save()
    }
}

extension Event.Key {
    static let environment: Event.Key = "env"
}

enum AppEnvironment: String, Encodable {
    case production
    case test
}
