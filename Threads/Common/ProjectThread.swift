//
//  ProjectThread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CloudKit
import CoreData
import Foundation

extension ProjectThread {
    class func fetchRequest(for project: Project) -> NSFetchRequest<ProjectThread> {
        let request: NSFetchRequest<ProjectThread> = fetchRequest()
        request.predicate = NSPredicate(format: "project = %@", project)
        request.sortDescriptors = [NSSortDescriptor(key: "thread.number", ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["thread"]
        return request
    }

    class func fetchRequest(for thread: Thread) -> NSFetchRequest<ProjectThread> {
        let request: NSFetchRequest<ProjectThread> = fetchRequest()
        request.predicate = NSPredicate(format: "thread = %@", thread)
        request.sortDescriptors = [NSSortDescriptor(key: "project.name", ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["project"]
        return request
    }

    func publishRecord() -> CKRecord {
        let record: CKRecord
        if let publishedID = publishedID {
            let id = CKRecord.ID(recordName: publishedID)
            record = CKRecord(recordType: "ProjectThread", recordID: id)
        } else {
            record = CKRecord(recordType: "ProjectThread")
        }

        record["amount"] = amount

        // inline properties from the thread
        if let thread = thread {
            record["number"] = thread.number
            record["label"] = thread.label
            record["colorHex"] = thread.colorHex
        }

        return record
    }
}
