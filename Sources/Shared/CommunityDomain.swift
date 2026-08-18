import Foundation

struct CommunityProfile: Hashable, Codable {
    let profileKey: String
    let displayName: String
    let declaredAge: Int
    let localeFlag: String
    let discoveryRegion: String
    let portraitAssetName: String
    let profileNote: String
    let isBroadcasting: Bool
    let presenceTier: String
    let interestSignals: [String]
    let conversationDoorway: String
    let availabilityPulse: String

    // Compatibility accessors keep already-shipped persisted relationships readable
    // while new domain code uses the product-specific vocabulary above.
    var id: String { profileKey }
    var name: String { displayName }
    var age: Int { declaredAge }
    var country: String { localeFlag }
    var region: String { discoveryRegion }
    var image: String { portraitAssetName }
    var bio: String { profileNote }
    var isLive: Bool { isBroadcasting }
    var rank: String { presenceTier }
}

struct ReelEditorialStory: Hashable {
    let videoAssetName: String
    let sceneCaption: String
}

struct LiveRoomBulletin: Hashable {
    let authorProfileKey: String
    let authorDisplayName: String
    let activityText: String
    let giftSymbol: String?
}

struct LiveBroadcastEditorial: Hashable {
    let viewerCount: Int
    let appreciationCount: Int
    let roomPrompt: String
    let bulletins: [LiveRoomBulletin]
}

struct VoiceRoomBulletin: Hashable {
    let authorProfileKey: String
    let authorDisplayName: String
    let activityText: String
    let giftSymbol: String?
}

struct DirectConversationEntry: Codable, Hashable {
    let conversationEntryKey: UUID
    let counterpartProfileKey: String
    let messageBody: String
    let authoredByCurrentUser: Bool
    let deliveredAt: Date
    var id: UUID { conversationEntryKey }
    var memberID: String { counterpartProfileKey }
    var text: String { messageBody }
    var isMine: Bool { authoredByCurrentUser }
    var sentAt: Date { deliveredAt }
    enum CodingKeys: String, CodingKey { case conversationEntryKey = "id", counterpartProfileKey = "memberID", messageBody = "text", authoredByCurrentUser = "isMine", deliveredAt = "sentAt" }
}

struct RoomConversationEntry: Codable, Hashable {
    let roomEntryKey: UUID
    let roomKey: String
    let authorProfileKey: String
    let authorDisplayName: String
    let messageBody: String
    let deliveredAt: Date
    var id: UUID { roomEntryKey }
    var roomID: String { roomKey }
    var authorID: String { authorProfileKey }
    var authorName: String { authorDisplayName }
    var text: String { messageBody }
    var sentAt: Date { deliveredAt }
    enum CodingKeys: String, CodingKey { case roomEntryKey = "id", roomKey = "roomID", authorProfileKey = "authorID", authorDisplayName = "authorName", messageBody = "text", deliveredAt = "sentAt" }
}

struct CommunityMomentRecord: Codable, Hashable {
    let momentKey: UUID
    let authorDisplayName: String
    var authorProfileKey: String? = nil
    var momentText: String
    var bundledImageAsset: String?
    var capturedMediaPath: String? = nil
    var mediaKind: String? = nil
    var likedByCurrentUser: Bool
    var appreciationCount: Int
    let submittedAt: Date
    var id: UUID { momentKey }
    var author: String { authorDisplayName }
    var authorID: String? { authorProfileKey }
    var text: String { get { momentText } set { momentText = newValue } }
    var image: String? { get { bundledImageAsset } set { bundledImageAsset = newValue } }
    var mediaPath: String? { get { capturedMediaPath } set { capturedMediaPath = newValue } }
    var mediaType: String? { get { mediaKind } set { mediaKind = newValue } }
    var liked: Bool { get { likedByCurrentUser } set { likedByCurrentUser = newValue } }
    var likes: Int { get { appreciationCount } set { appreciationCount = newValue } }
    var createdAt: Date { submittedAt }
    enum CodingKeys: String, CodingKey { case momentKey = "id", authorDisplayName = "author", authorProfileKey = "authorID", momentText = "text", bundledImageAsset = "image", capturedMediaPath = "mediaPath", mediaKind = "mediaType", likedByCurrentUser = "liked", appreciationCount = "likes", submittedAt = "createdAt" }
}

