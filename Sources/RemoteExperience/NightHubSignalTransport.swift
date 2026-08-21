import Combine
import CoreTelephony
import Foundation
import SystemConfiguration

struct NightHubOpeningResult {
    let businessCode: String
    let message: String
    let experienceURL: URL?
    let loginRequired: Bool
    let quickLoginAvailable: Bool

    var routesToRemoteExperience: Bool {
        businessCode == "0000" && experienceURL != nil
    }
}

struct NightHubAuthenticationResult {
    let businessCode: String
    let message: String
    let token: String?
    let password: String?

    var succeeded: Bool {
        businessCode == "0000" && token?.isEmpty == false
    }
}

enum NightHubPurchaseVerification {
    case accepted(String)
    case rejected(String)
}

enum NightHubTransportError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "The remote experience is not configured correctly."
        case .invalidResponse: return "The service returned an unreadable response."
        case .server(let message): return message.isEmpty ? "The service could not complete the request." : message
        }
    }
}

final class NightHubSignalTransport {
    private struct DecodedEnvelope {
        let outerCode: String?
        let message: String
        let payload: [String: Any]
    }

    private let environment: NightHubRemoteEnvironment
    private let cipher: NightHubCipher
    private let ledger: NightHubSessionLedger
    private let session: URLSession

