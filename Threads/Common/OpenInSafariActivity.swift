//
//  OpenInSafariActivity.swift
//  Threads
//
//  Created by Matt Moriarity on 10/18/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

extension UIActivity.ActivityType {
    static let openInSafari = UIActivity.ActivityType(
        "com.mattmoriarity.Threads.OpenInSafariActivity")
}

class OpenInSafariActivity: UIActivity {
    var activityItems: [Any] = []

    override var activityType: UIActivity.ActivityType? {
        .openInSafari
    }

    override var activityTitle: String? {
        NSLocalizedString("Open in Safari", comment: "")
    }

    override var activityImage: UIImage? {
        UIImage(named: "OpenInSafari")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let url = item as? URL, UIApplication.shared.canOpenURL(url) {
                return true
            }

            if let url = (item as? UIActivityItemProvider)?.placeholderItem as? URL,
                UIApplication.shared.canOpenURL(url)
            {
                return true
            }
        }

        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }

    override func perform() {
        for item in activityItems {
            guard
                let url = (item as? URL) ?? (
                    (item as? UIActivityItemProvider)?.placeholderItem as? URL
                ),
                UIApplication.shared.canOpenURL(url)
            else {
                continue
            }

            UIApplication.shared.open(url) { success in
                self.activityDidFinish(success)
            }
            return
        }
    }
}
