//
//  DeleteProjectImageAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UserActions

struct DeleteProjectImageAction: SimpleUserAction {
    let image: ProjectImage

    var undoActionName: String? { Localized.deleteImage }

    func perform() throws {
        Event.current[.projectName] = image.project?.name
        image.delete()
    }
}

extension ProjectImage {
    var deleteAction: DeleteProjectImageAction { .init(image: self) }
}