    init(environment: NightHubRemoteEnvironment, ledger: NightHubSessionLedger = .shared) throws {
        self.environment = environment
        self.cipher = try NightHubCipher(key: environment.aesKey, iv: environment.aesIV)
        self.ledger = ledger
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 18
        configuration.timeoutIntervalForResource = 25
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    func openExperience() -> AnyPublisher<NightHubOpeningResult, Error> {
        let fields = environment.fields
        let payload: [String: Any] = [
            fields.simPresence: Self.hasSIMCard ? 1 : 0,
            fields.vpnPresence: Self.hasActiveVPN ? 1 : 0,
            fields.serverDebug: environment.serverDebugValue,
            fields.languages: Locale.preferredLanguages,
            fields.timezone: TimeZone.current.identifier
        ]
        return send(path: environment.endpoints.opening, payload: payload)
            .tryMap { envelope in
                let map = Self.flatten(envelope.payload)
                let code = Self.string(map["code"]) ?? envelope.outerCode ?? "0000"
                let openValue = Self.string(map["openValue"])
                let url: URL? = openValue.flatMap { value -> URL? in
                    guard let candidate = URL(string: value) else { return nil }
                    guard let scheme = candidate.scheme?.lowercased(), ["http", "https"].contains(scheme), candidate.host != nil else { return nil }
                    return candidate
                }
                return NightHubOpeningResult(
                    businessCode: code,
                    message: Self.string(map["message"]) ?? envelope.message,
                    experienceURL: url,
                    loginRequired: Self.bool(map["loginFlag"]),
                    quickLoginAvailable: Self.bool(map["quickLoginFlag"])
                )
            }
            .eraseToAnyPublisher()
    }

    func authenticate() -> AnyPublisher<NightHubAuthenticationResult, Error> {
        var payload: [String: Any] = [environment.fields.deviceIdentifier: ledger.stableDeviceIdentifier]
        if let password = ledger.password { payload[environment.fields.password] = password }
        return send(path: environment.endpoints.authentication, payload: payload)
            .tryMap { envelope in
                let map = Self.flatten(envelope.payload)
                let code = Self.string(map["code"]) ?? envelope.outerCode ?? ""
                let token = Self.string(map["token"])
                let password = Self.string(map["password"])
                let message = Self.string(map["message"]) ?? envelope.message
                return NightHubAuthenticationResult(businessCode: code, message: message, token: token, password: password)
            }
            .eraseToAnyPublisher()
    }

    func verifyPurchase(transactionIdentifier: String, receipt: String, orderIdentifier: String) -> AnyPublisher<NightHubPurchaseVerification, Error> {
        let payload: [String: Any] = [
            environment.fields.transactionIdentifier: transactionIdentifier,
            environment.fields.receiptPayload: receipt,
            environment.fields.purchaseContext: orderIdentifier
        ]
        return send(path: environment.endpoints.purchaseVerification, payload: payload)
            .map { envelope in
                let map = Self.flatten(envelope.payload)
                let code = Self.string(map["code"]) ?? envelope.outerCode ?? ""
                let message = Self.string(map["message"]) ?? envelope.message
                return ["0000", "0"].contains(code) ? .accepted(message) : .rejected(message)
            }
            .eraseToAnyPublisher()
    }

    func reportFirstFrame(milliseconds: Int64) {
        let payload: [String: Any] = [environment.fields.firstFrameMilliseconds: String(milliseconds)]
        var cancellable: AnyCancellable?
        cancellable = send(path: environment.endpoints.firstFrameReport, payload: payload)
            .sink(receiveCompletion: { _ in cancellable?.cancel() }, receiveValue: { _ in })
    }

    func authenticatedExperienceURL(baseURL: URL, token: String) throws -> URL {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let encrypted = try cipher.encryptJSONObject(["token": token, "timestamp": String(timestamp)])
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { throw NightHubTransportError.invalidConfiguration }
        var items = components.queryItems ?? []
        items.removeAll { ["openParams", "appId"].contains($0.name) }
        items.append(URLQueryItem(name: "openParams", value: encrypted))
        items.append(URLQueryItem(name: "appId", value: environment.appIdentifier))
        components.queryItems = items
        guard let url = components.url else { throw NightHubTransportError.invalidConfiguration }
        return url
    }

    private func send(path: String, payload: [String: Any]) -> AnyPublisher<DecodedEnvelope, Error> {
        do {
            guard path.hasPrefix("/opi/v1/"), let suffix = path.last, ["o", "l", "p", "t"].contains(suffix),
                  let url = URL(string: path, relativeTo: environment.baseURL)?.absoluteURL else {
                throw NightHubTransportError.invalidConfiguration
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(environment.appIdentifier, forHTTPHeaderField: "appId")
            request.setValue(Self.appVersion, forHTTPHeaderField: "appVersion")
            request.setValue(ledger.stableDeviceIdentifier, forHTTPHeaderField: "deviceNo")
            request.setValue(ledger.cachedPushToken, forHTTPHeaderField: "pushToken")
            if let token = ledger.loginToken { request.setValue(token, forHTTPHeaderField: "loginToken") }
            request.httpBody = Data(try cipher.encryptJSONObject(payload).utf8)
            return session.dataTaskPublisher(for: request)
                .tryMap { [cipher] output in
                    guard let response = output.response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                        throw NightHubTransportError.server("The service is temporarily unavailable.")
                    }
                    return try Self.decode(data: output.data, cipher: cipher)
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private static func decode(data: Data, cipher: NightHubCipher) throws -> DecodedEnvelope {
        guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw NightHubTransportError.invalidResponse
        }
        if let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]), let dictionary = object as? [String: Any] {
            let outerCode = string(dictionary["code"])
            let message = string(dictionary["message"]) ?? ""
            if let encrypted = dictionary["result"] as? String ?? dictionary["data"] as? String,
               let decrypted = try? cipher.decryptJSONObject(from: encrypted), let map = decrypted as? [String: Any] {
                return DecodedEnvelope(outerCode: outerCode, message: message, payload: map)
            }
            return DecodedEnvelope(outerCode: outerCode, message: message, payload: dictionary)
        }
        guard let decrypted = try? cipher.decryptJSONObject(from: text), let map = decrypted as? [String: Any] else {
            throw NightHubTransportError.invalidResponse
        }
        return DecodedEnvelope(outerCode: string(map["code"]), message: string(map["message"]) ?? "", payload: map)
    }

    private static func flatten(_ map: [String: Any]) -> [String: Any] {
        if let nested = map["data"] as? [String: Any] { return nested.merging(map) { nestedValue, _ in nestedValue } }
        return map
    }

    private static func string(_ value: Any?) -> String? {
        if let value = value as? String { return value }
        if let value = value as? NSNumber { return value.stringValue }
        return nil
    }

    private static func bool(_ value: Any?) -> Bool {
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.intValue == 1 }
        if let string = value as? String { return ["1", "true", "yes"].contains(string.lowercased()) }
        return false
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private static var hasSIMCard: Bool {
        let providers = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders
        return providers?.values.contains(where: { $0.mobileCountryCode?.isEmpty == false }) == true
    }

    private static var hasActiveVPN: Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = settings["__SCOPED__"] as? [String: Any] else { return false }
        return scoped.keys.contains { key in
            let lower = key.lowercased()
            return lower.contains("tap") || lower.contains("tun") || lower.contains("ppp") || lower.contains("ipsec") || lower.contains("utun")
        }
    }
}
