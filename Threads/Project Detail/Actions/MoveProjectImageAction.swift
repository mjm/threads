//
//  MoveProjectImageAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct MoveProjectImageAction: SimpleUserAction {
    let project: Project
    let sourceIndex: Int
    let destinationIndex: Int

    var undoActionName: String? { Localized.moveImage }

    func perform() throws {
        Event.current[.projectName] = project.name

        var images = project.orderedImages

        let image = images.remove(at: sourceIndex)
        images.insert(image, at: destinationIndex)

        project.orderedImages = images
    }
}

extension Project {
    func moveImageAction(from source: Int, to destination: Int) -> MoveProjectImageAction {
        .init(project: self, sourceIndex: source, destinationIndex: destination)
    }
}
