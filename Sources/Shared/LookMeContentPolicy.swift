import Foundation

enum LookMeContentPolicy {
    enum RejectionReason: Equatable {
        case emptyOrOversized
        case sexualSolicitation
        case threatOrSelfHarm
        case targetedAbuse
        case scamOrContactSpam
        case repeatedNoise

        var userMessage: String {
            switch self {
            case .emptyOrOversized: return "Keep this message concise and add some meaningful text."
            case .sexualSolicitation: return "Please remove sexual requests or exploitative language."
            case .threatOrSelfHarm: return "Threats and encouragement of harm aren't allowed on LookMe."
            case .targetedAbuse: return "Please rewrite this without hateful, degrading or targeted abuse."
            case .scamOrContactSpam: return "Please remove suspicious links, payment requests or repeated contact details."
            case .repeatedNoise: return "Please replace repeated characters with a clear message."
            }
        }
    }

    struct Decision: Equatable {
        let isAllowed: Bool
        let rejectionReason: RejectionReason?

        static let allow = Decision(isAllowed: true, rejectionReason: nil)
        static func reject(_ reason: RejectionReason) -> Decision { Decision(isAllowed: false, rejectionReason: reason) }
    }

    private static let sexualSolicitationFragments = [
        "send nude", "send pic naked", "explicit photo", "sexual service", "pay for sex", "escort service", "meet for sex"
    ]
    private static let harmFragments = [
        "kill yourself", "go die", "i will kill", "hurt yourself", "you should die", "i will hurt"
    ]
    private static let abuseFragments = [
        "hate speech", "subhuman", "worthless freak", "racial slur", "terrorize you"
    ]
    private static let scamFragments = [
        "wire me money", "send crypto", "gift card code", "guaranteed profit", "investment return", "account verification fee"
    ]

    static func evaluate(_ text: String, allowsEmpty: Bool = false) -> Decision {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if (!allowsEmpty && trimmed.isEmpty) || trimmed.count > 2_000 { return .reject(.emptyOrOversized) }

        let normalized = normalizedForScreening(trimmed)
        if sexualSolicitationFragments.contains(where: normalized.contains) { return .reject(.sexualSolicitation) }
        if harmFragments.contains(where: normalized.contains) { return .reject(.threatOrSelfHarm) }
        if abuseFragments.contains(where: normalized.contains) { return .reject(.targetedAbuse) }
        if scamFragments.contains(where: normalized.contains) { return .reject(.scamOrContactSpam) }

        let linkCount = matches(#"(?:https?://|www\.)"#, in: normalized)
        let emailCount = matches(#"[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}"#, in: normalized)
        let phoneCount = matches(#"(?:\+?\d[\d\s().-]{7,}\d)"#, in: normalized)
        if linkCount > 1 || emailCount > 1 || phoneCount > 1 { return .reject(.scamOrContactSpam) }
        if normalized.range(of: #"(.)\1{11,}"#, options: .regularExpression) != nil { return .reject(.repeatedNoise) }
        return .allow
    }

    static func allows(_ text: String) -> Bool { evaluate(text).isAllowed }

    private static func normalizedForScreening(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
        let substitutions: [Character: Character] = ["0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t"]
        let substituted = String(folded.map { substitutions[$0] ?? $0 })
        return substituted
            .replacingOccurrences(of: #"[^a-z0-9@+.:/\s-]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private static func matches(_ pattern: String, in text: String) -> Int {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return 0 }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.numberOfMatches(in: text, range: range)
    }
}
