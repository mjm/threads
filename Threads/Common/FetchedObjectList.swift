//
//  FetchedObjectList.swift
//  Threads
//
//  Created by Matt Moriarity on 9/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData

class FetchedObjectList<ObjectType: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    let fetchedResultsController: NSFetchedResultsController<ObjectType>

    private let objectsSubject = CurrentValueSubject<[ObjectType], Never>([])
    private let objectSubject = PassthroughSubject<ObjectType, Never>()

    init(
        fetchRequest: NSFetchRequest<ObjectType>,
        managedObjectContext: NSManagedObjectContext
    ) {
        fetchedResultsController
            = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil)
        super.init()

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error fetching objects: \(error)")
        }

        // controllerDidChangeContent does not get called for the initial fetch, so we need to send the objects to our subject to populate the initial data
        objectsSubject.send(objects)
    }

    var objects: [ObjectType] { fetchedResultsController.fetchedObjects ?? [] }

    func objectsPublisher() -> AnyPublisher<[ObjectType], Never> {
        objectsSubject.eraseToAnyPublisher()
    }

    func objectPublisher() -> AnyPublisher<ObjectType, Never> {
        objectSubject.eraseToAnyPublisher()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        objectsSubject.send(fetchedResultsController.fetchedObjects ?? [])
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
        at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?
    ) {
        objectSubject.send(anObject as! ObjectType)
    }
}
