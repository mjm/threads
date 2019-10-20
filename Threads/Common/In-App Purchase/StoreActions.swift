//
//  StoreActions.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import Events

extension Event.Key {
    static let fetchProductsTime: Event.Key = "fetch_products_ms"
}

struct BuyPremiumAction: UserAction {
    let undoActionName: String? = nil
    
    func performAsync(_ context: UserActionContext<BuyPremiumAction>) {
        Event.current.startTimer(.fetchProductsTime)
        StoreObserver.default.fetch(products: [.premium]) { result in
            Event.current.stopTimer(.fetchProductsTime)
            
            do {
                let products = try result.get()
                guard let product = products.first else {
                    context.complete(error: Error.productInvalid)
                    return
                }
                
                print(product)
                context.complete()
            } catch {
                context.complete(error: error)
            }
        }
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
