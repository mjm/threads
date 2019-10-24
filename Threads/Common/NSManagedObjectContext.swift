//
//  NSManagedObjectContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/14/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData
import Combine

extension NSManagedObjectContext {
    func commit() {
        processPendingChanges()
        if hasChanges {
            do {
                try save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func publisher<T: NSManagedObject>(type: T.Type) -> AnyPublisher<T, Never>  {
        return NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: self
        ).receive(on: RunLoop.main).flatMap { note -> AnyPublisher<T, Never> in
            guard let userInfo = note.userInfo else {
                return Empty().eraseToAnyPublisher()
            }

            var changedObjects = Set<NSManagedObject>()
            changedObjects.formUnion(userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
            changedObjects.formUnion(userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? [])
            changedObjects.formUnion(userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? [])

            let objects = Set(changedObjects.compactMap { $0 as? T })
            return Publishers.Sequence(sequence: objects).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
