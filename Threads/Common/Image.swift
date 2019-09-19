//
//  Image.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import AVFoundation

extension UIImage {
    func resized(toFit size: CGSize) -> UIImage {
        let realSize = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(origin: .zero, size: size)).size
        let renderer = UIGraphicsImageRenderer(size: realSize)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: realSize))
        }
    }

    func croppedToSquare(side: CGFloat) -> UIImage {
        if size.height == side && size.width == side {
            return self
        }

        let newSize = CGSize(width: side, height: side)

        let ratio: CGFloat
        let delta: CGFloat
        let offset: CGPoint
        if size.width > size.height {
            ratio = newSize.height / size.height
            delta = ratio * (size.width - size.height)
            offset = CGPoint(x: delta / 2, y: 0)
        } else {
            ratio = newSize.width / size.width
            delta = ratio * (size.height - size.width)
            offset = CGPoint(x: 0, y: delta / 2)
        }

        let clipRect = CGRect(x: -offset.x, y: -offset.y, width: ratio * size.width, height: ratio * size.height)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 0
        format.opaque = true
        return UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: newSize), format: format).image { context in
            context.clip(to: clipRect)
            draw(in: clipRect)
        }
    }
}
