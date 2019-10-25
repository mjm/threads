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
import Combine
import Events

extension Event.Key {
    static let fetchProjectTime: Event.Key = "fetch_project_ms"
    static let saveProjectTime: Event.Key = "save_project_ms"
    static let recordCount: Event.Key = "record_count"
}

extension Project {
    class func allProjectsFetchRequest() -> NSFetchRequest<Project> {
        let request: NSFetchRequest<Project> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }
    
    class func withName(_ name: String, context: NSManagedObjectContext) throws -> Project? {
        let request: NSFetchRequest<Project> = fetchRequest()
        request.predicate = NSPredicate(format: "name = %@", name)
        request.fetchLimit = 1
        
        let results = try context.fetch(request)
        return results.first
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
    
    static let placeholderURL = URL(string: "https://threads-demo.glitch.me/projects/example")!
    
    var publishedURL: URL? {
        publishedID.flatMap { URL(string: "https://threads-demo.glitch.me/projects/\($0)") }
    }

    func publish() -> AnyPublisher<URL, Error> {
        let database = CKContainer.default().publicCloudDatabase
        
        return fetchOrCreateRecord().flatMap { record -> AnyPublisher<URL, Error> in
            record["name"] = self.name
            record["notes"] = self.notes?.string

            var records = [record]

            let projectImages = self.orderedImages
            var images: [CKRecord.Reference] = []
            for (reference, imageRecord) in projectImages.map({ $0.publishReference() }) {
                images.append(reference)
                if let record = imageRecord {
                    records.append(record)
                }
            }

            record["images"] = images

            let projectThreads: [ProjectThread]
            do {
                projectThreads = try self.managedObjectContext!.fetch(ProjectThread.fetchRequest(for: self))
                var threads: [CKRecord.Reference] = []
                for projectThread in projectThreads {
                    let threadRecord = projectThread.publishRecord()
                    records.append(threadRecord)
                    threads.append(CKRecord.Reference(record: threadRecord, action: .none))
                }

                record["threads"] = threads
            } catch {
                return Fail<URL, Error>(error: error).eraseToAnyPublisher()
            }
            
            Event.current[.recordCount] = records.count
            
            return Future { promise in
                let operation = CKModifyRecordsOperation(recordsToSave: records)
                operation.queuePriority = .veryHigh // this will be blocking a user operation so let's do it STAT
                operation.isAtomic = true
                operation.savePolicy = .changedKeys
                operation.modifyRecordsCompletionBlock = { records, _, error in
                    Event.current.stopTimer(.saveProjectTime)
                    
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    self.managedObjectContext?.perform {
                        let projectRecord = records![0]

                        self.publishedID = projectRecord.recordID.recordName

                        let imageReferences = projectRecord["images"] as! [CKRecord.Reference]
                        for (image, reference) in zip(projectImages, imageReferences) {
                            image.publishedID = reference.recordID.recordName
                        }

                        let threadReferences = projectRecord["threads"] as! [CKRecord.Reference]
                        for (thread, reference) in zip(projectThreads, threadReferences) {
                            thread.publishedID = reference.recordID.recordName
                        }

                        promise(.success(self.publishedURL!))
                    }
                }

                Event.current.startTimer(.saveProjectTime)
                database.add(operation)
            }.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    private func fetchOrCreateRecord() -> Future<CKRecord, Error> {
        Future { promise in
            if let id = self.publishedID {
                let recordID = CKRecord.ID(recordName: id)
                let database = CKContainer.default().publicCloudDatabase
                
                Event.current.startTimer(.fetchProjectTime)
                database.fetch(withRecordID: recordID) { record, error in
                    Event.current.stopTimer(.fetchProjectTime)
                    
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(record!))
                    }
                }
            } else {
                promise(.success(CKRecord(recordType: "Project")))
            }
        }
    }
}
