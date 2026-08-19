import XCTest
import UIKit
@testable import LookMe

final class LookMeTests: XCTestCase {
    func testRelativeTimesFollowTheInAppLanguageInsteadOfTheDeviceLanguage() {
        let center = LookMeLanguageCenter.shared
        let original = center.selectedLanguage
        defer { center.select(original) }
        let reference = Date(timeIntervalSince1970: 2_000_000)
        center.select(.english)
        let english = center.relativeTime(from: reference.addingTimeInterval(-7_200), relativeTo: reference)
        XCTAssertTrue(english.contains("hour"), "Expected an English relative time, got \(english)")
        XCTAssertNil(english.range(of: "[\\p{Han}]", options: .regularExpression))
    }

    func testCommunityCountriesUseMatchingDiscoveryRegions() {
        let amara = try! XCTUnwrap(LookMeCommunityDirectory.members.first(where: { $0.name == "Amara Ndlovu" }))
        XCTAssertEqual(amara.country, "🇿🇦")
        XCTAssertEqual(amara.region, "Africa")
        XCTAssertEqual(PresenceDiscoveryViewController.discoveryRegion(for: "ZA"), "Africa")
        XCTAssertEqual(PresenceDiscoveryViewController.discoveryRegion(for: "JP"), "Asia")
        XCTAssertEqual(PresenceDiscoveryViewController.discoveryRegion(for: "US"), "North America")
        XCTAssertFalse(LookMeCommunityDirectory.members.contains(where: { $0.country == "🇿🇦" && $0.region == "Asia" }))
    }

    func testCommunityProfilesHaveDistinctKeysAndMappedPortraits() {
        XCTAssertEqual(Set(LookMeCommunityDirectory.members.map(\.profileKey)).count, LookMeCommunityDirectory.members.count)
        XCTAssertTrue(LookMeCommunityDirectory.members.allSatisfy { !$0.portraitAssetName.isEmpty })
    }

    func testEveryCommunityProfileHasConversationSpecificContext() {
        XCTAssertTrue(LookMeCommunityDirectory.members.allSatisfy { !$0.displayName.isEmpty && !$0.profileNote.isEmpty })
        XCTAssertTrue(LookMeCommunityDirectory.members.allSatisfy { $0.interestSignals.count == 3 && !$0.conversationDoorway.isEmpty })
    }

    func testEveryProvidedImageAndVideoIsMappedIntoTheProduct() {
        XCTAssertEqual(CommunityMediaRegistry.images.count, 47)
        XCTAssertEqual(Set(CommunityMediaRegistry.images).count, 47)
        XCTAssertFalse(CommunityMediaRegistry.images.contains(CommunityMediaRegistry.currentUserAvatarAsset))
        XCTAssertNotNil(UIImage(named: CommunityMediaRegistry.currentUserAvatarAsset))
        XCTAssertEqual(LookMeCommunityDirectory.members.map(\.portraitAssetName), CommunityMediaRegistry.images)
        XCTAssertTrue(CommunityMediaRegistry.images.allSatisfy { UIImage(named: $0) != nil })
        XCTAssertEqual(CommunityMediaRegistry.videos.count, 17)
        XCTAssertEqual(Set(CommunityMediaRegistry.videos).count, 17)
        XCTAssertTrue(Set(CommunityMediaRegistry.reelVideos).isDisjoint(with: Set(CommunityMediaRegistry.liveVideos)))
        XCTAssertGreaterThanOrEqual(LookMeCommunityDirectory.members.count, CommunityMediaRegistry.reelVideos.count)
        XCTAssertEqual(Set(LookMeCommunityDirectory.members.filter(\.isBroadcasting).map(CommunityMediaRegistry.liveVideo(for:))), Set(CommunityMediaRegistry.liveVideos))
        XCTAssertTrue(CommunityMediaRegistry.videos.allSatisfy { Bundle.main.url(forResource: $0, withExtension: nil) != nil })
    }

    func testVoiceRoomCoversNeverRepeatLiveRoomCards() {
        let voiceCovers = Set(CommunityMediaRegistry.voiceRoomCoverAssets)
        let liveRoomCards = Set(LookMeCommunityDirectory.members.filter(\.isBroadcasting).map(\.portraitAssetName))
        XCTAssertEqual(voiceCovers.count, CommunityMediaRegistry.voiceRoomCoverAssets.count)
        XCTAssertTrue(voiceCovers.isDisjoint(with: liveRoomCards))
        XCTAssertTrue(voiceCovers.allSatisfy { UIImage(named: $0) != nil })
    }

    func testReelsUseDistinctConversationVolumesAndCopy() {
        let coverage = LookMeExperienceStore.reelConversationCoverage
        XCTAssertEqual(Set(coverage.keys), Set(CommunityMediaRegistry.reelVideos))
        XCTAssertEqual(coverage.mapValues(\.count), [
            "sunlit-sidewalk.mp4": 2,
            "evening-driving-range.mp4": 4,
            "railway-greenway.mp4": 5,
            "boulevard-selfie.mp4": 1,
            "brownstone-style.mp4": 6,
            "cliffside-dive.mp4": 3,
            "trail-conversation.mp4": 4,
            "canal-city-walk.mp4": 2
        ])
        XCTAssertEqual(Set(coverage.values.map(\.count)), Set(1...6))
        XCTAssertEqual(Set(coverage.values.flatMap { $0 }).count, coverage.values.reduce(0) { $0 + $1.count })
    }

