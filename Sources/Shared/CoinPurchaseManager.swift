import Combine
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
        .init(productID: "yusumvtayfbcjlzr", price: "149.99", coins: 115_000, badge: "MAX")
    ]

    static func package(for productID: String) -> CoinPackage? { all.first { $0.productID == productID } }
}

enum CoinPurchaseEvent {
    case requesting(CoinPackage)
    case purchasing(CoinPackage)
    case success(CoinPackage)
    case deferred(CoinPackage)
    case failure(String)
}

enum NightHubRemotePurchaseEvent {
    case requesting(String)
    case purchasing(String)
    case verifying(String)
    case success(String, String)
    case failed(String, String)
}

extension Notification.Name {
    static let lookMeCoinPurchaseEvent = Notification.Name("lookMeCoinPurchaseEvent")
}

final class CoinPurchaseManager: NSObject, SKProductsRequestDelegate, SKRequestDelegate, SKPaymentTransactionObserver {
    static let shared = CoinPurchaseManager()

    private struct RemoteDraft: Codable {
        let productIdentifier: String
        let orderIdentifier: String
        let createdAt: TimeInterval
    }

    private struct RemoteTransactionRecord: Codable {
        let transactionIdentifier: String
        let productIdentifier: String
        let orderIdentifier: String
        let receipt: String
    }

    private enum RequestOwner {
        case native(CoinPackage)
        case remote(RemoteDraft)
    }

    typealias RemoteVerifier = (String, String, String) -> AnyPublisher<NightHubPurchaseVerification, Error>

    var remoteEventHandler: ((NightHubRemotePurchaseEvent) -> Void)?

    private var productRequest: SKProductsRequest?
    private var requestOwner: RequestOwner?
    private let defaults = UserDefaults.standard
    private var isObserving = false
    private var remoteVerifier: RemoteVerifier?
    private var verificationTasks: [String: AnyCancellable] = [:]
    private let draftKey = "com.nighthub.afterdark.coinvault.production.remoteDraft"
    private let recordKey = "com.nighthub.afterdark.coinvault.production.remoteRecords"
    private let completedKey = "com.nighthub.afterdark.coinvault.production.completedRemoteTransactions"
    private let retiredTestRemoteKeys = [
        "com.nighthub.afterdark.coinvault.remoteDraft",
        "com.nighthub.afterdark.coinvault.remoteRecords",
        "com.nighthub.afterdark.coinvault.completedRemoteTransactions"
    ]

    private override init() { super.init() }

    func startObserving() {
        guard !isObserving else { return }
        retiredTestRemoteKeys.forEach(defaults.removeObject(forKey:))
        isObserving = true
        SKPaymentQueue.default().add(self)
    }

    func configureRemoteVerifier(_ verifier: @escaping RemoteVerifier) {
        remoteVerifier = verifier
        retryPersistedRemoteTransactions()
    }

    func purchase(_ package: CoinPackage) {
        guard SKPaymentQueue.canMakePayments() else {
            post(.failure("Purchases are disabled for this Apple ID or device."))
            return
        }
        productRequest?.cancel()
        requestOwner = .native(package)
        post(.requesting(package))
        requestProduct(identifier: package.productID)
    }

