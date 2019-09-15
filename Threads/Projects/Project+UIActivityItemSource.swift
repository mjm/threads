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
    
    public func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemOrange.setFill()
            UIColor.systemPurple.setStroke()
            
            let path = UIBezierPath(roundedRect: renderer.format.bounds, cornerRadius: 10)
            path.fill()
            
            path.lineWidth = 2
            path.stroke()
        }
    }
}
