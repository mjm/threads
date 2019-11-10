//
//  EventKeys.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

extension Event.Key {
    static let threadNumber: Event.Key = "thread_num"
    static let threadCount: Event.Key = "thread_count"

    static let oldAmount: Event.Key = "old_amount"
    static let newAmount: Event.Key = "new_amount"
    static let removed: Event.Key = "removed"

    static let projectName: Event.Key = "project_name"
    static let projectStatus: Event.Key = "project_status"
    static let byteCount: Event.Key = "byte_count"
    static let activityType: Event.Key = "activity_type"
}
