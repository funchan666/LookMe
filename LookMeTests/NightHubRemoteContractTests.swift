import XCTest
@testable import LookMe

final class NightHubRemoteContractTests: XCTestCase {
    func testCipherMatchesTheBackendTestVector() throws {
        let cipher = try NightHubCipher(key: "9986sdff5s4f1123", iv: "9986sdff5s4y456a")
        let object = try XCTUnwrap(try cipher.decryptJSONObject(from: "be85f9b3b97f17a09119cf0dd4841975") as? [String: Any])
        XCTAssertEqual(object["n"] as? Int, 1)
        XCTAssertEqual(object["g"] as? Int, 1)
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

    func testTestingEnvironmentKeepsRequiredSuffixSemantics() throws {
        let environment = try XCTUnwrap(NightHubRemoteEnvironment.testing)
        XCTAssertEqual(environment.baseURL.absoluteString, "https://opi.cphub.link")
        XCTAssertEqual(environment.appIdentifier, "11111111")
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
