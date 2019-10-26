//
//  StoreActions.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import Combine
import StoreKit
import Events

extension Event.Key {
    static let fetchProductsTime: Event.Key = "fetch_products_ms"
}

struct BuyPremiumAction: ReactiveUserAction {
    let undoActionName: String? = nil
    
    func publisher(context: UserActionContext<BuyPremiumAction>) -> AnyPublisher<Void, Swift.Error> {
        Event.current.startTimer(.fetchProductsTime)
        return StoreObserver.default.fetch(products: [.premium])
            .handleEvents(receiveCompletion: { _ in
                Event.current.stopTimer(.fetchProductsTime)
            }).map { $0.first }.tryMap { (product) throws -> SKProduct in
                if let product = product {
                    return product
                } else {
                    throw Error.productInvalid
                }
            }.print().map { _ in () }.eraseToAnyPublisher()
    }
    
    enum Error: LocalizedError {
        case productInvalid
        
        var errorDescription: String? {
            switch self {
            case .productInvalid:
                return "The premium product is invalid and could not be found."
            }
        }
    }
}
