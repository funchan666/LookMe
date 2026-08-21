import UIKit
import WebKit

enum NightHubBridgeContract {
    static let rechargeHandler = "CoinVaultRecharge"
    static let logoutHandler = "NightSessionLogout"
    static let browserHandler = "NightLinkOpen"
    static let rechargeStateEvent = "nativeRechargeState"
    static let openStateEvent = "nativeOpenState"

    static func stringArray(from body: Any, count: Int) -> [String]? {
        let raw: Any
        if let array = body as? [Any] { raw = array }
        else if let string = body as? String, let data = string.data(using: .utf8),
                let decoded = try? JSONSerialization.jsonObject(with: data, options: []), decoded is [Any] { raw = decoded }
        else { return nil }
        guard let array = raw as? [Any], array.count == count, array.allSatisfy({ $0 is String }) else { return nil }
        return array.compactMap { $0 as? String }
    }

    static func validatedSystemURL(from values: [String]) -> URL? {
        guard values.count == 2, values[0] == "system", let url = URL(string: values[1]),
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host != nil else { return nil }
        return url
    }
}

final class NightHubRouteResolvingViewController: UIViewController {
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    var retryHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.035, green: 0.012, blue: 0.105, alpha: 1)
        indicator.color = UIColor(red: 1, green: 0.18, blue: 0.62, alpha: 1)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        messageLabel.text = "Preparing NightHub"
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        retryButton.tintColor = .white
        retryButton.backgroundColor = UIColor(red: 0.94, green: 0.10, blue: 0.58, alpha: 1)
        retryButton.layer.cornerRadius = 22
        retryButton.isHidden = true
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        view.addSubview(indicator)
        view.addSubview(messageLabel)
        view.addSubview(retryButton)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 18),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 22),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 150),
            retryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func showRetry(message: String) {
        indicator.stopAnimating()
        messageLabel.text = message
        retryButton.isHidden = false
    }

    func showLoading() {
        retryButton.isHidden = true
        messageLabel.text = "Preparing NightHub"
        indicator.startAnimating()
    }

    @objc private func retryTapped() {
        showLoading()
        retryHandler?()
    }
}

final class NightHubRemoteLoginViewController: UIViewController {
    private let action: (@escaping (Result<Void, Error>) -> Void) -> Void
    private let button = UIButton(type: .system)
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()

    init(action: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        self.action = action
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(image: UIImage(named: "NightHubStreetGlowLogin"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        button.setTitle("Quick Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(red: 0.96, green: 0.10, blue: 0.59, alpha: 1)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.28
        button.layer.shadowRadius = 14
        button.layer.shadowOffset = CGSize(width: 0, height: 7)
        button.accessibilityIdentifier = "remote.quickLogin"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        view.addSubview(button)
        view.addSubview(indicator)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 28),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -28),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            button.heightAnchor.constraint(equalToConstant: 56),
            indicator.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            messageLabel.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -12)
        ])
    }

    @objc private func loginTapped() {
        guard button.isEnabled else { return }
        button.isEnabled = false
        button.setTitle("", for: .normal)
        messageLabel.text = nil
        indicator.startAnimating()
        action { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.button.isEnabled = true
                self.button.setTitle("Quick Login", for: .normal)
                self.indicator.stopAnimating()
                if case .failure(let error) = result { self.messageLabel.text = error.localizedDescription }
            }
        }
    }
}

private final class NightHubWeakScriptRelay: NSObject, WKScriptMessageHandler {
    weak var receiver: WKScriptMessageHandler?

    init(receiver: WKScriptMessageHandler) { self.receiver = receiver }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        receiver?.userContentController(userContentController, didReceive: message)
    }
}

final class NightHubRemoteExperienceViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    static let rechargeHandler = NightHubBridgeContract.rechargeHandler
    static let logoutHandler = NightHubBridgeContract.logoutHandler
    static let browserHandler = NightHubBridgeContract.browserHandler

    var logoutHandler: ((String) -> Void)?
    var firstFrameHandler: ((Int64) -> Void)?

    private let destinationURL: URL
    private let webView: WKWebView
    private let loadingCover = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let purchaseShield = UIView()
    private let purchaseIndicator = UIActivityIndicatorView(style: .large)
    private let retryButton = UIButton(type: .system)
    private let startedAt = Date()
    private var firstFramePresented = false
    private var firstNavigationRetryCount = 0
    private var relays: [NightHubWeakScriptRelay] = []

    init(destinationURL: URL) {
        self.destinationURL = destinationURL
        let controller = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        [Self.rechargeHandler, Self.logoutHandler, Self.browserHandler].forEach { name in
            let relay = NightHubWeakScriptRelay(receiver: self)
            relays.append(relay)
            controller.add(relay, name: name)
        }
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        [Self.rechargeHandler, Self.logoutHandler, Self.browserHandler].forEach(webView.configuration.userContentController.removeScriptMessageHandler(forName:))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.035, green: 0.012, blue: 0.105, alpha: 1)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        installLoadingCover()
        installPurchaseShield()
        CoinPurchaseManager.shared.remoteEventHandler = { [weak self] event in self?.handlePurchase(event) }
        loadDestination()
    }

    private func installLoadingCover() {
        loadingCover.translatesAutoresizingMaskIntoConstraints = false
        let background = UIImageView(image: UIImage(named: "NightHubStreetGlowLogin"))
        background.contentMode = .scaleAspectFill
        background.clipsToBounds = true
        background.translatesAutoresizingMaskIntoConstraints = false
        loadingCover.addSubview(background)
        let shade = UIView()
        shade.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        shade.translatesAutoresizingMaskIntoConstraints = false
        loadingCover.addSubview(shade)
        loadingIndicator.color = UIColor(red: 1, green: 0.20, blue: 0.65, alpha: 1)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingCover.addSubview(loadingIndicator)
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        retryButton.backgroundColor = UIColor(red: 0.94, green: 0.10, blue: 0.58, alpha: 1)
        retryButton.layer.cornerRadius = 23
        retryButton.isHidden = true
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        loadingCover.addSubview(retryButton)
        view.addSubview(loadingCover)
        NSLayoutConstraint.activate([
            loadingCover.topAnchor.constraint(equalTo: view.topAnchor),
            loadingCover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingCover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingCover.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.topAnchor.constraint(equalTo: loadingCover.topAnchor),
            background.leadingAnchor.constraint(equalTo: loadingCover.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: loadingCover.trailingAnchor),
            background.bottomAnchor.constraint(equalTo: loadingCover.bottomAnchor),
            shade.topAnchor.constraint(equalTo: loadingCover.topAnchor),
            shade.leadingAnchor.constraint(equalTo: loadingCover.leadingAnchor),
            shade.trailingAnchor.constraint(equalTo: loadingCover.trailingAnchor),
            shade.bottomAnchor.constraint(equalTo: loadingCover.bottomAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingCover.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingCover.centerYAnchor),
            retryButton.centerXAnchor.constraint(equalTo: loadingCover.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 24),
            retryButton.widthAnchor.constraint(equalToConstant: 150),
            retryButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func installPurchaseShield() {
        purchaseShield.backgroundColor = UIColor(red: 0.035, green: 0.012, blue: 0.105, alpha: 0.55)
        purchaseShield.isHidden = true
        purchaseShield.translatesAutoresizingMaskIntoConstraints = false
        purchaseIndicator.color = .white
        purchaseIndicator.translatesAutoresizingMaskIntoConstraints = false
        purchaseShield.addSubview(purchaseIndicator)
        view.addSubview(purchaseShield)
        NSLayoutConstraint.activate([
            purchaseShield.topAnchor.constraint(equalTo: view.topAnchor),
            purchaseShield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            purchaseShield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            purchaseShield.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            purchaseIndicator.centerXAnchor.constraint(equalTo: purchaseShield.centerXAnchor),
            purchaseIndicator.centerYAnchor.constraint(equalTo: purchaseShield.centerYAnchor)
        ])
    }

    private func loadDestination() {
        retryButton.isHidden = true
        loadingIndicator.startAnimating()
        webView.load(URLRequest(url: destinationURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25))
    }

    @objc private func retryTapped() { loadDestination() }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !firstFramePresented else { return }
        firstFramePresented = true
        loadingIndicator.stopAnimating()
        loadingCover.removeFromSuperview()
        let elapsed = Int64(Date().timeIntervalSince(startedAt) * 1000)
        firstFrameHandler?(elapsed)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { handleInitialFailure() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { handleInitialFailure() }

    private func handleInitialFailure() {
        guard !firstFramePresented else { return }
        if firstNavigationRetryCount == 0 {
            firstNavigationRetryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in self?.loadDestination() }
        } else {
            loadingIndicator.stopAnimating()
            retryButton.isHidden = false
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(origin.protocol.lowercased() == "https" ? .grant : .deny)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case Self.rechargeHandler: handleRecharge(message.body)
        case Self.logoutHandler: handleLogout(message.body)
        case Self.browserHandler: handleBrowser(message.body)
        default: break
        }
    }

    private func handleRecharge(_ body: Any) {
        guard let values = NightHubBridgeContract.stringArray(from: body, count: 2), !values[0].isEmpty, !values[1].isEmpty else {
            let order = (NightHubBridgeContract.stringArray(from: body, count: 2)?[1]) ?? ""
            dispatch(event: NightHubBridgeContract.rechargeStateEvent, detail: ["failed", order, "Invalid purchase request."])
            return
        }
        CoinPurchaseManager.shared.beginRemotePurchase(productIdentifier: values[0], orderIdentifier: values[1])
    }

    private func handleLogout(_ body: Any) {
        guard let values = NightHubBridgeContract.stringArray(from: body, count: 1), !values[0].isEmpty else { return }
        logoutHandler?(values[0])
    }

    private func handleBrowser(_ body: Any) {
        guard let values = NightHubBridgeContract.stringArray(from: body, count: 2),
              let url = NightHubBridgeContract.validatedSystemURL(from: values) else {
            let attempted = (NightHubBridgeContract.stringArray(from: body, count: 2)?[1]) ?? ""
            dispatch(event: NightHubBridgeContract.openStateEvent, detail: ["failed", attempted])
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            self?.dispatch(event: NightHubBridgeContract.openStateEvent, detail: [success ? "success" : "failed", values[1]])
        }
    }

    private func handlePurchase(_ event: NightHubRemotePurchaseEvent) {
        switch event {
        case .requesting, .purchasing, .verifying:
            guard firstFramePresented else { return }
            purchaseShield.isHidden = false
            purchaseIndicator.startAnimating()
        case .success(let order, let message):
            hidePurchaseShield()
            dispatch(event: NightHubBridgeContract.rechargeStateEvent, detail: ["success", order, message])
        case .failed(let order, let message):
            hidePurchaseShield()
            dispatch(event: NightHubBridgeContract.rechargeStateEvent, detail: ["failed", order, message])
        }
    }

    private func hidePurchaseShield() {
        purchaseIndicator.stopAnimating()
        purchaseShield.isHidden = true
    }

    private func dispatch(event: String, detail: [String]) {
        guard JSONSerialization.isValidJSONObject(detail),
              let data = try? JSONSerialization.data(withJSONObject: detail, options: []),
              let json = String(data: data, encoding: .utf8),
              let eventData = try? JSONSerialization.data(withJSONObject: event, options: [.fragmentsAllowed]),
              let eventJSON = String(data: eventData, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\(eventJSON),{detail:\(json)}));", completionHandler: nil)
    }
}
