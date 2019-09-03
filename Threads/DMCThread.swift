//
//  DMCThread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

struct DMCThread: Codable, Hashable {
    var number: String
    var label: String
    var colorHex: String
    
    var color: UIColor? {
        get {
            return UIColor(hex: colorHex)
        }
        set {
            colorHex = newValue?.hexString ?? ""
        }
    }
    
    static var all: [DMCThread] = {
        let url = Bundle.main.url(forResource: "AllThreads", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([DMCThread].self, from: data)
    }()
}

extension Thread {
    convenience init(dmcThread: DMCThread, context: NSManagedObjectContext) {
        self.init(context: context)
        label = dmcThread.label
        number = dmcThread.number
        colorHex = dmcThread.colorHex
    }
    
    var dmcThread: DMCThread {
        return DMCThread(number: number!, label: label!, colorHex: colorHex ?? "")
    }
    
    var color: UIColor? {
        get {
            return colorHex.flatMap { UIColor(hex: $0) }
        }
        set {
            colorHex = newValue?.hexString ?? ""
        }
    }
}
