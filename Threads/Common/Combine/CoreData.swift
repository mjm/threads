//
//  CoreData.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData

extension NSManagedObjectContext {
    func changesPublisher<T: NSManagedObject>(for request: NSFetchRequest<T>)
        -> ManagedObjectChangesPublisher<T>
    {
        ManagedObjectChangesPublisher(request: request, context: self)
    }
}

struct ManagedObjectChangesPublisher<Object: NSManagedObject>: Publisher {
    typealias Output = CollectionDifference<Object>
    typealias Failure = Error

    let request: NSFetchRequest<Object>
    let context: NSManagedObjectContext

    init(request: NSFetchRequest<Object>, context: NSManagedObjectContext) {
        self.request = request
        self.context = context
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let inner = Inner(downstream: subscriber, request: request, context: context)
        subscriber.receive(subscription: inner)
    }

    private final class Inner<Downstream: Subscriber>: NSObject, Combine.Subscription,
        NSFetchedResultsControllerDelegate
    where Downstream.Input == CollectionDifference<Object>, Downstream.Failure == Error {
        private let downstream: Downstream
        private var fetchedResultsController: NSFetchedResultsController<Object>?

        private var demand: Subscribers.Demand = .none
        private var lastSentState: [Object] = []

        private var currentDifferences: CollectionDifference<Object> = [Object]().difference(
            from: [Object]())

        init(
            downstream: Downstream,
            request: NSFetchRequest<Object>,
            context: NSManagedObjectContext
        ) {
            self.downstream = downstream
            fetchedResultsController
                = NSFetchedResultsController(
                    fetchRequest: request,
                    managedObjectContext: context,
                    sectionNameKeyPath: nil,
                    cacheName: nil)

            super.init()

            fetchedResultsController!.delegate = self

            do {
                try fetchedResultsController!.performFetch()
                updateDiff()
            } catch {
                downstream.receive(completion: .failure(error))
            }
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            fulfillDemand()
        }

        private func fulfillDemand() {
            if demand > 0 && !currentDifferences.isEmpty {
                let newDemand = downstream.receive(currentDifferences)
                lastSentState = Array(fetchedResultsController?.fetchedObjects ?? [])
                currentDifferences = lastSentState.difference(from: lastSentState)

                demand += newDemand
                demand -= 1
            }
        }

        private func updateDiff() {
            currentDifferences
                = Array(fetchedResultsController?.fetchedObjects ?? []).difference(
                    from: lastSentState)
            fulfillDemand()
        }

        func cancel() {
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
        }

        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            updateDiff()
        }

        override var description: String {
            "ManagedObjectChanges(\(Object.self))"
        }
    }
}
