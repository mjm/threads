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
    func resized(to size: CGSize) -> UIImage {
        let realSize = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(origin: .zero, size: size)).size
        let renderer = UIGraphicsImageRenderer(size: realSize)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: realSize))
        }
    }
}
