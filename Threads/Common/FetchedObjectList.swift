//
//  FetchedObjectList.swift
//  Threads
//
//  Created by Matt Moriarity on 9/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData

class FetchedObjectList<ObjectType: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    let fetchedResultsController: NSFetchedResultsController<ObjectType>
    let updateSnapshot: () -> Void
    let updateCell: (ObjectType) -> Void

    init(
        fetchRequest: NSFetchRequest<ObjectType>,
        managedObjectContext: NSManagedObjectContext,
        updateSnapshot: @escaping () -> Void,
        updateCell: @escaping (ObjectType) -> Void
    ) {
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: fetchRequest,
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        self.updateSnapshot = updateSnapshot
        self.updateCell = updateCell
        super.init()

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
    }

    var objects: [ObjectType] {
        fetchedResultsController.fetchedObjects ?? []
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        updateCell(anObject as! ObjectType)
    }
}
