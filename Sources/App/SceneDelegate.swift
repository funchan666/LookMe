import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        self.window = window
        AppRouter.shared.window = window
        CoinPurchaseManager.shared.startObserving()
        window.rootViewController = NightHubRouteResolvingViewController()
        window.makeKeyAndVisible()
        NightHubExperienceCoordinator.shared.start(in: window)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        NightHubPrivacyCoordinator.shared.sceneWillResignActive()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        NightHubPrivacyCoordinator.shared.sceneDidBecomeActive()
    }
}
