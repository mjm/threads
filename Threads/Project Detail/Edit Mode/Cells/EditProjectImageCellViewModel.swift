//
//  EditProjectImageCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class EditProjectImageCellViewModel {
    let projectImage: ProjectImage
    let actionRunner: UserActionRunner

    init(projectImage: ProjectImage, actionRunner: UserActionRunner) {
        self.projectImage = projectImage
        self.actionRunner = actionRunner
    }

    var imageData: Data? {
        projectImage.data
    }

    var thumbnail: AnyPublisher<UIImage?, Never> {
        projectImage.publisher(for: \.thumbnailImage).eraseToAnyPublisher()
    }

    var deleteAction: BoundUserAction<Void> {
        projectImage.deleteAction
            .bind(to: actionRunner, title: Localized.delete, options: .destructive)
    }
}

extension EditProjectImageCellViewModel: Hashable {
    static func == (lhs: EditProjectImageCellViewModel, rhs: EditProjectImageCellViewModel) -> Bool
    {
        lhs.projectImage == rhs.projectImage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(projectImage)
    }
}