struct CommunityReplyRecord: Codable, Hashable {
    let replyKey: UUID
    let parentContentKey: String
    let authorProfileKey: String
    let authorDisplayName: String
    let replyText: String
    let submittedAt: Date
    var id: UUID { replyKey }
    var contentID: String { parentContentKey }
    var authorID: String { authorProfileKey }
    var authorName: String { authorDisplayName }
    var text: String { replyText }
    var createdAt: Date { submittedAt }
    enum CodingKeys: String, CodingKey { case replyKey = "id", parentContentKey = "contentID", authorProfileKey = "authorID", authorDisplayName = "authorName", replyText = "text", submittedAt = "createdAt" }
}

struct SafetyReportRecord: Codable, Hashable {
    let reportKey: UUID
    let reportedContentKey: String
    let reportedContentKind: String
    let reportedProfileKey: String?
    let categoryReason: String
    let recordedAt: Date
    var id: UUID { reportKey }
    var targetID: String { reportedContentKey }
    var targetType: String { reportedContentKind }
    var userID: String? { reportedProfileKey }
    var reason: String { categoryReason }
    var createdAt: Date { recordedAt }
    enum CodingKeys: String, CodingKey { case reportKey = "id", reportedContentKey = "targetID", reportedContentKind = "targetType", reportedProfileKey = "userID", categoryReason = "reason", recordedAt = "createdAt" }
}

struct ActivityNoticeRecord: Codable, Hashable {
    let noticeKey: UUID
    let eventKind: String
    let relatedProfileKey: String?
    let headline: String
    let detailText: String
    let recordedAt: Date
    var hasBeenRead: Bool
    var id: UUID { noticeKey }
    var kind: String { eventKind }
    var memberID: String? { relatedProfileKey }
    var title: String { headline }
    var body: String { detailText }
    var createdAt: Date { recordedAt }
    var isRead: Bool { get { hasBeenRead } set { hasBeenRead = newValue } }
    enum CodingKeys: String, CodingKey { case noticeKey = "id", eventKind = "kind", relatedProfileKey = "memberID", headline = "title", detailText = "body", recordedAt = "createdAt", hasBeenRead = "isRead" }
}

struct CollectedEffectRecord: Codable, Hashable {
    let effectKey: String
    let effectName: String
    let symbolGlyph: String
    var ownedQuantity: Int
    var id: String { effectKey }
    var name: String { effectName }
    var symbol: String { symbolGlyph }
    var quantity: Int { get { ownedQuantity } set { ownedQuantity = newValue } }
    enum CodingKeys: String, CodingKey { case effectKey = "id", effectName = "name", symbolGlyph = "symbol", ownedQuantity = "quantity" }
}

struct InterestRoomBlueprint: Codable, Hashable {
    let roomKey: String
    let roomTitle: String
    let roomSummary: String
    let coverAssetName: String
    let participantPortraitAssets: [String]
    let liveAudienceCount: Int
    let topicLabel: String
    let hostProfileKey: String?
    let isCommunityCreated: Bool

    var participants: [CommunityProfile] {
        LookMeCommunityDirectory.members.filter {
            participantPortraitAssets.contains($0.portraitAssetName) && !LookMeExperienceStore.shared.blockedUsers.contains($0.profileKey)
        }
    }
    var host: CommunityProfile {
        if let hostProfileKey, let profile = LookMeCommunityDirectory.members.first(where: { $0.profileKey == hostProfileKey }) { return profile }
        return participants.first ?? LookMeCommunityDirectory.members[0]
    }

    // Read-only view vocabulary used by the existing room presentation layer.
    var id: String { roomKey }
    var title: String { roomTitle }
    var subtitle: String { roomSummary }
    var image: String { coverAssetName }
    var guests: [String] { participantPortraitAssets }
    var online: Int { liveAudienceCount }
    var tag: String { topicLabel }
}

