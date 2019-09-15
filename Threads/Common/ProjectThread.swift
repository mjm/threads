//
//  ProjectThread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

extension ProjectThread {
    class func fetchRequest(for project: Project) -> NSFetchRequest<ProjectThread> {
        let request: NSFetchRequest<ProjectThread> = fetchRequest()
        request.predicate = NSPredicate(format: "project = %@", project)
        request.sortDescriptors = [NSSortDescriptor(key: "thread.number", ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["thread"]
        return request
    }
}
