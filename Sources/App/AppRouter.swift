import UIKit
import AuthenticationServices

final class AppRouter {
    static let shared = AppRouter()
    weak var window: UIWindow?

    func showInitial() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "didQuickLogin"), defaults.bool(forKey: "acceptedLegalAgreements") else {
            showLogin(animated: true)
            return
        }
        guard defaults.string(forKey: "loginMethod") == "apple",
              let userID = defaults.string(forKey: "appleUserIdentifier") else {
            showMain(animated: true)
            return
        }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { [weak self] state, _ in
            DispatchQueue.main.async {
                if state == .authorized { self?.showMain(animated: true) }
                else {
                    defaults.set(false, forKey: "didQuickLogin")
                    self?.showLogin(animated: true)
                }
            }
        }
    }

    private func showLogin(animated: Bool) {
        let login = LoginViewController()
        guard animated, let window else { self.window?.rootViewController = login; return }
        UIView.transition(with: window, duration: 0.42, options: .transitionCrossDissolve) { window.rootViewController = login }
    }

    func showMain(animated: Bool = true, welcomeCoins: Int? = nil) {
        let main = LookMeNavigationShell(welcomeCoins: welcomeCoins)
        LookMeExperienceStore.shared.scheduleInboundFollowersIfNeeded()
        guard animated, let window else { self.window?.rootViewController = main; return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) { window.rootViewController = main }
    }

    func refreshInterfaceLanguage() {
        let isSignedIn = UserDefaults.standard.bool(forKey: "didQuickLogin") && UserDefaults.standard.bool(forKey: "acceptedLegalAgreements")
        if isSignedIn { showMain(animated: true) }
        else { showLogin(animated: true) }
    }

    func signOut() {
        UserDefaults.standard.set(false, forKey: "didQuickLogin")
        guard let window else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) { window.rootViewController = LoginViewController() }
    }

    func deleteAccount() {
        LookMeExperienceStore.shared.deleteAccountData()
        guard let window else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) { window.rootViewController = LoginViewController() }
    }
}