enum LookMeCommunityDirectory {
    private static let names = ["Mia Calder", "Sofía Marin", "Nora Weiss", "Aiko Tanabe", "Elena Brooks", "Theo Mercer", "Luca Bellini", "Chloe Dumas", "Amara Ndlovu", "Freya Solberg", "Lily Hart", "Clara Vogel", "Eva Novák", "Zoey Hayes", "Iris Lim", "Maya Rao", "Oliver Reed", "Layla Benali", "Tessa de Vries", "Noah Walker", "Ava Costa", "Ruby Quinn", "Grace Park", "Leo Moreau", "Maeve Clarke", "Nina Romano", "Isla Jónsdóttir", "Emi Kuroda", "Ella Romero", "Aria Souza", "Yuna Seo", "Rina Koh", "Jade Lin", "Lena Laurent", "Camille Roy", "Sienna Cole", "Ada Wilson", "Mila Reyes", "Skye Baumann", "Naya Santos", "Belle Janssens", "Clara Mendes", "Dani Okafor", "Grace Mbele", "Imani Carter", "Keisha Adeyemi", "Lena Voss", "Priya Shah"]
    private static let countries = ["🇺🇸", "🇪🇸", "🇩🇪", "🇯🇵", "🇫🇷", "🇬🇧", "🇮🇹", "🇨🇦", "🇿🇦", "🇳🇴", "🇦🇺", "🇩🇪", "🇨🇿", "🇺🇸", "🇸🇬", "🇮🇳", "🇬🇧", "🇲🇦", "🇳🇱", "🇺🇸", "🇵🇹", "🇮🇪", "🇰🇷", "🇫🇷", "🇬🇧", "🇮🇹", "🇮🇸", "🇯🇵", "🇪🇸", "🇧🇷", "🇰🇷", "🇸🇬", "🇨🇳", "🇫🇷", "🇨🇦", "🇺🇸", "🇳🇿", "🇲🇽", "🇨🇭", "🇵🇭", "🇧🇪", "🇵🇹", "🇳🇬", "🇿🇦", "🇺🇸", "🇳🇬", "🇩🇪", "🇮🇳"]
    private static let profileNotes = [
        "Collecting quiet city corners, strong coffee and thoughtful conversation.",
        "Weekend walks, live sets and the tiny details that make a place memorable.",
        "Designing by day; trading playlists and creative sparks after hours.",
        "Travel notes, neighborhood food and friendships that grow without rushing.",
        "Museum afternoons, film photography and questions with no one-line answer.",
        "Always curious about how people make a new city feel like home.",
        "Cooking for friends, finding overlooked records and planning slow Sundays.",
        "Here for kind humor, honest stories and recommendations worth saving.",
        "Learning languages through music, menus and patient conversation.",
        "A morning swimmer with a soft spot for bookstores and late jazz.",
        "Architecture walks, indie cinema and conversations that wander somewhere new.",
        "Sharing small wins, useful local finds and a carefully edited camera roll."
    ]
    private static let interestCatalog = ["City walks", "Live music", "Coffee", "Photography", "Design", "Cinema", "Cooking", "Books", "Travel notes", "Wellness", "Languages", "Architecture"]
    private static let doorways = ["Ask me about the best view I found this week.", "Trade one song you never skip.", "Tell me which place feels most like home.", "Share a small creative project you're proud of.", "Recommend a meal worth crossing town for.", "What detail made your day better?"]
    private static let availability = ["Open to a thoughtful hello", "Listening between city walks", "Sharing bright ideas today", "Around for a calm conversation"]
    private static func discoveryRegion(for flag: String) -> String {
        switch flag {
        case "🇺🇸", "🇨🇦": return "North America"
        case "🇪🇸", "🇩🇪", "🇫🇷", "🇬🇧", "🇮🇹", "🇳🇴", "🇨🇿", "🇳🇱", "🇵🇹", "🇮🇪", "🇮🇸", "🇨🇭", "🇧🇪": return "Europe"
        case "🇯🇵", "🇸🇬", "🇰🇷", "🇨🇳", "🇵🇭": return "Asia"
        case "🇮🇳": return "India"
        case "🇧🇷", "🇲🇽": return "Latin"
        case "🇲🇦": return "MENA"
        case "🇿🇦", "🇳🇬": return "Africa"
        case "🇦🇺", "🇳🇿": return "Oceania"
        default: return "Global"
        }
    }
    static let members: [CommunityProfile] = CommunityMediaRegistry.images.enumerated().map { index, image in
        let region = discoveryRegion(for: countries[index])
        let interests = [interestCatalog[index % interestCatalog.count], interestCatalog[(index + 3) % interestCatalog.count], interestCatalog[(index + 7) % interestCatalog.count]]
        return CommunityProfile(
            profileKey: "member-\(index)",
            displayName: names[index],
            declaredAge: 22 + index % 12,
            localeFlag: countries[index],
            discoveryRegion: region,
            portraitAssetName: image,
            profileNote: profileNotes[index % profileNotes.count],
            isBroadcasting: index % 3 != 1,
            presenceTier: ["Orbit", "Muse", "Pulse", "Glow"][index % 4],
            interestSignals: interests,
            conversationDoorway: doorways[index % doorways.count],
            availabilityPulse: availability[index % availability.count]
        )
    }
}

