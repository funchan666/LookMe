import Foundation

extension Notification.Name { static let lookMeStoreChanged = Notification.Name("lookMeStoreChanged") }

final class LookMeExperienceStore {
    static let shared = LookMeExperienceStore()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var scheduledInboundFollowers = Set<String>()

    private struct ReelConversationDraft {
        let videoAsset: String
        let authorIndex: Int
        let text: String
    }

    private static let reelConversationDrafts: [ReelConversationDraft] = [
        .init(videoAsset: "sunlit-sidewalk.mp4", authorIndex: 8, text: "The morning light makes this whole street feel cinematic."),
        .init(videoAsset: "sunlit-sidewalk.mp4", authorIndex: 9, text: "That quiet pause by the corner is such a good detail."),
        .init(videoAsset: "evening-driving-range.mp4", authorIndex: 11, text: "That swing looked effortless. The sunset timing helped too."),
        .init(videoAsset: "evening-driving-range.mp4", authorIndex: 12, text: "I started learning last month and this makes me want another lesson."),
        .init(videoAsset: "evening-driving-range.mp4", authorIndex: 13, text: "The sound of the ball at the end is so satisfying."),
        .init(videoAsset: "evening-driving-range.mp4", authorIndex: 32, text: "Did you stay for another bucket after this? That sky was worth it."),
        .init(videoAsset: "railway-greenway.mp4", authorIndex: 14, text: "Green paths beside old rail lines are my favorite city surprise."),
        .init(videoAsset: "railway-greenway.mp4", authorIndex: 15, text: "Saving this route for a slow Sunday walk."),
        .init(videoAsset: "railway-greenway.mp4", authorIndex: 16, text: "The mix of shade and open sky looks perfect for cycling."),
        .init(videoAsset: "railway-greenway.mp4", authorIndex: 33, text: "I can almost hear the wheels on that quiet stretch."),
        .init(videoAsset: "railway-greenway.mp4", authorIndex: 34, text: "Please share the starting point—this belongs on my next route."),
        .init(videoAsset: "boulevard-selfie.mp4", authorIndex: 17, text: "Your energy matches the whole boulevard today."),
        .init(videoAsset: "brownstone-style.mp4", authorIndex: 20, text: "The clean outfit against the brick is such a strong combination."),
        .init(videoAsset: "brownstone-style.mp4", authorIndex: 21, text: "I love how the accessories stay simple but still feel intentional."),
        .init(videoAsset: "brownstone-style.mp4", authorIndex: 22, text: "That block has so much character. Great place for this look."),
        .init(videoAsset: "brownstone-style.mp4", authorIndex: 35, text: "The neutral palette makes every little texture stand out."),
        .init(videoAsset: "brownstone-style.mp4", authorIndex: 36, text: "Where is that bag from? It fits the walk perfectly."),
        .init(videoAsset: "brownstone-style.mp4", authorIndex: 37, text: "This convinced me to keep tomorrow's outfit much simpler."),
        .init(videoAsset: "cliffside-dive.mp4", authorIndex: 23, text: "The water color is unreal. I would need a long countdown first."),
        .init(videoAsset: "cliffside-dive.mp4", authorIndex: 24, text: "That was brave and beautifully framed."),
        .init(videoAsset: "cliffside-dive.mp4", authorIndex: 25, text: "The calm moment before the jump makes the clip."),
        .init(videoAsset: "trail-conversation.mp4", authorIndex: 26, text: "Trail conversations always end up being the most honest ones."),
        .init(videoAsset: "trail-conversation.mp4", authorIndex: 27, text: "The view opening behind you halfway through is gorgeous."),
        .init(videoAsset: "trail-conversation.mp4", authorIndex: 28, text: "This is exactly my kind of unhurried afternoon."),
        .init(videoAsset: "trail-conversation.mp4", authorIndex: 38, text: "Good company and a trail with no signal sounds ideal."),
        .init(videoAsset: "canal-city-walk.mp4", authorIndex: 29, text: "The reflections make the canal look like a moving painting."),
        .init(videoAsset: "canal-city-walk.mp4", authorIndex: 30, text: "I like that you kept the street sounds in this one.")
    ]

