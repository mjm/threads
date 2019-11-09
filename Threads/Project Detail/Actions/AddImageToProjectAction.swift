//
//  AddImageToProjectAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreServices
import Events
import UIKit
import UserActions

struct AddImageToProjectAction: ReactiveUserAction {
    let project: Project

    let coordinator = Coordinator()

    var undoActionName: String? { Localized.addImage }

    func publisher(context: UserActions.Context<AddImageToProjectAction>) -> AnyPublisher<
        Void, Swift.Error
    > {
        Event.current[.projectName] = project.name

        coordinator.project = project

        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = coordinator
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String]

        context.present(imagePickerController)

        return coordinator.subject.handleEvents(receiveCompletion: { _ in
            context.dismiss()
        }).eraseToAnyPublisher()
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var project: Project!
        let subject = PassthroughSubject<Void, Swift.Error>()

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let url = info[.imageURL] as? URL {
                do {
                    let data = try Data(contentsOf: url)
                    Event.current[.byteCount] = data.count
                    project.addImage(data)

                    subject.send()
                    subject.send(completion: .finished)
                } catch {
                    subject.send(completion: .failure(error))
                }
            } else {
                subject.send(completion: .failure(Error.noImageURL))
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            subject.send(completion: .failure(UserActionError.canceled))
        }
    }

    enum Error: LocalizedError {
        case noImageURL

        var errorDescription: String? {
            switch self {
            case .noImageURL:
                return "Invalid Project Image"
            }
        }

        var failureReason: String? {
            switch self {
            case .noImageURL:
                return
                    "The chosen media could not be added to the project because it is not a valid image."
            }
        }
    }
}

extension Project {
    var addImageAction: AddImageToProjectAction { .init(project: self) }
}