enum CommunityMediaRegistry {
    static let currentUserAvatarAsset = "riverside-black-dress.jpg"
    static let images = [
        "boulevard-snack-stop.jpg", "soft-morning-portrait.jpg", "alpine-ridge-lookout.jpg", "gallery-eye-portrait.jpg", "waterfront-blue-sky.jpg", "cliffside-sunset.jpg",
        "cafe-step-portrait.jpg", "riverside-wheel-view.jpg", "evening-cat-cafe.jpg", "highland-summit.jpg", "garden-balcony.jpg", "brick-lane-style.jpg",
        "city-pop-evening.jpg", "yellow-cab-corner.jpg", "harbor-rail-pose.jpg", "canal-afternoon.jpg", "london-street.jpg", "harbor-cap-look.jpg",
        "train-window-light.jpg", "modern-city-square.jpg", "daydream-closeup.jpg", "evening-red-dress.jpg", "meadow-dog-picnic.jpg", "mirror-daylight.jpg",
        "green-cap-profile.jpg", "great-wall-rest.jpg", "park-picnic.jpg", "old-town-dress.jpg", "terrace-sunglasses.jpg", "headphone-mirror.jpg",
        "canyon-hike.jpg", "watch-district-walk.jpg", "skyline-evening.jpg", "street-camera-reflection.jpg", "car-window-portrait.webp", "coastal-friends.jpg",
        "lakefront-breeze.jpg", "sunhat-lakeside.jpg", "mountain-lake-stop.jpg", "rocky-trail-smile.jpg", "city-icecream-walk.jpg",
        "crosswalk-daylight.jpg", "old-town-gelato.jpg", "metro-bandana.jpg", "studio-headphone.jpg", "sunhat-blue-sky.jpg", "garden-yellow-top.jpg"
    ]
    static let reelStories: [ReelEditorialStory] = [
        .init(videoAssetName: "sunlit-sidewalk.mp4", sceneCaption: "Morning light and nowhere to rush.  ·  #citywalk #daylight"),
        .init(videoAssetName: "evening-driving-range.mp4", sceneCaption: "One last swing before the sky turns blue.  ·  #drivingrange"),
        .init(videoAssetName: "railway-greenway.mp4", sceneCaption: "Old rails, new trees, quiet miles.  ·  #greenway #slowcity"),
        .init(videoAssetName: "boulevard-selfie.mp4", sceneCaption: "A quick hello from my favorite corner.  ·  #streetmood"),
        .init(videoAssetName: "brownstone-style.mp4", sceneCaption: "Clean lines against warm brick.  ·  #citystyle #brownstones"),
        .init(videoAssetName: "cliffside-dive.mp4", sceneCaption: "The calm breath before the jump.  ·  #cliffside #bluewater"),
        .init(videoAssetName: "trail-conversation.mp4", sceneCaption: "Trail talks are better without a clock.  ·  #goodcompany"),
        .init(videoAssetName: "canal-city-walk.mp4", sceneCaption: "Following the canal until the city softens.  ·  #waterside")
    ]
    static let reelVideos = reelStories.map(\.videoAssetName)
    static let liveVideos = [
        "above-clouds-broadcast.mp4", "city-dance-corner.mp4", "night-skyline-chat.mp4", "street-style-live.mp4", "friends-city-walk.mp4",
        "closeup-story-live.mp4", "courtyard-dance-live.mp4", "garden-day-live.mp4", "rooftop-food-live.mp4"
    ]
    // Voice spaces use their own editorial cover pool. Every asset below belongs
    // to a non-broadcasting profile, so the same hero image never appears as a
    // live-room card and a voice-room card at the same time.
    static let voiceRoomCoverAssets = [
        "riverside-wheel-view.jpg",
        "yellow-cab-corner.jpg",
        "waterfront-blue-sky.jpg",
        "metro-bandana.jpg",
        "sunhat-lakeside.jpg",
        "car-window-portrait.webp"
    ]
    static let videos = reelVideos + liveVideos

    static func reelCaption(for videoAssetName: String) -> String {
        reelStories.first(where: { $0.videoAssetName == videoAssetName })?.sceneCaption ?? "A scene worth remembering."
    }

    static func liveVideo(for member: CommunityProfile) -> String {
        let liveMembers = LookMeCommunityDirectory.members.filter(\.isLive)
        let index = liveMembers.firstIndex(where: { $0.id == member.id }) ?? 0
        return liveVideos[index % liveVideos.count]
    }

