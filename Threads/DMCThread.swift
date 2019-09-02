//
//  DMCThread.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

struct DMCThread: Codable, Hashable {
    var number: String
    var label: String
    
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
    }
}