    static var reelConversationCoverage: [String: Set<String>] {
        Dictionary(grouping: reelConversationDrafts, by: \.videoAsset).mapValues { Set($0.map(\.text)) }
    }

    var nickname: String { didSet { saveProfile() } }
    var gender: String { didSet { saveProfile() } }
    var birthday: String { didSet { saveProfile() } }
    var country: String { didSet { saveProfile() } }
    var coins: Int { didSet { defaults.set(coins, forKey: "coins"); changed() } }
    var messageDND: Bool { didSet { defaults.set(messageDND, forKey: "messageDND") } }
    var callDND: Bool { didSet { defaults.set(callDND, forKey: "callDND") } }
    private(set) var following: Set<String>
    private(set) var incomingFollowers: Set<String>
    private(set) var blockedUsers: Set<String>
    private(set) var messages: [DirectConversationEntry]
    private(set) var voiceRoomMessages: [RoomConversationEntry]
    private(set) var moments: [CommunityMomentRecord]
    private(set) var pendingMoments: [CommunityMomentRecord]
    private(set) var comments: [CommunityReplyRecord]
    private(set) var reports: [SafetyReportRecord]
    private(set) var systemNotices: [ActivityNoticeRecord]
    private(set) var backpack: [CollectedEffectRecord]
    private(set) var createdInterestRooms: [InterestRoomBlueprint]

    private init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-reset-daily-coin") {
            defaults.removeObject(forKey: "lastDailyCoinClaim")
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-reset-reel-conversations") {
            defaults.removeObject(forKey: "installedReelConversationsV2")
            defaults.removeObject(forKey: "installedReelConversationsV3")
            defaults.removeObject(forKey: "comments")
            defaults.removeObject(forKey: "reports")
            defaults.removeObject(forKey: "blockedUsers")
        }
