//
//  StoreObserver.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import StoreKit

enum StoreProduct: String {
    case premium = "com.mattmoriarity.Threads.Premium"
}

class StoreObserver: NSObject, SKPaymentTransactionObserver {
    let productIDs: Set<StoreProduct>
    let purchasedProductIDs: Set<StoreProduct>
    
    init(productIDs: Set<StoreProduct>) {
        self.productIDs = productIDs
        self.purchasedProductIDs = Set(productIDs.filter { UserDefaults.standard.bool(forKey: $0.rawValue) })
    }
    
    func validateReceipt() throws {
//        guard let appReceiptURL = Bundle.main.appStoreReceiptURL else {
//            fatalError()
//        }
//
//        print(appReceiptURL)
    }
    
    func hasPurchased(_ product: StoreProduct) -> Bool {
        purchasedProductIDs.contains(product)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        NSLog("updated transactions: \(transactions)")
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                break
            case .failed:
                break
            case .restored:
                break
            case .deferred:
                break
            case .purchasing:
                break
            default:
                break
            }
        }
    }
}
