//
//  NSManagedObjectContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/14/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

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

    func observeChanges<T: NSManagedObject>(type: T.Type, observer: @escaping (Set<T>) -> Void) -> Any {
        return ObserverBox(NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: self, queue: OperationQueue.main) { note in
            guard let userInfo = note.userInfo else {
                return
            }

            var changedObjects = Set<NSManagedObject>()
            changedObjects.formUnion(userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
            changedObjects.formUnion(userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? [])
            changedObjects.formUnion(userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? [])

            let interestingObjects = Set(changedObjects.compactMap { $0 as? T })
            observer(interestingObjects)
        })
    }
}

class ObserverBox {
    let observer: Any

    init(_ observer: Any) {
        self.observer = observer
    }

    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}
