//
//  TextEncoderTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import XCTest
@testable import Threads

struct TestStruct: Encodable {
    var foo: String
    var bar: Int
}

extension Event.Key {
    fileprivate static let foo: Event.Key = "foo"
    fileprivate static let bar: Event.Key = "bar"
    fileprivate static let baz: Event.Key = "baz"
}

class TextEncoderTests: XCTestCase {
    
    var encoder: TextEncoder!

    override func setUp() {
        encoder = TextEncoder()
    }
    
    func testEncodeFlatStruct() throws {
        let result = try encoder.encode(TestStruct(foo: "a string", bar: 123))
        XCTAssertEqual(result, "foo=\"a string\" bar=123")
    }
    
    func testEncodeEvent() throws {
        var b = EventBuilder()
        b[.foo] = "an interesting value"
        b[.bar] = 1234
        b[.baz] = URL(string: "http://example.com/")!
        
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let result = try encoder.encode(b.makeEvent(message: "my event message", timestamp: date))
        
        XCTAssertEqual(result, "msg=\"my event message\" bar=1234 baz=\"http://example.com/\" foo=\"an interesting value\"")
    }
}
