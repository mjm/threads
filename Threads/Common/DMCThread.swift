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
    
    static var all: [DMCThread] = {
        let url = Bundle.main.url(forResource: "AllThreads", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let threads = try! JSONDecoder().decode([DMCThread].self, from: data)
        return threads.sorted { $0.number < $1.number }
    }()
}

extension Thread {
    convenience init(dmcThread: DMCThread, context: NSManagedObjectContext) {
        self.init(context: context)
        label = dmcThread.label
        number = dmcThread.number
        colorHex = dmcThread.colorHex
    }
    
    @objc dynamic var color: UIColor? {
        get {
            return colorHex.flatMap { UIColor(hex: $0) }
        }
        set {
            colorHex = newValue?.hexString ?? ""
        }
    }
    
    class func keyPathsForValuesAffectingColor() -> Set<String> {
        return ["colorHex"]
    }
}
