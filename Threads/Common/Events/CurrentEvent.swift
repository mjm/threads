//
//  CurrentEvent.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

private let eventAccessQueue = DispatchQueue(label: "com.mattmoriarity.Threads.EventAccessQueue")

extension Event {
    private static var _global = EventBuilder()
    static var global: EventBuilder {
        get {
            eventAccessQueue.sync { _global }
        }
        set {
            eventAccessQueue.sync(flags: .barrier) {
                _global = newValue
            }
        }
    }
    
    private static var _current = EventBuilder()
    static var current: EventBuilder {
        get {
            eventAccessQueue.sync { _current }
        }
        set {
            eventAccessQueue.sync(flags: .barrier) {
                _current = newValue
            }
        }
    }
}
