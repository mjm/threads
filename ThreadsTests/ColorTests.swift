//
//  ColorTests.swift
//  ThreadsTests
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import XCTest
@testable import Threads

class ColorTests: XCTestCase {

    func testWhite() {
        XCTAssertEqual(UIColor.white.hexString, "#FFFFFF")
        XCTAssertEqual(UIColor(hex: "#FFFFFF")?.cgColor.components, [1.0, 1.0, 1.0, 1.0])
    }
    
    func testBlack() {
        XCTAssertEqual(UIColor.black.hexString, "#000000")
        XCTAssertEqual(UIColor(hex: "#000000")?.cgColor.components, [0.0, 0.0, 0.0, 1.0])
    }
    
    func testRed() {
        XCTAssertEqual(UIColor.red.hexString, "#FF0000")
        XCTAssertEqual(UIColor(hex: "#FF0000")?.cgColor.components, [1.0, 0.0, 0.0, 1.0])
    }

}
