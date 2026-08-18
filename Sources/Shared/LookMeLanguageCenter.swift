import Foundation

enum LookMeInterfaceLanguage: String, CaseIterable, Codable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case spanish = "es"
    case japanese = "ja"
    case german = "de"

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .spanish: return "Español"
        case .japanese: return "日本語"
        case .german: return "Deutsch"
        }
    }

    var marketNote: String {
        switch self {
        case .english: return "Global"
        case .simplifiedChinese: return "简体"
        case .spanish: return "Latinoamérica · España"
        case .japanese: return "日本"
        case .german: return "Deutschland · DACH"
        }
    }

    var monogram: String {
        switch self {
        case .english: return "EN"
        case .simplifiedChinese: return "简"
        case .spanish: return "ES"
        case .japanese: return "あ"
        case .german: return "DE"
        }
    }
}

final class LookMeLanguageCenter {
    static let shared = LookMeLanguageCenter()
    static let preferenceKey = "lookMe.interfaceLanguage"

    private let defaults: UserDefaults
    private var localizedBundle: Bundle?

    private(set) var selectedLanguage: LookMeInterfaceLanguage {
        didSet { localizedBundle = Self.bundle(for: selectedLanguage) }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let savedCode = defaults.string(forKey: Self.preferenceKey),
           let savedLanguage = LookMeInterfaceLanguage(rawValue: savedCode) {
            selectedLanguage = savedLanguage
        } else {
            selectedLanguage = .english
        }
        localizedBundle = Self.bundle(for: selectedLanguage)
    }

    func select(_ language: LookMeInterfaceLanguage) {
        guard language != selectedLanguage else { return }
        selectedLanguage = language
        defaults.set(language.rawValue, forKey: Self.preferenceKey)
        NotificationCenter.default.post(name: .lookMeLanguageChanged, object: language)
    }

    func text(_ englishSource: String) -> String {
        guard selectedLanguage != .english, let localizedBundle else { return englishSource }
        return localizedBundle.localizedString(forKey: englishSource, value: englishSource, table: nil)
    }

    func relativeTime(from date: Date, relativeTo referenceDate: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: selectedLanguage.rawValue)
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

    private static func bundle(for language: LookMeInterfaceLanguage) -> Bundle? {
        let productBundle = Bundle(for: LookMeLanguageCenter.self)
        guard let path = productBundle.path(forResource: language.rawValue, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }
}

extension String {
    var lmLocalized: String { LookMeLanguageCenter.shared.text(self) }
}

extension Notification.Name {
    static let lookMeLanguageChanged = Notification.Name("lookMe.language.changed")
}
