import Foundation

struct NightHubRemoteEnvironment {
    struct EndpointMap {
        let opening: String
        let authentication: String
        let purchaseVerification: String
        let firstFrameReport: String
    }

    struct FieldMap {
        let simPresence: String
        let vpnPresence: String
        let serverDebug: String
        let languages: String
        let timezone: String
        let password: String
        let deviceIdentifier: String
        let transactionIdentifier: String
        let receiptPayload: String
        let purchaseContext: String
        let firstFrameMilliseconds: String
    }

    let baseURL: URL
    let appIdentifier: String
    let aesKey: String
    let aesIV: String
    let endpoints: EndpointMap
    let fields: FieldMap
    let serverDebugValue: Int

    static let testing: NightHubRemoteEnvironment? = {
        guard let baseURL = URL(string: "https://opi.cphub.link") else { return nil }
        return NightHubRemoteEnvironment(
            baseURL: baseURL,
            appIdentifier: "11111111",
            aesKey: "9986sdff5s4f1123",
            aesIV: "9986sdff5s4y456a",
            endpoints: EndpointMap(
                opening: "/opi/v1/night/thresholdo",
                authentication: "/opi/v1/afterglow/entryl",
                purchaseVerification: "/opi/v1/coinvault/settlep",
                firstFrameReport: "/opi/v1/moment/frameclockt"
            ),
            fields: FieldMap(
                simPresence: "lanternd",
                vpnPresence: "midnightn",
                serverDebug: "starlightg",
                languages: "voicescapee",
                timezone: "nightzonet",
                password: "vaultpassd",
                deviceIdentifier: "presencekeyn",
                transactionIdentifier: "coinreceiptt",
                receiptPayload: "storeproofp",
                purchaseContext: "ordertrailc",
                firstFrameMilliseconds: "frameelapsedo"
            ),
            serverDebugValue: 1
        )
    }()
}
