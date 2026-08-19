import Foundation
import StoreKit

struct CoinPackage: Equatable {
    let productID: String
    let price: String
    let coins: Int
    let badge: String?

    var displayPrice: String { "$\(price)" }

    static let all: [CoinPackage] = [
        .init(productID: "pnbbupnbuvktgbuz", price: "0.99", coins: 500, badge: nil),
        .init(productID: "iphmxaehlokhqbct", price: "1.99", coins: 1_050, badge: nil),
        .init(productID: "yigmnvtxnjnmqlzd", price: "2.99", coins: 1_650, badge: "NEW"),
        .init(productID: "mazqovirzlcftvhi", price: "4.99", coins: 2_900, badge: nil),
        .init(productID: "ffthvfpycfqnceox", price: "9.99", coins: 6_000, badge: "POPULAR"),
        .init(productID: "bfydbuxftbusaqiq", price: "19.99", coins: 12_500, badge: nil),
        .init(productID: "uboaynpdevvevaif", price: "49.99", coins: 33_000, badge: "PLUS 10%"),
        .init(productID: "uvhfntfqftmppfby", price: "99.99", coins: 72_000, badge: "PLUS 20%"),
        .init(productID: "yusumvtayfbcjlzr", price: "149.99", coins: 115_000, badge: "MAX"),
    ]

    static func package(for productID: String) -> CoinPackage? {
        all.first { $0.productID == productID }
    }
}

enum CoinPurchaseEvent {
    case requesting(CoinPackage)
    case purchasing(CoinPackage)
    case success(CoinPackage)
    case deferred(CoinPackage)
    case failure(String)
}

extension Notification.Name {
    static let lookMeCoinPurchaseEvent = Notification.Name("lookMeCoinPurchaseEvent")
}

/// StoreKit 1 purchase coordinator. A product is requested only after its package is tapped.
final class CoinPurchaseManager: NSObject, SKProductsRequestDelegate, SKRequestDelegate, SKPaymentTransactionObserver {
    static let shared = CoinPurchaseManager()

    private var productRequest: SKProductsRequest?
    private var requestedPackage: CoinPackage?
    private let defaults = UserDefaults.standard
    private var isObserving = false

    private override init() { super.init() }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        SKPaymentQueue.default().add(self)
    }

    func purchase(_ package: CoinPackage) {
        guard SKPaymentQueue.canMakePayments() else {
            post(.failure("Purchases are disabled for this Apple ID or device."))
            return
        }
        productRequest?.cancel()
        requestedPackage = package
        post(.requesting(package))
        let request = SKProductsRequest(productIdentifiers: [package.productID])
        productRequest = request
        request.delegate = self
        request.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard request === productRequest, let package = requestedPackage else { return }
        productRequest = nil
        guard let product = response.products.first(where: { $0.productIdentifier == package.productID }) else {
            requestedPackage = nil
            post(.failure("This coin pack is not available in the current App Store storefront."))
            return
        }
        post(.purchasing(package))
        SKPaymentQueue.default().add(SKPayment(product: product))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request === productRequest else { return }
        productRequest = nil
        requestedPackage = nil
        post(.failure(error.localizedDescription))
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            guard let package = CoinPackage.package(for: transaction.payment.productIdentifier) else {
                if transaction.transactionState == .purchased || transaction.transactionState == .restored || transaction.transactionState == .failed {
                    queue.finishTransaction(transaction)
                }
                continue
            }
            switch transaction.transactionState {
            case .purchased:
                fulfill(transaction, package: package, queue: queue)
            case .restored:
                // Coin packs are consumables and aren't restored as reusable entitlements.
                queue.finishTransaction(transaction)
            case .failed:
                let cancelled = (transaction.error as? SKError)?.code == .paymentCancelled
                queue.finishTransaction(transaction)
                requestedPackage = nil
                if !cancelled { post(.failure(transaction.error?.localizedDescription ?? "The purchase could not be completed.")) }
            case .deferred:
                requestedPackage = nil
                post(.deferred(package))
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }

    private func fulfill(_ transaction: SKPaymentTransaction, package: CoinPackage, queue: SKPaymentQueue) {
        let identifier = transaction.transactionIdentifier ?? "\(package.productID)-\(transaction.transactionDate?.timeIntervalSince1970 ?? 0)"
        var processed = Set(defaults.stringArray(forKey: "processedCoinTransactions") ?? [])
        if !processed.contains(identifier) {
            LookMeExperienceStore.shared.addCoins(package.coins, source: "App Store purchase")
            processed.insert(identifier)
            defaults.set(Array(processed), forKey: "processedCoinTransactions")
        }
        queue.finishTransaction(transaction)
        requestedPackage = nil
        post(.success(package))
    }

    private func post(_ event: CoinPurchaseEvent) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .lookMeCoinPurchaseEvent, object: event)
        }
    }
}
