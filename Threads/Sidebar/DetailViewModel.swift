//
//  DetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 11/1/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class DetailViewModel: ViewModel {
    enum Selection: Equatable {
        case collection
        case shoppingList
        case project(ProjectDetailViewModel)
    }

    let collectionViewModel: MyThreadsViewModel
    let shoppingListViewModel: ShoppingListViewModel

    @Published var selection: Selection = .collection
    @Published private(set) var isEditingProject = false

    private var currentProjectEditing: AnyCancellable?

    override init(context: NSManagedObjectContext = .view) {
        collectionViewModel = MyThreadsViewModel(context: context)
        shoppingListViewModel = ShoppingListViewModel(context: context)
        super.init(context: context)

        $selection.sink { [weak self] selection in
            guard let self = self else { return }

            if case .project(let model) = selection {
                self.currentProjectEditing = model.$isEditing.assign(to: \.isEditingProject, on: self)
            } else {
                self.currentProjectEditing = nil
                self.isEditingProject = false
            }
        }.store(in: &cancellables)
    }

    #if targetEnvironment(macCatalyst)
    var toolbarItemProvider: AnyPublisher<ToolbarItemProviding, Never> {
        let collectionModel = self.collectionViewModel
        let shoppingListModel = self.shoppingListViewModel

        return $selection.map { selection in
            switch selection {
            case .collection:
                return collectionModel
            case .shoppingList:
                return shoppingListModel
            case .project(let projectModel):
                return projectModel
            }
        }.eraseToAnyPublisher()
    }
    #endif
}
