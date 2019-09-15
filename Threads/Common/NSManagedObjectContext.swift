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
    
    func act(_ name: String, action: () -> Void) {
        undoManager?.setActionName(name)
        action()
        commit()
    }
}

extension NSManagedObject {
    func act(_ name: String, action: () -> Void) {
        managedObjectContext!.act(name, action: action)
    }
}
