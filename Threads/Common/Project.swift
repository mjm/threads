//
//  Project.swift
//  Threads
//
//  Created by Matt Moriarity on 9/7/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

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
    
    var primaryImage: ProjectImage? {
        orderedImages.first
    }
}
