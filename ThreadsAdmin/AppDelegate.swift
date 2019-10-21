//
//  AppDelegate.swift
//  ThreadsAdmin
//
//  Created by Matt Moriarity on 10/20/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Cocoa

let allThreadsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Projects/Threads/Threads/AllThreads.json")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

@objc(Thread) class Thread: NSObject, Codable {
    @objc dynamic var number: String
    @objc dynamic var label: String
    @objc dynamic var colorHex: String

    @objc dynamic var color: NSColor? {
        get {
            NSColor(hex: colorHex)
        }
        set {
            colorHex = newValue?.hexString ?? ""
        }
    }
    
    override init() {
        number = ""
        label = ""
        colorHex = "#FFFFFF"
        super.init()
    }
}