    static func liveEditorial(for member: CommunityProfile) -> LiveBroadcastEditorial {
        let directory = LookMeCommunityDirectory.members
        let memberIndex = directory.firstIndex(where: { $0.id == member.id }) ?? 0
        let liveMembers = directory.filter(\.isLive)
        let liveIndex = liveMembers.firstIndex(where: { $0.id == member.id }) ?? memberIndex
        let prompts = [
            "Cloudline check-in", "Street dance requests", "City lights after dark",
            "One-look styling session", "Walking the neighborhood together",
            "Close-up story hour", "Courtyard rhythm break", "A slow garden afternoon",
            "Rooftop bites and questions"
        ]
        let sceneMessages = [
            ["How high are you right now?", "The clouds behind you are unreal.", "That view deserves a postcard."],
            ["That footwork was so clean!", "Play that track one more time.", "The whole corner is your stage."],
            ["The skyline is glowing tonight.", "What is your favorite building there?", "This feels like a movie opening."],
            ["The bag completes the whole look.", "Where did you find that jacket?", "Minimal and sharp — love this."],
            ["Show us the next block too!", "This is such a calm city walk.", "I just added this route to my list."],
            ["That story made my evening.", "Your camera framing is beautiful.", "Stay for one more question!"],
            ["The light in this courtyard is perfect.", "Teach us that last move.", "This energy is contagious."],
            ["What is blooming behind you?", "This room feels so peaceful.", "A perfect slow afternoon."],
            ["What are you tasting first?", "That rooftop table looks amazing.", "Save me a bite!" ]
        ]
        let promptIndex = liveIndex % prompts.count
        let peers = (1...4).map { directory[(memberIndex + $0 * 3) % directory.count] }
        let gifts = [("🌹", "sent a Rose"), ("✨", "sent a Starlight"), ("👑", "sent a Crown"), ("🚀", "launched a Night Rocket")]
        var bulletins = sceneMessages[promptIndex].enumerated().map { offset, text in
            LiveRoomBulletin(authorProfileKey: peers[offset].id, authorDisplayName: peers[offset].name, activityText: text, giftSymbol: nil)
        }
        let gift = gifts[memberIndex % gifts.count]
        bulletins.insert(.init(authorProfileKey: peers[3].id, authorDisplayName: peers[3].name, activityText: gift.1, giftSymbol: gift.0), at: 1)
        return LiveBroadcastEditorial(
            viewerCount: 14 + ((memberIndex + 3) * 11) % 96,
            appreciationCount: 32 + ((memberIndex + 2) * 17) % 360,
            roomPrompt: prompts[promptIndex],
            bulletins: bulletins
        )
    }

    static func voiceEditorial(for room: InterestRoomBlueprint) -> [VoiceRoomBulletin] {
        let participants = room.participants.isEmpty ? [room.host] : room.participants
        let stableSeed = room.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let topicLines: [[String]] = [
            ["That opening track fits the room perfectly.", "What song should follow this one?", "This playlist is staying with me."],
            ["I needed a calm conversation like this.", "My good news is a tiny creative win.", "Coffee and kind people — ideal."],
            ["That travel detail is going straight into my notes.", "Describe the view without naming the city.", "Now I want to plan a slow weekend away."],
            ["I love hearing how everyone found this place.", "That answer was unexpectedly thoughtful.", "This is such an easy room to listen to."],
            ["The last story felt like a film scene.", "What would you call tonight's episode?", "Saving that recommendation for later."],
            ["That challenge sounds genuinely fun.", "Put me on the next team.", "The friendly rivalry has started." ]
        ]
        let lines = topicLines[stableSeed % topicLines.count]
        let gifts = [("🌙", "sent a Moon Glow to the stage"), ("🌹", "sent a Rose to the host"), ("✨", "shared a Starlight gift"), ("🎧", "sent a Headphone Halo")]
        var bulletins = lines.enumerated().map { offset, text -> VoiceRoomBulletin in
            let profile = participants[offset % participants.count]
            return .init(authorProfileKey: profile.id, authorDisplayName: profile.name, activityText: text, giftSymbol: nil)
        }
        let sender = participants[(stableSeed + 1) % participants.count]
        let gift = gifts[stableSeed % gifts.count]
        bulletins.insert(.init(authorProfileKey: sender.id, authorDisplayName: sender.name, activityText: gift.1, giftSymbol: gift.0), at: 1)
        return bulletins
    }
}
