//
//  StoreObserver.swift
//  Threads
//
//  Created by Matt Moriarity on 10/19/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import StoreKit
import Combine

enum StoreProduct: String, CaseIterable {
    #if targetEnvironment(macCatalyst)
    case premium = "maccatalyst.com.mattmoriarity.Threads.PremiumVersion"
    #else
    case premium = "com.mattmoriarity.Threads.PremiumVersion"
    #endif
}

class StoreObserver: NSObject, SKPaymentTransactionObserver {
    static let `default` = StoreObserver(productIDs: Set(StoreProduct.allCases))
    
    let productIDs: Set<StoreProduct>
    var purchasedProductIDs: Set<StoreProduct>
    
    var requests = Set<AnyCancellable>()
    
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
    
    func fetch(products: [StoreProduct]) -> AnyPublisher<[SKProduct], Error> {
        var delegate: ProductsRequestDelegate? = ProductsRequestDelegate()
        
        // need the delegate to hang around long enough
        delegate!.onCompletion.sink(receiveCompletion: { completion in
            delegate = nil
        }, receiveValue: { _ in }).store(in: &requests)
        
        let request = SKProductsRequest(productIdentifiers: Set(products.map { $0.rawValue }))
        request.delegate = delegate
        request.start()
        
        return delegate!.onCompletion.eraseToAnyPublisher()
    }
    
    func hasPurchased(_ product: StoreProduct) -> Bool {
        purchasedProductIDs.contains(product)
    }
    
    func attemptPurchase(_ product: SKProduct, completionHandler: @escaping (Result<(), Error>) -> Void) {
        let payment = SKPayment(product: product)
        let observer = PurchaseObserver(productID: product.productIdentifier, completionHandler: completionHandler)
        SKPaymentQueue.default().add(observer)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handleSuccessfulPurchase(transaction)
            case .failed:
                handleFailedPurchase(transaction)
            case .restored:
                handleSuccessfulPurchase(transaction)
            case .deferred:
                break
            case .purchasing:
                break
            default:
                break
            }
        }
    }
    
    private func handleSuccessfulPurchase(_ transaction: SKPaymentTransaction) {
        guard let product = StoreProduct(rawValue: transaction.payment.productIdentifier) else { return }
        purchasedProductIDs.insert(product)
        UserDefaults.standard.set(true, forKey: product.rawValue)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleFailedPurchase(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

class PurchaseObserver: NSObject, SKPaymentTransactionObserver {
    let productID: String
    let completionHandler: (Result<(), Error>) -> Void
    
    init(productID: String, completionHandler: @escaping (Result<(), Error>) -> Void) {
        self.productID = productID
        self.completionHandler = completionHandler
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            guard transaction.payment.productIdentifier == productID else {
                continue
            }
            
            switch transaction.transactionState {
            case .purchased:
                complete(.success(()))
            case .failed:
                handleFailed(transaction)
            case .restored:
                complete(.success(()))
            case .deferred:
                break
            case .purchasing:
                break
            default:
                break
            }
        }
    }
    
    private func handleFailed(_ transaction: SKPaymentTransaction) {
        guard let error = transaction.error else {
            complete(.success(()))
            return
        }
        
        if case SKError.paymentCancelled = error {
            complete(.success(()))
        } else {
            complete(.failure(error))
        }
    }
    
    private func complete(_ result: Result<(), Error>) {
        completionHandler(result)
        SKPaymentQueue.default().remove(self)
    }
}

fileprivate class ProductsRequestDelegate: NSObject, SKProductsRequestDelegate {
    let onCompletion = PassthroughSubject<[SKProduct], Error>()
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        onCompletion.send(response.products)
        onCompletion.send(completion: .finished)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        onCompletion.send(completion: .failure(error))
    }
}
