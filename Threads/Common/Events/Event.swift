//
//  Event.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import os

struct Event: Encodable {
    enum Key: Hashable, CodingKey, ExpressibleByStringLiteral {
        case time
        case error
        case message
        case custom(String)
        
        init?(intValue: Int) {
            return nil
        }
        
        init?(stringValue: String) {
            switch stringValue {
            case "time": self = .time
            case "err": self = .error
            case "msg": self = .message
            default: self = .custom(stringValue)
            }
        }
        
        init(stringLiteral value: String) {
            self = .custom(value)
        }
        
        var intValue: Int? { nil }
        var stringValue: String {
            switch self {
            case .time: return "time"
            case .error: return "err"
            case .message: return "msg"
            case let .custom(key): return key
            }
        }
    }
    
    var timestamp: Date
    var error: Error?
    var message: String = ""
    var fields: [Event.Key: AnyEncodable]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(timestamp, forKey: .time)
        if let error = error {
            try container.encode(error.localizedDescription, forKey: .error)
        }
        try container.encode(message, forKey: .message)
        
        let sortedKeys = fields.keys.sorted { $0.stringValue < $1.stringValue }
        for key in sortedKeys {
            let value = fields[key]!
            try container.encode(value, forKey: key)
        }
    }
}

struct EventBuilder {
    var error: Error?
    var fields: [Event.Key: AnyEncodable] = [:]
    
    init() {}
    
    subscript <T: Encodable>(_ key: Event.Key) -> T? {
        get {
            fields[key] as? T
        }
        set {
            fields[key] = AnyEncodable(newValue)
        }
    }
    
    func makeEvent(message: String, timestamp: Date = Date()) -> Event {
        Event(timestamp: timestamp,
              error: error,
              message: message,
              fields: fields)
    }
}
