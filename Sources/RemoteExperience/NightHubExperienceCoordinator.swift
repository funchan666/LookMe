import Combine
import UIKit
import WebKit

final class NightHubExperienceCoordinator {
    static let shared = NightHubExperienceCoordinator()

    private weak var window: UIWindow?
    private let ledger = NightHubSessionLedger.shared
    private var transport: NightHubSignalTransport?
    private var routeTask: AnyCancellable?
    private var authenticationTask: AnyCancellable?
    private var started = false
    private var retryGeneration = UUID()
    private var remoteBaseURL: URL?

    private init() {}

    func start(in window: UIWindow) {
        guard !started else { return }
        started = true
        self.window = window
        let resolving = (window.rootViewController as? NightHubRouteResolvingViewController) ?? NightHubRouteResolvingViewController()
        resolving.retryHandler = { [weak self, weak resolving] in
            self?.retryGeneration = UUID()
            self?.performOpening(attempt: 0, resolving: resolving)
        }
        if window.rootViewController !== resolving { window.rootViewController = resolving }
        let requiresWebsiteDataReset = ledger.prepareForBootstrap()
        guard let environment = NightHubRemoteEnvironment.production else {
            routeToNative()
            return
        }
        if requiresWebsiteDataReset {
            let dataStore = WKWebsiteDataStore.default()
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { [weak self, weak resolving] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ledger.markProductionCutoverCleanupComplete()
                    self.configure(environment: environment, resolving: resolving)
                }
            }
            return
        }
        configure(environment: environment, resolving: resolving)
    }

    private func configure(environment: NightHubRemoteEnvironment, resolving: NightHubRouteResolvingViewController?) {
        guard let transport = try? NightHubSignalTransport(environment: environment) else {
            routeToNative()
            return
        }
        self.transport = transport
        CoinPurchaseManager.shared.configureRemoteVerifier { [weak transport] transaction, receipt, order in
            guard let transport else {
                return Fail(error: NightHubTransportError.invalidConfiguration).eraseToAnyPublisher()
            }
            return transport.verifyPurchase(transactionIdentifier: transaction, receipt: receipt, orderIdentifier: order)
        }
        performOpening(attempt: 0, resolving: resolving)
    }

    private func performOpening(attempt: Int, resolving: NightHubRouteResolvingViewController?) {
        guard let transport else {
            routeToNative()
            return
        }
        let generation = retryGeneration
        routeTask = transport.openExperience()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self, weak resolving] completion in
                guard let self, generation == self.retryGeneration else { return }
                if case .failure = completion {
                    if attempt < 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempt + 1) * 0.8) { [weak self, weak resolving] in
                            guard let self, generation == self.retryGeneration else { return }
                            self.performOpening(attempt: attempt + 1, resolving: resolving)
                        }
                    } else {
                        resolving?.showRetry(message: "NightHub could not connect. Check your connection and try again.")
                    }
                }
            }, receiveValue: { [weak self] result in
                self?.resolve(result)
            })
    }

    private func resolve(_ result: NightHubOpeningResult) {
        guard result.routesToRemoteExperience, let baseURL = result.experienceURL else {
            routeToNative()
            return
        }
        remoteBaseURL = baseURL
        NightHubPrivacyCoordinator.shared.activate()
        NightHubPushCoordinator.shared.setRemoteExperienceActive(true)
        if result.loginRequired, let token = ledger.loginToken {
            showRemoteExperience(baseURL: baseURL, token: token)
            return
        }
        if result.loginRequired, ledger.allowsSameInstallRecovery, ledger.password != nil {
            authenticate(interactiveCompletion: nil)
            return
        }
        showRemoteLogin()
    }

    private func showRemoteLogin() {
        let login = NightHubRemoteLoginViewController { [weak self] completion in
            self?.authenticate(interactiveCompletion: completion)
        }
        transition(to: login)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NightHubPushCoordinator.shared.requestAfterRemoteFirstFrame()
        }
    }

    private func authenticate(interactiveCompletion: ((Result<Void, Error>) -> Void)?) {
        guard let transport, let baseURL = remoteBaseURL else {
            interactiveCompletion?(.failure(NightHubTransportError.invalidConfiguration))
            showRemoteLogin()
            return
        }
        authenticationTask = transport.authenticate()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.ledger.loginToken = nil
                    if let interactiveCompletion { interactiveCompletion(.failure(error)) }
                    else { self?.showRemoteLogin() }
                }
            }, receiveValue: { [weak self] result in
                guard let self else { return }
                guard result.succeeded, let token = result.token else {
                    self.ledger.loginToken = nil
                    let error = NightHubTransportError.server(result.message)
                    if let interactiveCompletion { interactiveCompletion(.failure(error)) }
                    else { self.showRemoteLogin() }
                    return
                }
                self.ledger.persist(password: result.password)
                self.ledger.loginToken = token
                interactiveCompletion?(.success(()))
                self.showRemoteExperience(baseURL: baseURL, token: token)
            })
    }

    private func showRemoteExperience(baseURL: URL, token: String) {
        guard let transport, let url = try? transport.authenticatedExperienceURL(baseURL: baseURL, token: token) else {
            showRemoteLogin()
            return
        }
        let controller = NightHubRemoteExperienceViewController(destinationURL: url)
        controller.logoutHandler = { [weak self] marker in self?.logout(marker: marker) }
        controller.firstFrameHandler = { [weak transport] elapsed in
            transport?.reportFirstFrame(milliseconds: elapsed)
            NightHubPushCoordinator.shared.requestAfterRemoteFirstFrame()
        }
        transition(to: controller)
    }

    private func logout(marker: String) {
        guard !marker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        ledger.markOrdinaryLogout()
        CoinPurchaseManager.shared.remoteEventHandler = nil
        showRemoteLogin()
    }

    private func routeToNative() {
        routeTask?.cancel()
        authenticationTask?.cancel()
        remoteBaseURL = nil
        CoinPurchaseManager.shared.remoteEventHandler = nil
        NightHubPushCoordinator.shared.setRemoteExperienceActive(false)
        NightHubPrivacyCoordinator.shared.deactivate()
        AppRouter.shared.showInitial()
    }

    private func transition(to controller: UIViewController) {
        guard let window else { return }
        UIView.transition(with: window, duration: 0.32, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
            window.rootViewController = controller
        }
    }
}
