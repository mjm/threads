//
//  Project+UIActivityItemSource.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

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
            let group = DispatchGroup()
            group.enter()

            project.publish { error in
                if let error = error {
                    NSLog("Error publishing project: \(error)")
                }

                group.leave()
            }
            
            group.wait()
            isPublished = true
        }

        if let url = project.publishedURL {
            NSLog("URL for published project: \(url)")
            return url
        } else {
            return ""
        }
    }

    public override func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return project.primaryImage?.thumbnailImage
    }
}
