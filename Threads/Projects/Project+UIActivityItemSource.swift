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
