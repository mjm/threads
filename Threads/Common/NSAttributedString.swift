//
//  NSAttributedString.swift
//  Threads
//
//  Created by Matt Moriarity on 9/14/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    // source: https://stackoverflow.com/questions/43723345/nsattributedstring-change-the-font-overall-but-keep-all-other-attributes
    func replace(font: UIFont, color: UIColor? = nil) {
        beginEditing()
        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) {
            value, range, stop in

            if let f = value as? UIFont,
                let newFontDescriptor = f.fontDescriptor
                    .withFamily(font.familyName)
                    .withSymbolicTraits(f.fontDescriptor.symbolicTraits)
            {

                let newFont = UIFont(
                    descriptor: newFontDescriptor,
                    size: font.pointSize)
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
                if let color = color {
                    removeAttribute(.foregroundColor, range: range)
                    addAttribute(.foregroundColor, value: color, range: range)
                }
            }
        }
        endEditing()
    }
}

extension NSAttributedString {
    func replacing(font: UIFont, color: UIColor? = nil) -> NSAttributedString {
        let newString = mutableCopy() as! NSMutableAttributedString
        newString.replace(font: font, color: color)
        return newString.copy() as! NSAttributedString
    }
}
