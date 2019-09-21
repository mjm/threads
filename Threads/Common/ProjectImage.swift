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

@objc(ProjectImage)
public class ProjectImage: NSManagedObject {
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
        if let thumbnailData = thumbnailData {
            return UIImage(data: thumbnailData)
        } else if let image = image {
            let thumbnail = image.croppedToSquare(side: 600)
            thumbnailData = thumbnail.jpegData(compressionQuality: 1.0)
            return thumbnail
        } else {
            return nil
        }
    }

    func delete() {
        let project = self.project

        managedObjectContext!.delete(self)

        if let project = project {
            project.reorderImages()
        }
    }
}
