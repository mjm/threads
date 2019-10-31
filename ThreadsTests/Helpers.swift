//
//  Helpers.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import Events
import UIKit
import XCTest

@testable import Threads

extension XCTestCase {
    func createPersistentContainer() -> NSPersistentContainer {
        let managedObjectModel = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
            .managedObjectModel

        let persistentContainer
            = NSPersistentContainer(
                name: "Threads",
                managedObjectModel: managedObjectModel)

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        do {
            var event = EventBuilder()
            try Thread.importThreads(
                DMCThread.all, context: persistentContainer.viewContext, event: &event)
            try persistentContainer.viewContext.save()
        } catch {
            XCTFail("Error importing threads: \(error)")
        }

        return persistentContainer
    }
}
