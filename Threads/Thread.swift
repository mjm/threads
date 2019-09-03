//
//  Thread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

extension Thread {
    class func sortedByNumber(context: NSManagedObjectContext) throws -> [Thread] {
        let request: NSFetchRequest<Thread> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        return try context.fetch(request)
    }
    
    class func importThreads(_ threads: [DMCThread], context: NSManagedObjectContext) throws {
        // assumes the threads are already sorted by number
        
        let existingThreads = try sortedByNumber(context: context)
        
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
}
