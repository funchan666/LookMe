import Foundation
import Security
import UIKit

final class NightHubSessionLedger {
    static let shared = NightHubSessionLedger()

    private let defaults = UserDefaults.standard
    private let service = "com.nighthub.afterdark.remote.production.identity"
    private let retiredTestService = "com.nighthub.afterdark.remote.identity"
    private let deviceAccount = "night-presence-device"
    private let passwordAccount = "night-presence-password"
    private let tokenKey = "com.nighthub.afterdark.remote.production.loginToken"
    private let continuityKey = "com.nighthub.afterdark.remote.production.sameInstallLogin"
    private let pushTokenKey = "com.nighthub.afterdark.remote.production.pushToken"
    private let explicitLogoutKey = "com.nighthub.afterdark.remote.production.explicitLogout"
    private let cutoverCleanupKey = "com.nighthub.afterdark.remote.production.cutoverCleanup.v1"
    private let retiredTestDefaultsKeys = [
        "com.nighthub.afterdark.remote.loginToken",
        "com.nighthub.afterdark.remote.sameInstallLogin",
        "com.nighthub.afterdark.remote.pushToken",
        "com.nighthub.afterdark.remote.explicitLogout"
    ]

    private init() {}

    var stableDeviceIdentifier: String {
        if let existing = read(account: deviceAccount), !existing.isEmpty { return existing }
        let value = UIDevice.current.identifierForVendor?.uuidString.lowercased() ?? UUID().uuidString.lowercased()
        write(value, account: deviceAccount)
        return value
    }

    var password: String? {
        read(account: passwordAccount)
    }

    var loginToken: String? {
        get {
            let value = defaults.string(forKey: tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false ? value : nil
        }
        set {
            if let value = newValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                defaults.set(value, forKey: tokenKey)
                defaults.set(true, forKey: continuityKey)
                defaults.set(false, forKey: explicitLogoutKey)
            } else {
                defaults.removeObject(forKey: tokenKey)
            }
        }
    }

    var cachedPushToken: String {
        defaults.string(forKey: pushTokenKey) ?? ""
    }

    var allowsSameInstallRecovery: Bool {
        defaults.bool(forKey: continuityKey) && !defaults.bool(forKey: explicitLogoutKey)
    }

    func persist(password: String?) {
        guard let password = password?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else { return }
        write(password, account: passwordAccount)
    }

    func persist(pushToken: String) {
        defaults.set(pushToken, forKey: pushTokenKey)
    }

    func markOrdinaryLogout() {
        loginToken = nil
        defaults.set(true, forKey: explicitLogoutKey)
    }

    func prepareForBootstrap() -> Bool {
        _ = stableDeviceIdentifier
        ["loginToken", "remoteLoginToken", "bLoginToken"].forEach { delete(account: $0) }
        guard !defaults.bool(forKey: cutoverCleanupKey) else { return false }
        retiredTestDefaultsKeys.forEach(defaults.removeObject(forKey:))
        delete(account: deviceAccount, service: retiredTestService)
        delete(account: passwordAccount, service: retiredTestService)
        ["loginToken", "remoteLoginToken", "bLoginToken"].forEach { delete(account: $0, service: retiredTestService) }
        URLCache.shared.removeAllCachedResponses()
        return true
    }

    func markProductionCutoverCleanupComplete() {
        defaults.set(true, forKey: cutoverCleanupKey)
    }

    private func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query = baseQuery(account: account)
        let attributes: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            var insertion = query
            insertion[kSecValueData as String] = data
            insertion[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(insertion as CFDictionary, nil)
        }
    }

    private func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private func delete(account: String, service: String) {
        SecItemDelete(baseQuery(account: account, service: service) as CFDictionary)
    }

    private func baseQuery(account: String, service: String? = nil) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service ?? self.service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }
}
