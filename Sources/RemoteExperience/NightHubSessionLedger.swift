import Foundation
import Security
import UIKit

final class NightHubSessionLedger {
    static let shared = NightHubSessionLedger()

    private let service = "com.nighthub.afterdark.remote.identity"
    private let deviceAccount = "night-presence-device"
    private let passwordAccount = "night-presence-password"
    private let tokenKey = "com.nighthub.afterdark.remote.loginToken"
    private let continuityKey = "com.nighthub.afterdark.remote.sameInstallLogin"
    private let pushTokenKey = "com.nighthub.afterdark.remote.pushToken"
    private let explicitLogoutKey = "com.nighthub.afterdark.remote.explicitLogout"

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
            let value = UserDefaults.standard.string(forKey: tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false ? value : nil
        }
        set {
            if let value = newValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                UserDefaults.standard.set(value, forKey: tokenKey)
                UserDefaults.standard.set(true, forKey: continuityKey)
                UserDefaults.standard.set(false, forKey: explicitLogoutKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }

    var cachedPushToken: String {
        UserDefaults.standard.string(forKey: pushTokenKey) ?? ""
    }

    var allowsSameInstallRecovery: Bool {
        UserDefaults.standard.bool(forKey: continuityKey) && !UserDefaults.standard.bool(forKey: explicitLogoutKey)
    }

    func persist(password: String?) {
        guard let password = password?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty else { return }
        write(password, account: passwordAccount)
    }

    func persist(pushToken: String) {
        UserDefaults.standard.set(pushToken, forKey: pushTokenKey)
    }

    func markOrdinaryLogout() {
        loginToken = nil
        UserDefaults.standard.set(true, forKey: explicitLogoutKey)
    }

    func prepareForBootstrap() {
        _ = stableDeviceIdentifier
        ["loginToken", "remoteLoginToken", "bLoginToken"].forEach { delete(account: $0) }
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

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }
}