    func testEveryReelHasDistinctEditorialCopy() {
        let stories = CommunityMediaRegistry.reelStories
        XCTAssertEqual(stories.count, CommunityMediaRegistry.reelVideos.count)
        XCTAssertEqual(Set(stories.map(\.videoAssetName)), Set(CommunityMediaRegistry.reelVideos))
        XCTAssertEqual(Set(stories.map(\.sceneCaption)).count, stories.count)
        XCTAssertTrue(stories.allSatisfy { !$0.sceneCaption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    func testLiveBroadcastsHaveRoomSpecificCountsTopicsAndActivity() {
        let liveMembers = LookMeCommunityDirectory.members.filter(\.isLive)
        let editorials = liveMembers.map(CommunityMediaRegistry.liveEditorial(for:))
        XCTAssertEqual(Set(editorials.map(\.viewerCount)).count, liveMembers.count)
        XCTAssertEqual(Set(editorials.map(\.appreciationCount)).count, liveMembers.count)
        XCTAssertTrue(editorials.allSatisfy { (10...120).contains($0.viewerCount) })
        XCTAssertTrue(editorials.allSatisfy { (30...420).contains($0.appreciationCount) })
        XCTAssertGreaterThanOrEqual(Set(editorials.map(\.roomPrompt)).count, CommunityMediaRegistry.liveVideos.count)
        XCTAssertTrue(editorials.allSatisfy { $0.bulletins.count >= 4 })
        XCTAssertTrue(editorials.allSatisfy { $0.bulletins.contains(where: { $0.giftSymbol != nil }) })
    }

    func testVoiceRoomsReceiveTopicSpecificConversationAndGiftActivity() {
        let covers = Array(CommunityMediaRegistry.images.prefix(3))
        let rooms = (0..<6).map { index in
            InterestRoomBlueprint(roomKey: "editorial-room-\(index)", roomTitle: "Room \(index)", roomSummary: "A distinct listening topic", coverAssetName: covers[index % covers.count], participantPortraitAssets: covers, liveAudienceCount: 40 + index, topicLabel: "Topic \(index)", hostProfileKey: nil, isCommunityCreated: false)
        }
        let activity = rooms.map(CommunityMediaRegistry.voiceEditorial(for:))
        let signatures = activity.map { $0.map(\.activityText).joined(separator: "|") }
        XCTAssertEqual(Set(signatures).count, rooms.count)
        XCTAssertTrue(activity.allSatisfy { $0.contains(where: { $0.giftSymbol != nil }) })
    }

    func testLoginAcceptsFormattedEmailAndSixCharacterPassword() {
        XCTAssertTrue(LoginValidation.isValidEmail("hello@example.com"))
        XCTAssertTrue(LoginValidation.isValidPassword("123456"))
        XCTAssertFalse(LoginValidation.isValidEmail("hello@"))
        XCTAssertFalse(LoginValidation.isValidPassword("12345"))
    }

    func testLegalPagesUseTheConfiguredHTTPSAddresses() {
        XCTAssertEqual(PolicyKind.terms.remoteURL?.absoluteString, "https://sites.google.com/view/lookme-terms-of-service/home")
        XCTAssertEqual(PolicyKind.privacy.remoteURL?.absoluteString, "https://sites.google.com/view/lookme-privacypolicy/home")
        XCTAssertNil(PolicyKind.community.remoteURL)
    }

    func testRequiredCoinProductsKeepTheirExactPriceAndIdentifiers() {
        let required = [
            "yusumvtayfbcjlzr": "149.99",
            "uvhfntfqftmppfby": "99.99",
            "uboaynpdevvevaif": "49.99",
            "bfydbuxftbusaqiq": "19.99",
            "ffthvfpycfqnceox": "9.99",
            "mazqovirzlcftvhi": "4.99",
            "yigmnvtxnjnmqlzd": "2.99",
            "iphmxaehlokhqbct": "1.99",
            "pnbbupnbuvktgbuz": "0.99"
        ]
        XCTAssertEqual(CoinPackage.all.count, 9)
        for (identifier, price) in required {
            XCTAssertEqual(CoinPackage.package(for: identifier)?.price, price)
            XCTAssertGreaterThan(CoinPackage.package(for: identifier)?.coins ?? 0, 0)
        }
        XCTAssertEqual(Set(CoinPackage.all.map(\.productID)).count, CoinPackage.all.count)
    }

    func testContentPolicySeparatesSafetyCategoriesFromNormalConversation() {
        XCTAssertTrue(LookMeContentPolicy.evaluate("What album changed how you listen to music?").isAllowed)
        XCTAssertEqual(LookMeContentPolicy.evaluate("send nude photos").rejectionReason, .sexualSolicitation)
        XCTAssertEqual(LookMeContentPolicy.evaluate("you should die").rejectionReason, .threatOrSelfHarm)
        XCTAssertEqual(LookMeContentPolicy.evaluate("wire me money for guaranteed profit").rejectionReason, .scamOrContactSpam)
        XCTAssertEqual(LookMeContentPolicy.evaluate("aaaaaaaaaaaaaaaaaaaa").rejectionReason, .repeatedNoise)
    }

    func testFiveInterfaceLanguagesAreBundledAndSelectable() {
        let center = LookMeLanguageCenter.shared
        let original = center.selectedLanguage
        defer { center.select(original) }
        XCTAssertEqual(LookMeInterfaceLanguage.allCases.count, 5)

        let expectedSettings = [
            LookMeInterfaceLanguage.english: "Settings",
            .simplifiedChinese: "设置",
            .spanish: "Ajustes",
            .japanese: "設定",
            .german: "Einstellungen"
        ]
        for language in LookMeInterfaceLanguage.allCases {
            center.select(language)
            XCTAssertEqual(center.text("Settings"), expectedSettings[language])
            XCTAssertFalse(center.text("App language").isEmpty)
        }
    }
}
