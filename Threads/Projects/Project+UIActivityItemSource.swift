//
//  Project+UIActivityItemSource.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

extension Project: UIActivityItemSource {
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return name ?? Localized.unnamedProject
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        NSLog("activityType = \(String(describing: activityType))")
        return name ?? Localized.unnamedProject
    }
    
    var itemProvider: NSItemProvider {
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(ofClass: NSURL.self, visibility: .all) { completion in
            let progress = Progress.discreteProgress(totalUnitCount: 1)
            
            self.publish { error in
                if error != nil {
                    completion(nil, error)
                } else {
                    if let recordID = self.publishedID {
                        let url = URL(string: "https://threads-demo.glitch.me/projects/\(recordID)")!
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
        super.init(placeholderItem: project.name ?? Localized.unnamedProject)
    }

    override var item: Any {
        let group = DispatchGroup()
        group.enter()

        project.publish { error in
            if let error = error {
                NSLog("Error publishing project: \(error)")
            }

            group.leave()
        }
        
        group.wait()

        if let recordID = project.publishedID {
            let url = "https://threads-demo.glitch.me/projects/\(recordID)"
            NSLog("URL for published project: \(url)")
            return url
        } else {
            return placeholderItem!
        }
    }

    public override func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return project.primaryImage?.thumbnailImage
    }
}
