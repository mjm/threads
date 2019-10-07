//
//  Project.swift
//  Threads
//
//  Created by Matt Moriarity on 9/7/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

extension Project {
    class func allProjectsFetchRequest() -> NSFetchRequest<Project> {
        let request: NSFetchRequest<Project> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }
    
    func addToShoppingList() {
        let projectThreads = (threads?.allObjects ?? []) as! [ProjectThread]
        for projectThread in projectThreads {
            projectThread.thread?.addToShoppingList(quantity: projectThread.amount)
        }
    }

    func addImage(_ data: Data) {
        let image = ProjectImage(context: managedObjectContext!)
        image.order = Int64(allImages.count) // it matters that this one comes before the next line
        image.project = self
        image.data = data
    }
    
    var allImages: Set<ProjectImage> {
        get {
            (images as? Set<ProjectImage>) ?? []
        }
        set {
            images = newValue as NSSet
        }
    }
    
    var orderedImages: [ProjectImage] {
        get {
            Array(allImages).sorted { $0.order < $1.order }
        }
        set {
            for (i, image) in newValue.enumerated() {
                image.project = self
                image.order = Int64(i)
            }
        }
    }

    func reorderImages() {
        for (i, image) in orderedImages.enumerated() {
            image.order = Int64(i)
        }
    }
    
    var primaryImage: ProjectImage? {
        orderedImages.first
    }

    func publish(completion: @escaping (Error?) -> Void) {
        let database = CKContainer.default().publicCloudDatabase

        publishableRecord { record, error in
            if let error = error {
                completion(error)
                return
            }

            guard let record = record else {
                completion(nil)
                return
            }

            record["name"] = self.name
            record["notes"] = self.notes?.string

            let operation = CKModifyRecordsOperation(recordsToSave: [record])
            operation.queuePriority = .veryHigh // this will be blocking a user operation so let's do it STAT
            operation.isAtomic = true
            operation.savePolicy = .changedKeys
            operation.modifyRecordsCompletionBlock = { records, _, error in
                if let error = error {
                    completion(error)
                    return
                }

                guard let records = records else {
                    completion(nil)
                    return
                }

                self.managedObjectContext?.perform {
                    self.publishedID = records[0].recordID.recordName
                    completion(nil)
                }
            }

            database.add(operation)
        }
    }

    private func publishableRecord(completion: @escaping (CKRecord?, Error?) -> Void) {
        if let id = publishedID {
            let recordID = CKRecord.ID(recordName: id)

            let database = CKContainer.default().publicCloudDatabase
            database.fetch(withRecordID: recordID, completionHandler: completion)
        } else {
            completion(CKRecord(recordType: "Project"), nil)
        }
    }
}
