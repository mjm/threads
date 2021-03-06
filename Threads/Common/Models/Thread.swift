//
//  Thread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import Events
import UIKit

extension Event.Key {
    static let mergedThreadCount: Event.Key = "merged_thread_count"
    static let createdThreadCount: Event.Key = "created_thread_count"
    static let extraThreadCount: Event.Key = "extra_thread_count"
    static let updatedThreadCount: Event.Key = "updated_thread_count"
}

public class Thread: NSManagedObject {
    class func inCollectionFetchRequest() -> NSFetchRequest<Thread> {
        let request = sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "inCollection = YES")
        return request
    }

    class func notInCollectionFetchRequest() -> NSFetchRequest<Thread> {
        let request = sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "inCollection = NO")
        return request
    }

    class func inShoppingListFetchRequest() -> NSFetchRequest<Thread> {
        let request = sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "inShoppingList = YES")
        return request
    }

    class func notInShoppingListFetchRequest() -> NSFetchRequest<Thread> {
        let request = sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "inShoppingList = NO")
        return request
    }

    class func purchasedFetchRequest() -> NSFetchRequest<Thread> {
        let request = sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "inShoppingList = YES AND purchased = YES")
        return request
    }

    class func fetchRequest(for project: Project) -> NSFetchRequest<Thread> {
        let request = sortedByNumberFetchRequest()
        request.predicate = NSPredicate(format: "%@ IN projects.project", project)
        return request
    }

    class func sortedByNumberFetchRequest() -> NSFetchRequest<Thread> {
        let request: NSFetchRequest<Thread> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        return request
    }

    class func withNumber(_ number: String, context: NSManagedObjectContext) throws -> Thread? {
        let request: NSFetchRequest<Thread> = fetchRequest()
        request.predicate = NSPredicate(format: "number = %@", number)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first
    }

    class func importThreads(
        _ threads: [DMCThread], context: NSManagedObjectContext, event: inout EventBuilder
    ) throws {
        // assumes the threads are already sorted by number

        let existingThreads = try context.fetch(sortedByNumberFetchRequest())

        var leftIter = existingThreads.makeIterator()
        var rightIter = threads.makeIterator()

        var leftItem = leftIter.next()
        var rightItem = rightIter.next()

        var createdCount = 0
        var extraCount = 0
        var updatedCount = 0

        while leftItem != nil && rightItem != nil {
            if leftItem!.number! > rightItem!.number {
                // We don't have a local thread for this one, so make one
                _ = Thread(dmcThread: rightItem!, context: context)
                rightItem = rightIter.next()
                createdCount += 1
            } else if leftItem!.number! < rightItem!.number {
                // Leave around threads that we don't have to import anymore
                leftItem = leftIter.next()
                extraCount += 1
            } else {
                // Update existing threads
                leftItem!.label = rightItem!.label
                leftItem!.colorHex = rightItem!.colorHex

                leftItem = leftIter.next()
                rightItem = rightIter.next()
                updatedCount += 1
            }
        }

        // Create any remaining threads we don't already have
        while rightItem != nil {
            _ = Thread(dmcThread: rightItem!, context: context)
            rightItem = rightIter.next()
            createdCount += 1
        }

        event[.createdThreadCount] = createdCount
        event[.extraThreadCount] = extraCount
        event[.updatedThreadCount] = updatedCount
    }

    class func mergeThreads(context: NSManagedObjectContext, event: inout EventBuilder) throws {
        let threads = try context.fetch(sortedByNumberFetchRequest())

        var currentThread: Thread?
        var mergedThreads = 0

        for thread in threads {
            if let currentThread = currentThread, thread.number == currentThread.number {
                // if we have multiple threads with the same number, merge all properties
                // and relationships into the first one and delete the extras

                currentThread.merge(thread)
                context.delete(thread)

                mergedThreads += 1
            } else {
                currentThread = thread
            }
        }

        event[.mergedThreadCount] = mergedThreads
    }

    func merge(_ other: Thread) {
        amountInCollection += other.amountInCollection
        inCollection = inCollection || other.inCollection
        onBobbin = onBobbin || other.onBobbin

        amountInShoppingList += other.amountInShoppingList
        inShoppingList = inShoppingList || other.inShoppingList
        purchased = purchased || other.purchased

        let otherProjectThreads = (other.projects?.allObjects ?? []) as! [ProjectThread]
        for projectThread in otherProjectThreads {
            guard let project = projectThread.project else { continue }
            if let myProjectThread = inProject(project) {
                // if both threads are in the project, combine their amounts.
                // the ProjectThread for `other` should be deleted when `other` is deleted.
                myProjectThread.amount += projectThread.amount
            } else {
                // if `self` is not in the project, just steal the ProjectThread from `other`
                // and make it ours.
                projectThread.thread = self
            }
        }
    }

    func addToCollection() {
        amountInCollection = 1

        // If the thread is already in the collection, don't take it off the bobbin.
        // This can happen when adding things from the shopping list.
        if !inCollection {
            inCollection = true
            onBobbin = false
        }
    }

    func removeFromCollection() {
        inCollection = false
        amountInCollection = 0
        onBobbin = false
    }

    func addToShoppingList(quantity: Int64 = 1) {
        if !inShoppingList {
            inShoppingList = true
            purchased = false
            amountInShoppingList = quantity
        } else {
            // TODO: there's a weird edge case here if you've already marked the thread as purchased.
            // it doesn't really make sense to just add more quantity here, since it'll be like
            // you already bought those skeins.
            amountInShoppingList += quantity
        }
    }

    func removeFromShoppingList() {
        inShoppingList = false
        amountInShoppingList = 0
        purchased = false
    }

    func togglePurchased() {
        assert(inShoppingList)

        purchased = !purchased
    }

    @discardableResult func add(to project: Project) -> ProjectThread {
        if let projectThread = inProject(project) {
            return projectThread
        }

        let projectThread = ProjectThread(context: managedObjectContext!)
        projectThread.project = project
        projectThread.amount = 1
        addToProjects(projectThread)
        return projectThread
    }

    func inProject(_ project: Project) -> ProjectThread? {
        return projects?.first(where: { ($0 as! ProjectThread).project == project })
            as? ProjectThread
    }

    var colorImage: UIImage? {
        guard let color = color else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 180))
        return renderer.image { context in
            color.setFill()
            context.fill(renderer.format.bounds)
        }
    }
}
