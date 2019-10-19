//
//  Project+UIActivityItemSource.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

extension Event.Key {
    static let previousPublishedID: Event.Key = "prev_published_id"
    static let publishedID: Event.Key = "published_id"
    static let publishedURL: Event.Key = "published_url"
}

extension Project {
    var itemProvider: NSItemProvider {
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(ofClass: NSURL.self, visibility: .all) { completion in
            let progress = Progress.discreteProgress(totalUnitCount: 1)
            
            self.publish { error in
                if error != nil {
                    completion(nil, error)
                } else {
                    if let url = self.publishedURL {
                        NSLog("URL for published project: \(url)")
                        progress.completedUnitCount = 1
                        completion(url as NSURL, nil)
                    } else {
                        fatalError()
                    }
                }
            }
            
            return progress
        }
        return itemProvider
    }
}

class ProjectActivity: UIActivityItemProvider {
    let project: Project

    init(project: Project) {
        self.project = project
        super.init(placeholderItem: project.publishedURL ?? Project.placeholderURL)
    }

    private var isPublished = false
    override var item: Any {
        if !isPublished {
            Event.current[.previousPublishedID] = project.publishedID
            
            let group = DispatchGroup()
            group.enter()

            project.publish { error in
                if let error = error {
                    Event.current.error = error
                }

                group.leave()
            }
            
            group.wait()
            isPublished = true
            
            Event.current[.publishedID] = project.publishedID
            Event.current[.publishedURL] = project.publishedURL
        }
        
        return project.publishedURL ?? ""
    }

    public override func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return project.primaryImage?.thumbnailImage
    }
}