#endif
        nickname = defaults.string(forKey: "nickname") ?? "Nani Kohli"
        gender = defaults.string(forKey: "gender") ?? "Female"
        birthday = defaults.string(forKey: "birthday") ?? "2000-04-23"
        country = defaults.string(forKey: "country") ?? "SG"
        coins = Self.storedInteger(in: defaults, keys: ["coins", "diamonds"]) ?? 0
        messageDND = defaults.bool(forKey: "messageDND")
        callDND = defaults.bool(forKey: "callDND")
        following = Set(defaults.stringArray(forKey: "following") ?? [])
        incomingFollowers = Set(defaults.stringArray(forKey: "incomingFollowers") ?? [])
        blockedUsers = Set(defaults.stringArray(forKey: "blockedUsers") ?? [])
        messages = Self.decode([DirectConversationEntry].self, from: defaults.data(forKey: "messages")) ?? []
        voiceRoomMessages = Self.decode([RoomConversationEntry].self, from: defaults.data(forKey: "voiceRoomMessages")) ?? []
        if !defaults.bool(forKey: "removedLegacySeedMessage") { messages.removeAll { !$0.isMine && $0.memberID == "member-0" }; defaults.set(true, forKey: "removedLegacySeedMessage") }
        moments = Self.decode([CommunityMomentRecord].self, from: defaults.data(forKey: "moments")) ?? [
            .init(momentKey: UUID(), authorDisplayName: "Mia Calder", authorProfileKey: "member-0", momentText: "Slow mornings and a new favorite corner of the city.", bundledImageAsset: "boulevard-snack-stop.jpg", likedByCurrentUser: false, appreciationCount: 48, submittedAt: Date().addingTimeInterval(-7200)),
            .init(momentKey: UUID(), authorDisplayName: "Amara Ndlovu", authorProfileKey: "member-8", momentText: "What song has been on repeat for you lately?", bundledImageAsset: "evening-cat-cafe.jpg", likedByCurrentUser: true, appreciationCount: 86, submittedAt: Date().addingTimeInterval(-19000))
        ]
        pendingMoments = Self.decode([CommunityMomentRecord].self, from: defaults.data(forKey: "pendingMoments")) ?? []
        comments = Self.decode([CommunityReplyRecord].self, from: defaults.data(forKey: "comments")) ?? []
        reports = Self.decode([SafetyReportRecord].self, from: defaults.data(forKey: "reports")) ?? []
        systemNotices = Self.decode([ActivityNoticeRecord].self, from: defaults.data(forKey: "systemNotices")) ?? []
        backpack = Self.decode([CollectedEffectRecord].self, from: defaults.data(forKey: "backpack")) ?? []
        createdInterestRooms = Self.decode([InterestRoomBlueprint].self, from: defaults.data(forKey: "createdInterestRooms")) ?? []
        installReelConversationsIfNeeded()
        save(messages, key: "messages")
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func storedInteger(in defaults: UserDefaults, keys: [String]) -> Int? {
        for key in keys {
            if let number = defaults.object(forKey: key) as? NSNumber { return number.intValue }
            if let value = defaults.string(forKey: key), let number = Int(value) { return number }
        }
        return nil
    }

    func toggleFollow(_ id: String) {
        if following.contains(id) { following.remove(id) } else { following.insert(id) }
        defaults.set(Array(following), forKey: "following"); changed()
    }

    func isMutual(with id: String) -> Bool { following.contains(id) && incomingFollowers.contains(id) && !blockedUsers.contains(id) }

    var visibleMoments: [CommunityMomentRecord] {
        moments.filter { moment in
            let contentID = "moment:\(moment.id.uuidString)"
            return !isReported(contentID) && !(moment.authorID.map(blockedUsers.contains) ?? false)
        }
    }

    func visibleMembers(_ members: [CommunityProfile] = LookMeCommunityDirectory.members) -> [CommunityProfile] { members.filter { !blockedUsers.contains($0.id) } }

    func isReported(_ targetID: String) -> Bool { reports.contains { $0.targetID == targetID } }

    func blockUser(_ id: String) {
        blockedUsers.insert(id)
        following.remove(id); incomingFollowers.remove(id)
        defaults.set(Array(blockedUsers), forKey: "blockedUsers")
        defaults.set(Array(following), forKey: "following"); defaults.set(Array(incomingFollowers), forKey: "incomingFollowers")
        changed()
    }

    func unblockUser(_ id: String) {
        blockedUsers.remove(id)
        defaults.set(Array(blockedUsers), forKey: "blockedUsers")
        changed()
    }

    func report(targetID: String, type: String, userID: String?, reason: String) {
        guard !isReported(targetID) else { return }
        reports.append(.init(reportKey: UUID(), reportedContentKey: targetID, reportedContentKind: type, reportedProfileKey: userID, categoryReason: reason, recordedAt: Date()))
        save(reports, key: "reports")
        changed()
    }

    func send(_ text: String, to memberID: String) {
        messages.append(.init(conversationEntryKey: UUID(), counterpartProfileKey: memberID, messageBody: text, authoredByCurrentUser: true, deliveredAt: Date()))
        save(messages, key: "messages"); changed()
    }

    func voiceMessages(for roomID: String) -> [RoomConversationEntry] {
        voiceRoomMessages.filter {
            $0.roomID == roomID && !isReported("voice-message:\($0.id.uuidString)") && !blockedUsers.contains($0.authorID)
        }
    }

    func sendVoiceRoomMessage(_ text: String, roomID: String) {
        voiceRoomMessages.append(.init(roomEntryKey: UUID(), roomKey: roomID, authorProfileKey: "me", authorDisplayName: nickname, messageBody: text, deliveredAt: Date()))
        save(voiceRoomMessages, key: "voiceRoomMessages")
        changed()
    }

    func comments(for contentID: String) -> [CommunityReplyRecord] {
        comments.filter { $0.contentID == contentID && !isReported("comment:\($0.id.uuidString)") && !blockedUsers.contains($0.authorID) }
    }

    func addComment(_ text: String, to contentID: String) {
        comments.append(.init(replyKey: UUID(), parentContentKey: contentID, authorProfileKey: "me", authorDisplayName: nickname, replyText: text, submittedAt: Date()))
        save(comments, key: "comments")
        changed()
    }

    private func installReelConversationsIfNeeded() {
        let installationKey = "installedReelConversationsV3"
        guard !defaults.bool(forKey: installationKey) else { return }
        // V2 used exactly three bundled replies for every reel. Replace only
        // those editorial replies while preserving anything written by Me.
        let reelContentIDs = Set(CommunityMediaRegistry.reelVideos.map { "reel:\($0)" })
        comments.removeAll { reelContentIDs.contains($0.contentID) && $0.authorID != "me" }
        let now = Date()
        for (offset, draft) in Self.reelConversationDrafts.enumerated() {
            guard LookMeCommunityDirectory.members.indices.contains(draft.authorIndex) else { continue }
            let author = LookMeCommunityDirectory.members[draft.authorIndex]
            let contentID = "reel:\(draft.videoAsset)"
            let isAlreadyPresent = comments.contains { $0.contentID == contentID && $0.authorID == author.id && $0.text == draft.text }
            guard !isAlreadyPresent else { continue }
            comments.append(.init(replyKey: UUID(), parentContentKey: contentID, authorProfileKey: author.id, authorDisplayName: author.name, replyText: draft.text, submittedAt: now.addingTimeInterval(-Double(900 + offset * 437))))
        }
        defaults.set(true, forKey: installationKey)
        save(comments, key: "comments")
    }

    func addMoment(text: String) {
        submitMoment(text: text, mediaPath: nil, mediaType: nil)
    }

    func submitMoment(text: String, mediaPath: String?, mediaType: String?) {
        pendingMoments.insert(.init(momentKey: UUID(), authorDisplayName: nickname, authorProfileKey: "me", momentText: text, bundledImageAsset: nil, capturedMediaPath: mediaPath, mediaKind: mediaType, likedByCurrentUser: false, appreciationCount: 0, submittedAt: Date()), at: 0)
        save(pendingMoments, key: "pendingMoments")
        changed()
    }

    func toggleLike(_ id: UUID) {
        guard let index = moments.firstIndex(where: { $0.id == id }) else { return }
        moments[index].liked.toggle()
        moments[index].likes += moments[index].liked ? 1 : -1
        save(moments, key: "moments"); changed()
    }

    @discardableResult func spendCoins(_ amount: Int, reason: String) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        coins -= amount
        defaults.set(reason, forKey: "lastCoinSpendReason")
        defaults.set(Date(), forKey: "lastCoinSpendDate")
        return true
    }

    func addCoins(_ amount: Int, source: String) {
        guard amount > 0 else { return }
        coins += amount
        defaults.set(source, forKey: "lastCoinCreditSource")
        defaults.set(Date(), forKey: "lastCoinCreditDate")
    }

    @discardableResult func buy(id: String, name: String, symbol: String, price: Int) -> Bool {
        guard spendCoins(price, reason: name) else { return false }
        if let index = backpack.firstIndex(where: { $0.id == id }) { backpack[index].quantity += 1 }
        else { backpack.append(.init(effectKey: id, effectName: name, symbolGlyph: symbol, ownedQuantity: 1)) }
        save(backpack, key: "backpack"); changed(); return true
    }

    @discardableResult func createInterestRoom(title: String, summary: String, topic: String) -> InterestRoomBlueprint {
        let normalizedKey = title.lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let room = InterestRoomBlueprint(
            roomKey: "created-\(normalizedKey)-\(UUID().uuidString.prefix(6).lowercased())",
            roomTitle: title,
            roomSummary: summary,
            coverAssetName: "presence-constellation-field.png",
            participantPortraitAssets: [CommunityMediaRegistry.images[0]],
            liveAudienceCount: 1,
            topicLabel: topic,
            hostProfileKey: nil,
            isCommunityCreated: true
        )
        createdInterestRooms.insert(room, at: 0)
        save(createdInterestRooms, key: "createdInterestRooms")
        changed()
        return room
    }

    var canClaimDailyCoinDrop: Bool { defaults.string(forKey: "lastDailyCoinClaim") != dailyCoinClaimKey() }

    @discardableResult func claimDailyTask() -> Bool {
        guard canClaimDailyCoinDrop else { return false }
        defaults.set(dailyCoinClaimKey(), forKey: "lastDailyCoinClaim")
        addCoins(50, source: "Daily coin drop")
        return true
    }

    private func dailyCoinClaimKey(for date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    @discardableResult func grantWelcomeCoinsIfNeeded() -> Int? {
        guard !defaults.bool(forKey: "welcomeCoinsGranted") else { return nil }
        let amount = 888
        defaults.set(true, forKey: "welcomeCoinsGranted")
        addCoins(amount, source: "First login gift")
        systemNotices.insert(.init(noticeKey: UUID(), eventKind: "reward", relatedProfileKey: nil, headline: "Welcome coin drop", detailText: "888 coins were added to your balance.", recordedAt: Date(), hasBeenRead: false), at: 0)
        save(systemNotices, key: "systemNotices")
        changed()
        return amount
    }

    func markNoticeRead(_ id: UUID) {
        guard let index = systemNotices.firstIndex(where: { $0.id == id }) else { return }
        systemNotices[index].isRead = true
        save(systemNotices, key: "systemNotices"); changed()
    }

    func markAllNoticesRead() {
        guard systemNotices.contains(where: { !$0.isRead }) else { return }
        for index in systemNotices.indices { systemNotices[index].isRead = true }
        save(systemNotices, key: "systemNotices"); changed()
    }

    func scheduleInboundFollowersIfNeeded() {
        var plan = defaults.stringArray(forKey: "inboundFollowerPlan") ?? []
        if plan.isEmpty {
            let candidates = LookMeCommunityDirectory.members.filter { !blockedUsers.contains($0.id) }
            plan = candidates.shuffled().prefix(min(Int.random(in: 1...3), candidates.count)).map(\.id)
            defaults.set(plan, forKey: "inboundFollowerPlan")
        }
        let pending = plan.filter { !incomingFollowers.contains($0) && !scheduledInboundFollowers.contains($0) }
        for (offset, id) in pending.enumerated() {
            guard let member = LookMeCommunityDirectory.members.first(where: { $0.id == id }) else { continue }
            scheduledInboundFollowers.insert(id)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(4 + offset * 7)) { [weak self] in
                guard let self else { return }
                self.scheduledInboundFollowers.remove(member.id)
                guard self.defaults.bool(forKey: "didQuickLogin"), !self.blockedUsers.contains(member.id), !self.incomingFollowers.contains(member.id) else { return }
                self.incomingFollowers.insert(member.id)
                self.defaults.set(Array(self.incomingFollowers), forKey: "incomingFollowers")
                self.systemNotices.insert(.init(noticeKey: UUID(), eventKind: "follow", relatedProfileKey: member.profileKey, headline: "New follower", detailText: "\(member.displayName) followed you", recordedAt: Date(), hasBeenRead: false), at: 0)
                self.save(self.systemNotices, key: "systemNotices")
                self.changed()
            }
        }
    }

    func deleteAccountData() {
        let domain = Bundle.main.bundleIdentifier ?? "com.nighthub.momentspace"
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        coins = 0; following.removeAll(); incomingFollowers.removeAll(); blockedUsers.removeAll(); messages.removeAll(); voiceRoomMessages.removeAll(); pendingMoments.removeAll(); comments.removeAll(); reports.removeAll(); systemNotices.removeAll(); backpack.removeAll(); createdInterestRooms.removeAll(); scheduledInboundFollowers.removeAll(); installReelConversationsIfNeeded()
    }

    private func saveProfile() {
        defaults.set(nickname, forKey: "nickname"); defaults.set(gender, forKey: "gender")
        defaults.set(birthday, forKey: "birthday"); defaults.set(country, forKey: "country"); changed()
    }
    private func save<T: Encodable>(_ value: T, key: String) { defaults.set(try? encoder.encode(value), forKey: key) }
    private func changed() { NotificationCenter.default.post(name: .lookMeStoreChanged, object: nil) }
}
