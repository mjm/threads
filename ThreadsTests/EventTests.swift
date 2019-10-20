//
//  EventTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import XCTest
@testable import Threads

extension Event.Key {
    fileprivate static let foo: Event.Key = "foo"
    fileprivate static let bar: Event.Key = "bar"
    fileprivate static let baz: Event.Key = "baz"
}

private let now = Date()

class EventBuilderTests: XCTestCase {
    override class func setUp() {
        Event.global = EventBuilder()
    }
    
    func testCreateEmptyEvent() throws {
        var b = EventBuilder()
        let event = b.makeEvent(message: "test message", timestamp: now)
        
        XCTAssertEqual(event.timestamp, now)
        XCTAssertEqual(event.message, "test message")
        XCTAssertNil(event.error)
    }
    
    func testAFewEventTypes() throws {
        var b = EventBuilder()
        b[.foo] = "a string test"
        b[.bar] = 123
        b[.baz] = URL(string: "http://example.org/")!
        let event = b.makeEvent(message: "test message", timestamp: now)
        
        XCTAssertEqual(event.timestamp, now)
        XCTAssertEqual(event.message, "test message")
        XCTAssertNil(event.error)
        XCTAssertEqual(event.fields[.foo]?.value as? String, "a string test")
        XCTAssertEqual(event.fields[.bar]?.value as? Int, 123)
        XCTAssertEqual(event.fields[.baz]?.value as? URL, URL(string: "http://example.org/"))
    }
    
    func testIncludesFieldsFromGlobal() throws {
        Event.global[.baz] = "baz"
        
        var b = EventBuilder()
        b[.foo] = "a string test"
        b[.bar] = 123
        let event = b.makeEvent(message: "test message", timestamp: now)
        
        XCTAssertEqual(event.fields[.foo]?.value as? String, "a string test")
        XCTAssertEqual(event.fields[.bar]?.value as? Int, 123)
        XCTAssertEqual(event.fields[.baz]?.value as? String, "baz")
    }
    
    func testLocalValuesOverrideGlobal() throws {
        Event.global[.baz] = "baz"
        
        var b = EventBuilder()
        b[.foo] = "a string test"
        b[.bar] = 123
        b[.baz] = "overridden"
        let event = b.makeEvent(message: "test message", timestamp: now)
        
        XCTAssertEqual(event.fields[.foo]?.value as? String, "a string test")
        XCTAssertEqual(event.fields[.bar]?.value as? Int, 123)
        XCTAssertEqual(event.fields[.baz]?.value as? String, "overridden")
    }
    
    func testLazyFields() throws {
        var counter = 1
        Event.global[.bar] = { counter }
        
        var b = EventBuilder()
        b[.foo] = { counter * 2 }
        
        let event = b.makeEvent(message: "test message", timestamp: now)
        
        XCTAssertEqual(event.fields[.foo]?.value as? Int, 2)
        XCTAssertEqual(event.fields[.bar]?.value as? Int, 1)
        
        counter = 5
        
        let event2 = b.makeEvent(message: "test message", timestamp: now)
        
        XCTAssertEqual(event2.fields[.foo]?.value as? Int, 10)
        XCTAssertEqual(event2.fields[.bar]?.value as? Int, 5)
    }
}

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

class EventTests: XCTestCase {
    func testRoundtripEmptyEvent() throws {
        var b = EventBuilder()
        let fields = try roundtrip(event: b.makeEvent(message: "a cool message", timestamp: now))
        
        XCTAssertEqual(fields["msg"] as? String, "a cool message")
    }
    
    func testRoundtripEventWithFields() throws {
        var b = EventBuilder()
        b[.foo] = "a string test"
        b[.bar] = 123
        b[.baz] = URL(string: "http://example.org/")!
        let fields = try roundtrip(event: b.makeEvent(message: "a cool message", timestamp: now))
        
        XCTAssertEqual(fields["msg"] as? String, "a cool message")
        XCTAssertEqual(fields["foo"] as? String, "a string test")
        XCTAssertEqual(fields["bar"] as? Int, 123)
        XCTAssertEqual(fields["baz"] as? String, "http://example.org/")
    }
    
    private func roundtrip(event: Event) throws -> [String: Any] {
        let encodedData = try encoder.encode(event)
        let decodedDictionary = try JSONSerialization.jsonObject(with: encodedData, options: [])
        return decodedDictionary as! [String: Any]
    }
}