    func beginRemotePurchase(productIdentifier: String, orderIdentifier: String) {
        let product = productIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let order = orderIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !product.isEmpty, !order.isEmpty else {
            emitRemote(.failed(order, "Invalid purchase request."))
            return
        }
        guard SKPaymentQueue.canMakePayments() else {
            emitRemote(.failed(order, "Purchases are disabled for this Apple ID or device."))
            return
        }
        guard requestOwner == nil, verificationTasks.isEmpty else {
            emitRemote(.failed(order, "Another purchase is still being processed."))
            return
        }
        let draft = RemoteDraft(productIdentifier: product, orderIdentifier: order, createdAt: Date().timeIntervalSince1970)
        persist(draft: draft)
        requestOwner = .remote(draft)
        emitRemote(.requesting(order))
        requestProduct(identifier: product)
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard request === productRequest, let owner = requestOwner else { return }
        productRequest = nil
        let identifier: String
        switch owner {
        case .native(let package): identifier = package.productID
        case .remote(let draft): identifier = draft.productIdentifier
        }
        guard let product = response.products.first(where: { $0.productIdentifier == identifier }) else {
            requestOwner = nil
            switch owner {
            case .native: post(.failure("This coin pack is not available in the current App Store storefront."))
            case .remote(let draft):
                clearDraft()
                emitRemote(.failed(draft.orderIdentifier, "This item is not available in the current App Store storefront."))
            }
            return
        }
        let payment = SKMutablePayment(product: product)
        switch owner {
        case .native(let package): post(.purchasing(package))
        case .remote(let draft):
            payment.applicationUsername = draft.orderIdentifier
            emitRemote(.purchasing(draft.orderIdentifier))
        }
        SKPaymentQueue.default().add(payment)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request === productRequest, let owner = requestOwner else { return }
        productRequest = nil
        requestOwner = nil
        switch owner {
        case .native: post(.failure(error.localizedDescription))
        case .remote(let draft):
            clearDraft()
            emitRemote(.failed(draft.orderIdentifier, error.localizedDescription))
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased: processPurchased(transaction, queue: queue)
            case .restored: queue.finishTransaction(transaction)
            case .failed: processFailed(transaction, queue: queue)
            case .deferred: processDeferred(transaction)
            case .purchasing: break
            @unknown default: break
            }
        }
    }

    private func processPurchased(_ transaction: SKPaymentTransaction, queue: SKPaymentQueue) {
        let productIdentifier = transaction.payment.productIdentifier
        let transactionIdentifier = transaction.transactionIdentifier ?? ""
        if completedRemoteTransactions.contains(transactionIdentifier), !transactionIdentifier.isEmpty {
            queue.finishTransaction(transaction)
            return
        }
        if let record = remoteRecords[transactionIdentifier], !transactionIdentifier.isEmpty {
            verify(record: record, transaction: transaction, queue: queue)
            return
        }
        if let draft = currentDraft, draft.productIdentifier == productIdentifier {
            guard transactionMatches(transaction, draft: draft), let receipt = appReceipt, !transactionIdentifier.isEmpty else {
                emitRemote(.failed(draft.orderIdentifier, "Purchase verification is waiting for a complete App Store receipt."))
                return
            }
            let record = RemoteTransactionRecord(transactionIdentifier: transactionIdentifier, productIdentifier: productIdentifier, orderIdentifier: draft.orderIdentifier, receipt: receipt)
            persist(record: record)
            clearDraft()
            requestOwner = nil
            verify(record: record, transaction: transaction, queue: queue)
            return
        }
        if case .remote = requestOwner { return }
        guard let package = CoinPackage.package(for: productIdentifier) else { return }
        fulfillNative(transaction, package: package, queue: queue)
    }

    private func processFailed(_ transaction: SKPaymentTransaction, queue: SKPaymentQueue) {
        let cancelled = (transaction.error as? SKError)?.code == .paymentCancelled
        if let draft = currentDraft, draft.productIdentifier == transaction.payment.productIdentifier,
           transactionMatches(transaction, draft: draft) {
            queue.finishTransaction(transaction)
            requestOwner = nil
            clearDraft()
            emitRemote(.failed(draft.orderIdentifier, cancelled ? "Purchase cancelled." : (transaction.error?.localizedDescription ?? "The purchase could not be completed.")))
            return
        }
        if CoinPackage.package(for: transaction.payment.productIdentifier) != nil {
            queue.finishTransaction(transaction)
            requestOwner = nil
            if !cancelled { post(.failure(transaction.error?.localizedDescription ?? "The purchase could not be completed.")) }
        }
    }

    private func processDeferred(_ transaction: SKPaymentTransaction) {
        if let draft = currentDraft, draft.productIdentifier == transaction.payment.productIdentifier,
           transactionMatches(transaction, draft: draft) {
            requestOwner = nil
            emitRemote(.failed(draft.orderIdentifier, "The purchase is awaiting App Store approval."))
            return
        }
        if let package = CoinPackage.package(for: transaction.payment.productIdentifier) {
            requestOwner = nil
            post(.deferred(package))
        }
    }

    private func verify(record: RemoteTransactionRecord, transaction: SKPaymentTransaction?, queue: SKPaymentQueue) {
        guard verificationTasks[record.transactionIdentifier] == nil else { return }
        guard let verifier = remoteVerifier else {
            emitRemote(.failed(record.orderIdentifier, "Verification will resume when the service is available."))
            return
        }
        emitRemote(.verifying(record.orderIdentifier))
        verificationTasks[record.transactionIdentifier] = verifier(record.transactionIdentifier, record.receipt, record.orderIdentifier)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                if case .failure = completion {
                    self.emitRemote(.failed(record.orderIdentifier, "Purchase verification could not be completed. Please try again later."))
                }
                self.verificationTasks.removeValue(forKey: record.transactionIdentifier)
            }, receiveValue: { [weak self] result in
                guard let self else { return }
                switch result {
                case .accepted(let message):
                    self.completeRemote(record: record, transaction: transaction, queue: queue)
                    self.emitRemote(.success(record.orderIdentifier, message.isEmpty ? "Purchase completed." : message))
                case .rejected(let message):
                    if let transaction { queue.finishTransaction(transaction) }
                    self.removeRemoteRecord(transactionIdentifier: record.transactionIdentifier)
                    self.emitRemote(.failed(record.orderIdentifier, message.isEmpty ? "The purchase could not be verified." : message))
                }
            })
    }

    private func completeRemote(record: RemoteTransactionRecord, transaction: SKPaymentTransaction?, queue: SKPaymentQueue) {
        var completed = completedRemoteTransactions
        completed.insert(record.transactionIdentifier)
        defaults.set(Array(completed), forKey: completedKey)
        if let transaction { queue.finishTransaction(transaction) }
        removeRemoteRecord(transactionIdentifier: record.transactionIdentifier)
    }

    private func fulfillNative(_ transaction: SKPaymentTransaction, package: CoinPackage, queue: SKPaymentQueue) {
        let identifier = transaction.transactionIdentifier ?? "\(package.productID)-\(transaction.transactionDate?.timeIntervalSince1970 ?? 0)"
        var processed = Set(defaults.stringArray(forKey: "processedCoinTransactions") ?? [])
        if !processed.contains(identifier) {
            LookMeExperienceStore.shared.addCoins(package.coins, source: "App Store purchase")
            processed.insert(identifier)
            defaults.set(Array(processed), forKey: "processedCoinTransactions")
        }
        queue.finishTransaction(transaction)
        requestOwner = nil
        post(.success(package))
    }

    private func retryPersistedRemoteTransactions() {
        let records = remoteRecords
        for transaction in SKPaymentQueue.default().transactions where transaction.transactionState == .purchased {
            guard let identifier = transaction.transactionIdentifier, let record = records[identifier] else { continue }
            verify(record: record, transaction: transaction, queue: .default())
        }
    }

    private func transactionMatches(_ transaction: SKPaymentTransaction, draft: RemoteDraft) -> Bool {
        if transaction.payment.applicationUsername == draft.orderIdentifier { return true }
        guard let date = transaction.transactionDate else { return false }
        return date.timeIntervalSince1970 >= draft.createdAt - 30
    }

    private func requestProduct(identifier: String) {
        let request = SKProductsRequest(productIdentifiers: [identifier])
        productRequest = request
        request.delegate = self
        request.start()
    }

    private var appReceipt: String? {
        guard let url = Bundle.main.appStoreReceiptURL, let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
        return data.base64EncodedString()
    }

    private var currentDraft: RemoteDraft? {
        guard let data = defaults.data(forKey: draftKey) else { return nil }
        return try? JSONDecoder().decode(RemoteDraft.self, from: data)
    }

    private func persist(draft: RemoteDraft) {
        if let data = try? JSONEncoder().encode(draft) { defaults.set(data, forKey: draftKey) }
    }

    private func clearDraft() { defaults.removeObject(forKey: draftKey) }

    private var remoteRecords: [String: RemoteTransactionRecord] {
        guard let data = defaults.data(forKey: recordKey) else { return [:] }
        return (try? JSONDecoder().decode([String: RemoteTransactionRecord].self, from: data)) ?? [:]
    }

    private func persist(record: RemoteTransactionRecord) {
        var records = remoteRecords
        records[record.transactionIdentifier] = record
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: recordKey) }
    }

    private func removeRemoteRecord(transactionIdentifier: String) {
        var records = remoteRecords
        records.removeValue(forKey: transactionIdentifier)
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: recordKey) }
    }

    private var completedRemoteTransactions: Set<String> { Set(defaults.stringArray(forKey: completedKey) ?? []) }

    private func post(_ event: CoinPurchaseEvent) {
        DispatchQueue.main.async { NotificationCenter.default.post(name: .lookMeCoinPurchaseEvent, object: event) }
    }

    private func emitRemote(_ event: NightHubRemotePurchaseEvent) {
        DispatchQueue.main.async { [weak self] in self?.remoteEventHandler?(event) }
    }
}
