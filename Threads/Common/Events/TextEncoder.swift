//
//  TextEncoder.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

class TextEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = _TextEncoder()
        
        try value.encode(to: encoder)
        
        return encoder.encodedString
    }
}

fileprivate class _TextEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    private var storage = FieldStorage()
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = TextKeyedEncodingContainer<Key>(encoder: self, storage: storage, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("TextEncoder does not support unkeyed encoding")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
    
    var encodedString: String {
        var fieldStrings = [String]()
        
        for (key, value) in storage.fields {
            fieldStrings.append("\(key)=\(value.quotedIfNeeded())")
        }
        
        return fieldStrings.joined(separator: " ")
    }
}

private let dateFormatter = ISO8601DateFormatter()

extension _TextEncoder {
    fileprivate func stringify(_ value: Bool) -> String { return value ? "true" : "false" }
    fileprivate func stringify(_ value: String) -> String { return value }
    fileprivate func stringify(_ value: Double) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: Float) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: Int) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: Int8) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: Int16) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: Int32) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: Int64) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: UInt) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: UInt8) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: UInt16) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: UInt32) -> String { return String(describing: value) }
    fileprivate func stringify(_ value: UInt64) -> String { return String(describing: value) }
    
    fileprivate func stringify<T: Encodable>(_ value: T) throws -> String? {
        if T.self == Date.self || T.self == NSDate.self {
            return dateFormatter.string(from: value as! Date)
        }
        
        if T.self == URL.self || T.self == NSURL.self {
            return (value as! URL).absoluteString
        }
        
        try value.encode(to: self)
        return nil
    }
}

fileprivate struct TextKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    var encoder: _TextEncoder
    var storage: FieldStorage
    var codingPath: [CodingKey]
    
    mutating func encodeNil(forKey key: K) throws {
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        try assertCanEncodeValue(key: key)
        storage.append(key.stringValue, encoder.stringify(value))
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        try assertCanEncodeValue(key: key)
        
        encoder.codingPath.append(key)
        defer { encoder.codingPath.removeLast() }
        
        if let str = try encoder.stringify(value) {
            storage.append(key.stringValue, str)
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("TextEncoder does not currently support nesting")
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        fatalError("TextEncoder does not support unkeyed encoding")
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        return encoder
    }
    
    private func assertCanEncodeValue(key: K) throws {
        if codingPath.count > 0 {
            throw TextEncodingError.nestingNotSupported(codingPath + [key])
        }
    }
}

extension _TextEncoder: SingleValueEncodingContainer {
    func encodeNil() throws {
    }
    
    func encode(_ value: Bool) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: String) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Double) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Float) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Int) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Int8) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Int16) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Int32) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: Int64) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: UInt) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: UInt8) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: UInt16) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: UInt32) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode(_ value: UInt64) throws {
        try assertCanEncodeValue()
        storage.append(codingPath[0].stringValue, stringify(value))
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        try assertCanEncodeValue()
        
        if let str = try stringify(value) {
            storage.append(codingPath[0].stringValue, str)
        }
    }
    
    private func assertCanEncodeValue() throws {
        if codingPath.count == 0 {
            throw TextEncodingError.keysRequired
        }
        
        if codingPath.count > 1 {
            throw TextEncodingError.nestingNotSupported(codingPath)
        }
    }
}

fileprivate class FieldStorage {
    var fields: [(key: String, value: String)] = []
    
    func append(_ key: String, _ value: String) {
        fields.append((key, value))
    }
}

enum TextEncodingError: LocalizedError {
    case nestingNotSupported([CodingKey])
    case keysRequired
    
    var errorDescription: String? {
        switch self {
        case let .nestingNotSupported(path):
            return "Could not encode at path \(path) because TextEncoder does not support nesting"
        case .keysRequired:
            return "Could not encode single value because TextEncoder requires top-level keys"
        }
    }
}

private let quoteRequiringCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._/@^+").inverted

extension String {
    fileprivate func quotedIfNeeded() -> String {
        let needsQuoted = unicodeScalars.contains { quoteRequiringCharacters.contains($0) }
        if needsQuoted {
            return String(reflecting: self)
        } else {
            return self
        }
    }
}
