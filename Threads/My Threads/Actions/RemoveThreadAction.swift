//
//  RemoveThreadAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import Events
import Foundation

struct RemoveThreadAction: ReactiveUserAction, DestructiveUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.removeThread }
    var displayName: String? { Localized.removeFromCollection }

    var confirmationTitle: String { Localized.removeThread }
    var confirmationMessage: String { Localized.removeThreadPrompt }
    var confirmationButtonTitle: String { Localized.remove }

    func publisher(context: UserActionContext<RemoveThreadAction>) -> AnyPublisher<Void, Error> {
        Event.current[.threadNumber] = thread.number

        return Future { promise in
            UserActivity.showThread(self.thread).delete {
                RunLoop.main.perform {
                    self.thread.removeFromCollection()
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension Thread {
    var removeFromCollectionAction: RemoveThreadAction { .init(thread: self) }
}
