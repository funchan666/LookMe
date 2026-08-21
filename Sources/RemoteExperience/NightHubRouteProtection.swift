import UIKit
import UserNotifications

final class NightHubPushCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NightHubPushCoordinator()

    private var permissionRequestedThisProcess = false
    private(set) var remoteExperienceIsActive = false

    private override init() { super.init() }

    func setRemoteExperienceActive(_ active: Bool) {
        remoteExperienceIsActive = active
    }

    func requestAfterRemoteFirstFrame() {
        guard remoteExperienceIsActive, !permissionRequestedThisProcess else { return }
        permissionRequestedThisProcess = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    func receive(deviceToken: Data) {
        NightHubSessionLedger.shared.persist(pushToken: deviceToken.map { String(format: "%02x", $0) }.joined())
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(remoteExperienceIsActive ? [.banner, .badge, .sound] : [])
    }
}

final class NightHubPrivacyCoordinator {
    static let shared = NightHubPrivacyCoordinator()

    private let coverTag = 942_671
    private var isEnabled = false
    private var isSceneInactive = false

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(captureStateChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
    }

    func activate() {
        isEnabled = true
        refresh()
    }

    func deactivate() {
        isEnabled = false
        refresh()
    }

    func sceneWillResignActive() {
        isSceneInactive = true
        refresh()
    }

    func sceneDidBecomeActive() {
        isSceneInactive = false
        refresh()
    }

    @objc private func captureStateChanged() {
        refresh()
    }

    private func refresh() {
        DispatchQueue.main.async {
            let shouldCover = self.isEnabled && (self.isSceneInactive || UIScreen.main.isCaptured)
            for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
                if shouldCover { self.installCover(in: window) }
                else { window.viewWithTag(self.coverTag)?.removeFromSuperview() }
            }
        }
    }

    private func installCover(in window: UIWindow) {
        guard window.viewWithTag(coverTag) == nil else { return }
        let cover = UIView(frame: window.bounds)
        cover.tag = coverTag
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cover.backgroundColor = UIColor(red: 0.035, green: 0.012, blue: 0.105, alpha: 1)
        let mark = UIImageView(image: UIImage(named: "AppIconPreview") ?? UIImage(named: "NightHubStreetGlowLogin"))
        mark.contentMode = .scaleAspectFill
        mark.clipsToBounds = true
        mark.layer.cornerRadius = 24
        mark.translatesAutoresizingMaskIntoConstraints = false
        cover.addSubview(mark)
        NSLayoutConstraint.activate([
            mark.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            mark.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
            mark.widthAnchor.constraint(equalToConstant: 82),
            mark.heightAnchor.constraint(equalToConstant: 82)
        ])
        window.addSubview(cover)
    }
}
