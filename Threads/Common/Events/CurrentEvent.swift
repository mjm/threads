//
//  CurrentEvent.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

extension Event {
    static var global = EventBuilder()
    
    static var current = EventBuilder()
}
