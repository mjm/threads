//
//  NSManagedObjectContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/14/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import UIKit

extension NSManagedObjectContext {
    class var view: NSManagedObjectContext {
        (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }

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
}
