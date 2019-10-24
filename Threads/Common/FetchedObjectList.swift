//
//  FetchedObjectList.swift
//  Threads
//
//  Created by Matt Moriarity on 9/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import Combine

class FetchedObjectList<ObjectType: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    let fetchedResultsController: NSFetchedResultsController<ObjectType>
    private let contentSubject = PassthroughSubject<Void, Never>()
    private let objectSubject = PassthroughSubject<ObjectType, Never>()

    init(
        fetchRequest: NSFetchRequest<ObjectType>,
        managedObjectContext: NSManagedObjectContext
    ) {
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: fetchRequest,
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
    }

    var objects: [ObjectType] {
        fetchedResultsController.fetchedObjects ?? []
    }
    
    func contentChangePublisher() -> AnyPublisher<Void, Never> {
        contentSubject.eraseToAnyPublisher()
    }
    
    func objectPublisher() -> AnyPublisher<ObjectType, Never> {
        objectSubject.eraseToAnyPublisher()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        contentSubject.send()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        objectSubject.send(anObject as! ObjectType)
    }
}
