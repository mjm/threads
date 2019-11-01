//
//  ViewProjectImageCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ViewProjectImageCellViewModel {
    let projectImage: ProjectImage

    init(projectImage: ProjectImage) {
        self.projectImage = projectImage
    }

    var thumbnail: AnyPublisher<UIImage?, Never> {
        projectImage.publisher(for: \.thumbnailImage).eraseToAnyPublisher()
    }
}

extension ViewProjectImageCellViewModel: Hashable {
    static func == (lhs: ViewProjectImageCellViewModel, rhs: ViewProjectImageCellViewModel) -> Bool
    {
        lhs.projectImage == rhs.projectImage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(projectImage)
    }
}
