//
//  ViewController.swift
//  ThreadsAdmin
//
//  Created by Matt Moriarity on 10/20/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var threadsController: NSArrayController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        threadsController.sortDescriptors = [
            NSSortDescriptor(keyPath: \Thread.number, ascending: true) { a, b in
                let a = a as! String
                let b = b as! String
                
                return a.compare(b, options: [.caseInsensitive, .numeric])
            }
        ]

        do {
            let threadsData = try Data(contentsOf: allThreadsURL)
            let threads = try JSONDecoder().decode([Thread].self, from: threadsData)
            threadsController.content = NSMutableArray(array: threads)
        } catch {
            NSApp.presentError(error)
        }
    }
    
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
    
    @objc func saveDocument(_ sender: Any?) {
        do {
            let data = try encoder.encode(threadsController.arrangedObjects as! [Thread])
            try data.write(to: allThreadsURL)
        } catch {
            NSApp.presentError(error)
        }
    }
}
