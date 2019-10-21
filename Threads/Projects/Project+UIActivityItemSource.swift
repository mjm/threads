//
//  Project+UIActivityItemSource.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import Events

extension Event.Key {
    static let previousPublishedID: Event.Key = "prev_published_id"
    static let publishedID: Event.Key = "published_id"
    static let publishedURL: Event.Key = "published_url"
    static let publishTime: Event.Key = "publish_ms"
}

extension Project {
    var itemProvider: NSItemProvider {
        var isPublished = false
        
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(ofClass: NSURL.self, visibility: .all) { completion in
            if isPublished, let url = self.publishedURL {
                completion(url as NSURL, nil)
                return nil
            }
            
            let progress = Progress.discreteProgress(totalUnitCount: 1)
            Event.current[.projectName] = self.name
            Event.current[.previousPublishedID] = self.publishedID
            
            Event.current.startTimer(.publishTime)
            self.publish { error in
                Event.current.stopTimer(.publishTime)
                isPublished = true
                
                if error != nil {
                    Event.current.error = error
                    Event.current.send("shared project")
                    completion(nil, error)
                } else if let url = self.publishedURL {
                    Event.current[.publishedID] = self.publishedID
                    Event.current[.publishedURL] = url
                    Event.current.send("shared project")
                    
                    progress.completedUnitCount = 1
                    completion(url as NSURL, nil)
                } else {
                    fatalError()
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
            
            Event.current.startTimer(.publishTime)
            
            let group = DispatchGroup()
            group.enter()

            project.publish { error in
                if let error = error {
                    Event.current.error = error
                }

                group.leave()
            }
            
            group.wait()
            
            Event.current.stopTimer(.publishTime)
            
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
