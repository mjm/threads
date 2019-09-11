//
//  Thread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

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
    
    class func importThreads(_ threads: [DMCThread], context: NSManagedObjectContext) throws {
        // assumes the threads are already sorted by number
        
        let existingThreads = try context.fetch(sortedByNumberFetchRequest())
        
        var leftIter = existingThreads.makeIterator()
        var rightIter = threads.makeIterator()
        
        var leftItem = leftIter.next()
        var rightItem = rightIter.next()
        
        while leftItem != nil && rightItem != nil {
            if leftItem!.number! > rightItem!.number {
                // We don't have a local thread for this one, so make one
                _ = Thread(dmcThread: rightItem!, context: context)
                rightItem = rightIter.next()
            } else if leftItem!.number! < rightItem!.number {
                // Leave around threads that we don't have to import anymore
                leftItem = leftIter.next()
            } else {
                // Update existing threads
                leftItem!.label = rightItem!.label
                leftItem!.colorHex = rightItem!.colorHex
                
                leftItem = leftIter.next()
                rightItem = rightIter.next()
            }
        }
        
        // Create any remaining threads we don't already have
        for item in rightIter {
            _ = Thread(dmcThread: item, context: context)
        }
    }
    
    class func mergeThreads(context: NSManagedObjectContext) throws -> Int {
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
        
        return mergedThreads
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
            add(to: project)
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

    func addToShoppingList() {
        inShoppingList = true
        amountInShoppingList = 1
        purchased = false
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
    
    func add(to project: Project) {
        guard let projects = projects, !projects.contains(where: { ($0 as! ProjectThread).project == project }) else {
            return
        }
        
        let projectThread = ProjectThread(context: managedObjectContext!)
        projectThread.project = project
        addToProjects(projectThread)
    }
}
