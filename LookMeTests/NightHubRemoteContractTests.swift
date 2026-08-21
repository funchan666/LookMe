import XCTest
@testable import LookMe

final class NightHubRemoteContractTests: XCTestCase {
    func testCipherRoundTripsAJSONPayload() throws {
        let cipher = try NightHubCipher(key: "0123456789abcdef", iv: "fedcba9876543210")
        let encrypted = try cipher.encryptJSONObject(["state": "ready", "count": 2])
        let object = try XCTUnwrap(try cipher.decryptJSONObject(from: encrypted) as? [String: Any])
        XCTAssertEqual(object["state"] as? String, "ready")
        XCTAssertEqual(object["count"] as? Int, 2)
    }

    func testBridgeAcceptsOnlyExactStringArrays() {
        XCTAssertEqual(NightHubBridgeContract.stringArray(from: ["sku", "order"], count: 2), ["sku", "order"])
        XCTAssertEqual(NightHubBridgeContract.stringArray(from: "[\"system\",\"https://example.com\"]", count: 2), ["system", "https://example.com"])
        XCTAssertNil(NightHubBridgeContract.stringArray(from: ["sku"], count: 2))
        XCTAssertNil(NightHubBridgeContract.stringArray(from: ["sku", 42], count: 2))
        XCTAssertNil(NightHubBridgeContract.stringArray(from: ["batchNo": "sku"], count: 2))
        XCTAssertNil(NightHubBridgeContract.stringArray(from: "order", count: 1))
        XCTAssertNil(NightHubBridgeContract.stringArray(from: "{\"url\":\"https://example.com\"}", count: 2))
    }

    func testBrowserContractAllowsOnlySystemHTTPAndHTTPS() {
        XCTAssertEqual(NightHubBridgeContract.validatedSystemURL(from: ["system", "https://example.com/path"])?.scheme, "https")
        XCTAssertEqual(NightHubBridgeContract.validatedSystemURL(from: ["system", "http://example.com"])?.scheme, "http")
        XCTAssertNil(NightHubBridgeContract.validatedSystemURL(from: ["embedded", "https://example.com"]))
        XCTAssertNil(NightHubBridgeContract.validatedSystemURL(from: ["system", "nighthub://purchase"]))
        XCTAssertNil(NightHubBridgeContract.validatedSystemURL(from: ["system", "javascript:alert(1)"]))
        XCTAssertNil(NightHubBridgeContract.validatedSystemURL(from: ["system", "file:///tmp/item"]))
    }

    func testProductionEnvironmentKeepsRequiredSecurityAndSuffixSemantics() throws {
        let environment = try XCTUnwrap(NightHubRemoteEnvironment.production)
        XCTAssertEqual(environment.baseURL.scheme, "https")
        XCTAssertNotNil(environment.baseURL.host)
        XCTAssertFalse(environment.appIdentifier.isEmpty)
        XCTAssertEqual(environment.aesKey.lengthOfBytes(using: .utf8), 16)
        XCTAssertEqual(environment.aesIV.lengthOfBytes(using: .utf8), 16)
        XCTAssertEqual(environment.serverDebugValue, 0)
        XCTAssertTrue(environment.endpoints.opening.hasSuffix("o"))
        XCTAssertTrue(environment.endpoints.authentication.hasSuffix("l"))
        XCTAssertTrue(environment.endpoints.purchaseVerification.hasSuffix("p"))
        XCTAssertTrue(environment.endpoints.firstFrameReport.hasSuffix("t"))
        XCTAssertTrue(environment.fields.simPresence.hasSuffix("d"))
        XCTAssertTrue(environment.fields.vpnPresence.hasSuffix("n"))
        XCTAssertTrue(environment.fields.serverDebug.hasSuffix("g"))
        XCTAssertTrue(environment.fields.transactionIdentifier.hasSuffix("t"))
        XCTAssertTrue(environment.fields.receiptPayload.hasSuffix("p"))
        XCTAssertTrue(environment.fields.purchaseContext.hasSuffix("c"))
    }
}
