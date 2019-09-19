//
//  ProjectImage.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension ProjectImage {
    class func fetchRequest(for project: Project) -> NSFetchRequest<ProjectImage> {
        let request: NSFetchRequest<ProjectImage> = fetchRequest()
        request.predicate = NSPredicate(format: "project = %@", project)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        return request
    }

    var image: UIImage? {
        get {
            data.flatMap { UIImage(data: $0) }
        }
        set {
            data = newValue?.jpegData(compressionQuality: 1.0)
        }
    }

    var thumbnailImage: UIImage? {
        image?.croppedToSquare(side: 600)
    }

    func delete() {
        let project = self.project

        managedObjectContext!.delete(self)

        if let project = project {
            project.reorderImages()
        }
    }
}
