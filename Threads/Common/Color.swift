//
//  Color.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init?(hex: String) {
        let normalized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .init(charactersIn: "#"))
        
        let scanner = Scanner(string: normalized)
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xff0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0xff00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0xff) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        
        if !getRed(&red, green: &green, blue: &blue, alpha: nil) {
            fatalError("Could not get color components")
        }
        
        return String(format: "#%02X%02X%02X", red.colorValue, green.colorValue, blue.colorValue)
    }
    
    // source: https://stackoverflow.com/a/3943023
    //
    // This will return black or white, whichever would be higher contrast against
    // the provided background.
    var labelColor: UIColor {
        if luminance > 0.179 {
            return .black
        } else {
            return .white
        }
    }
    
    var luminance: CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        
        if !getRed(&red, green: &green, blue: &blue, alpha: nil) {
            fatalError("Could not get color components")
        }
        
        func normalize(_ value: inout CGFloat) {
            if value <= 0.03928 {
                value = value / 12.92
            } else {
                value = pow((value + 0.055) / 1.055, 2.4)
            }
        }
        
        normalize(&red)
        normalize(&green)
        normalize(&blue)
        
        return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }
}

extension CGFloat {
    var colorValue: Int {
        return Int((self * 255.0).rounded(.towardZero))
    }
}
