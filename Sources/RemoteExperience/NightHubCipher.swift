import Foundation
import CommonCrypto

enum NightHubCipherError: Error {
    case invalidKeyMaterial
    case invalidHex
    case cryptorFailure(CCCryptorStatus)
    case invalidText
}

struct NightHubCipher {
    private let key: Data
    private let iv: Data

    init(key: String, iv: String) throws {
        guard let keyData = key.data(using: .utf8), keyData.count == kCCKeySizeAES128,
              let ivData = iv.data(using: .utf8), ivData.count == kCCBlockSizeAES128 else {
            throw NightHubCipherError.invalidKeyMaterial
        }
        self.key = keyData
        self.iv = ivData
    }

    func encryptJSONObject(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return try crypt(data, operation: CCOperation(kCCEncrypt)).map { String(format: "%02x", $0) }.joined()
    }

    func decryptJSONObject(from hex: String) throws -> Any {
        let clear = try crypt(try Self.data(from: hex), operation: CCOperation(kCCDecrypt))
        return try JSONSerialization.jsonObject(with: clear, options: [.fragmentsAllowed])
    }

    private func crypt(_ input: Data, operation: CCOperation) throws -> Data {
        var output = Data(count: input.count + kCCBlockSizeAES128)
        let outputCapacity = output.count
        var moved = 0
        let status = output.withUnsafeMutableBytes { outputBytes in
            input.withUnsafeBytes { inputBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            key.count,
                            ivBytes.baseAddress,
                            inputBytes.baseAddress,
                            input.count,
                            outputBytes.baseAddress,
                            outputCapacity,
                            &moved
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else { throw NightHubCipherError.cryptorFailure(status) }
        output.removeSubrange(moved..<output.count)
        return output
    }

    private static func data(from hex: String) throws -> Data {
        let normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count.isMultiple(of: 2), !normalized.isEmpty else { throw NightHubCipherError.invalidHex }
        var data = Data(capacity: normalized.count / 2)
        var index = normalized.startIndex
        while index < normalized.endIndex {
            let next = normalized.index(index, offsetBy: 2)
            guard let value = UInt8(normalized[index..<next], radix: 16) else { throw NightHubCipherError.invalidHex }
            data.append(value)
            index = next
        }
        return data
    }
}
