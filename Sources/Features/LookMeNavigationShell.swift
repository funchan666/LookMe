import UIKit
import AVFoundation

final class LookMeNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var childForStatusBarStyle: UIViewController? { topViewController }
}

final class LookMeNavigationShell: UITabBarController, UINavigationControllerDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var childForStatusBarStyle: UIViewController? { selectedViewController }
    private let customBar = UIView()
    private let buttonStack = UIStackView()
    private var tabButtons: [UIButton] = []
    private let normalIcons = ["video", "heart", "waveform.circle", "envelope", "person.crop.circle"]
    private let selectedIcons = ["video.fill", "heart.fill", "waveform.circle.fill", "envelope.fill", "person.crop.circle.fill"]
    private var welcomeCoins: Int?

    init(welcomeCoins: Int? = nil) {
        self.welcomeCoins = welcomeCoins
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let discovery = PresenceDiscoveryViewController()
        discovery.onCreate = { [weak self] in self?.presentCreator() }
        let controllers: [UIViewController] = [
            nav(StoryReelsViewController()),
            nav(discovery),
            nav(InterestRoomsViewController()),
            nav(ActivityInboxViewController()),
            nav(PersonalPresenceViewController())
        ]
        controllers.forEach { $0.additionalSafeAreaInsets.bottom = 48 }
        viewControllers = controllers
        tabBar.isHidden = true
        buildCustomBar()
        selectTab(1)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(customBar)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let amount = welcomeCoins, presentedViewController == nil else { return }
        welcomeCoins = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in self?.present(WelcomeCoinViewController(amount: amount), animated: true) }
    }

    private func nav(_ root: UIViewController) -> UINavigationController {
        let nav = LookMeNavigationController(rootViewController: root); nav.delegate = self
        nav.navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = LMTheme.background
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: LMTheme.font(size: 18, weight: .bold)]
        nav.navigationBar.standardAppearance = appearance; nav.navigationBar.scrollEdgeAppearance = appearance; nav.navigationBar.tintColor = .white
        return nav
    }

    private func buildCustomBar() {
        // Keep the navigation surface opaque so scrolling rows never ghost
        // through the icon bar at the bottom edge.
        customBar.backgroundColor = UIColor(red: 0.035, green: 0.012, blue: 0.13, alpha: 1)
        customBar.layer.borderWidth = 0
        customBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customBar)
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        customBar.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            customBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customBar.heightAnchor.constraint(equalToConstant: 82),
            buttonStack.topAnchor.constraint(equalTo: customBar.topAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: customBar.leadingAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: customBar.trailingAnchor, constant: -12),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        for index in normalIcons.indices {
            let button = UIButton(type: .system)
            button.tag = index
            button.accessibilityIdentifier = "main.tab.\(index)"
            button.tintColor = UIColor.white.withAlphaComponent(0.58)
            button.setImage(UIImage(systemName: normalIcons[index], withConfiguration: UIImage.SymbolConfiguration(pointSize: index == 2 ? 23 : 22, weight: .medium)), for: .normal)
            button.accessibilityLabel = ["Video", "Discover", "Party", "Message", "Profile"][index].lmLocalized
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            buttonStack.addArrangedSubview(button)
            tabButtons.append(button)
        }
    }

    @objc private func tabTapped(_ sender: UIButton) { selectTab(sender.tag) }

    @objc private func presentCreator() {
        let hub = LookMeCreateHubViewController()
        hub.onGoLive = { [weak self, weak hub] in
            hub?.dismiss(animated: true) { (self?.selectedViewController as? UINavigationController)?.pushViewController(LiveBroadcastSetupViewController(), animated: true) }
        }
        hub.onPostVideo = { [weak self, weak hub] in
            hub?.dismiss(animated: true) { (self?.selectedViewController as? UINavigationController)?.pushViewController(CommunityMomentComposerViewController(mode: .videoOnly), animated: true) }
        }
        present(hub, animated: true)
    }

    private func selectTab(_ index: Int) {
        selectedIndex = index
        customBar.isHidden = false
        for (buttonIndex, button) in tabButtons.enumerated() {
            let selected = buttonIndex == index
            button.setImage(UIImage(systemName: selected ? selectedIcons[buttonIndex] : normalIcons[buttonIndex], withConfiguration: UIImage.SymbolConfiguration(pointSize: buttonIndex == 2 ? 23 : 22, weight: .medium)), for: .normal)
            button.tintColor = selected ? LMTheme.pink : UIColor.white.withAlphaComponent(0.58)
            button.transform = selected ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isRoot = navigationController.viewControllers.first === viewController
        customBar.isHidden = !isRoot
        navigationController.additionalSafeAreaInsets.bottom = isRoot ? 48 : 0
    }
}

private final class LookMeCreateHubViewController: UIViewController {
    var onGoLive: (() -> Void)?
    var onPostVideo: (() -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
            sheetPresentationController.preferredCornerRadius = 30
            sheetPresentationController.prefersGrabberVisible = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMTheme.background
        let eyebrow = UILabel.lm("CREATE", size: 10, weight: .heavy, color: LMTheme.pinkSoft)
        let title = UILabel.lm("What do you want to share?", size: 23, weight: .bold); title.font = LMTheme.displayFont(size: 23, weight: .bold)
        let note = UILabel.lm("Start a live conversation or submit a video moment for review.", size: 11, weight: .medium, color: LMTheme.muted); note.numberOfLines = 0
        let live = createCard(title: "Go live", note: "Camera + microphone · live conversation", symbol: "dot.radiowaves.left.and.right", identifier: "create.goLive", selector: #selector(goLive))
        let video = createCard(title: "Post a video", note: "Choose from Photos or record a new scene", symbol: "play.rectangle.fill", identifier: "create.postVideo", selector: #selector(postVideo))
        [eyebrow,title,note,live,video].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        NSLayoutConstraint.activate([
            eyebrow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22), eyebrow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            title.topAnchor.constraint(equalTo: eyebrow.bottomAnchor, constant: 7), title.leadingAnchor.constraint(equalTo: eyebrow.leadingAnchor), title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6), note.leadingAnchor.constraint(equalTo: title.leadingAnchor), note.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            live.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 18), live.leadingAnchor.constraint(equalTo: title.leadingAnchor), live.trailingAnchor.constraint(equalTo: title.trailingAnchor), live.heightAnchor.constraint(equalToConstant: 82),
            video.topAnchor.constraint(equalTo: live.bottomAnchor, constant: 10), video.leadingAnchor.constraint(equalTo: live.leadingAnchor), video.trailingAnchor.constraint(equalTo: live.trailingAnchor), video.heightAnchor.constraint(equalTo: live.heightAnchor)
        ])
    }

    private func createCard(title: String, note: String, symbol: String, identifier: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system); button.accessibilityIdentifier = identifier; button.backgroundColor = LMTheme.panel; button.round(18); button.layer.borderWidth = 1; button.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor; button.addTarget(self, action: selector, for: .touchUpInside)
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold))); icon.tintColor = identifier == "create.goLive" ? LMTheme.pinkSoft : UIColor(red: 0.62, green: 0.48, blue: 1, alpha: 1); icon.backgroundColor = LMTheme.violet.withAlphaComponent(0.42); icon.contentMode = .center; icon.round(22)
        let heading = UILabel.lm(title, size: 16, weight: .bold); let detail = UILabel.lm(note, size: 10, weight: .medium, color: LMTheme.muted); let arrow = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold))); arrow.tintColor = .white.withAlphaComponent(0.6)
        [icon,heading,detail,arrow].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; button.addSubview($0) }
        NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 14), icon.centerYAnchor.constraint(equalTo: button.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 44), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), heading.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12), heading.topAnchor.constraint(equalTo: button.topAnchor, constant: 20), detail.leadingAnchor.constraint(equalTo: heading.leadingAnchor), detail.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 5), detail.trailingAnchor.constraint(lessThanOrEqualTo: arrow.leadingAnchor, constant: -8), arrow.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16), arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor)])
        return button
    }

    @objc private func goLive() { onGoLive?() }
    @objc private func postVideo() { onPostVideo?() }
}

final class LiveBroadcastSetupViewController: LMViewController {
    private let titleField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Go live"
        let hero = UIImageView(image: UIImage(named: "presence-constellation-field.png")); hero.contentMode = .scaleAspectFill; hero.clipsToBounds = true; hero.round(24)
        let badge = UILabel.lm("  LIVE STUDIO  ", size: 10, weight: .heavy); badge.backgroundColor = LMTheme.pink; badge.round(11)
        let heading = UILabel.lm("Open a live conversation", size: 24, weight: .bold); heading.font = LMTheme.displayFont(size: 24, weight: .bold)
        let note = UILabel.lm("Add a clear title. Camera and microphone access are requested only after you tap Start live.", size: 12, weight: .medium, color: LMTheme.muted); note.numberOfLines = 0
        let fieldLabel = UILabel.lm("LIVE TITLE", size: 10, weight: .heavy, color: LMTheme.pinkSoft)
        titleField.accessibilityIdentifier = "goLive.title"; titleField.attributedPlaceholder = NSAttributedString(string: "Example: A quiet city walk", attributes: [.foregroundColor: LMTheme.muted]); titleField.textColor = .white; titleField.font = LMTheme.font(size: 15, weight: .semibold); titleField.backgroundColor = LMTheme.panel; titleField.round(17); titleField.setLeftPadding(16); titleField.returnKeyType = .done
        let start = UIButton.lm("Start live", symbol: "dot.radiowaves.left.and.right"); start.accessibilityIdentifier = "goLive.start"; start.backgroundColor = LMTheme.pink; start.round(27); start.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        [hero,badge,heading,note,fieldLabel,titleField,start].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18), hero.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18), hero.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18), hero.heightAnchor.constraint(equalToConstant: 190),
            badge.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 16), badge.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -16), badge.heightAnchor.constraint(equalToConstant: 23),
            heading.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 22), heading.leadingAnchor.constraint(equalTo: hero.leadingAnchor), heading.trailingAnchor.constraint(equalTo: hero.trailingAnchor),
            note.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 7), note.leadingAnchor.constraint(equalTo: heading.leadingAnchor), note.trailingAnchor.constraint(equalTo: heading.trailingAnchor),
            fieldLabel.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 25), fieldLabel.leadingAnchor.constraint(equalTo: note.leadingAnchor),
            titleField.topAnchor.constraint(equalTo: fieldLabel.bottomAnchor, constant: 9), titleField.leadingAnchor.constraint(equalTo: note.leadingAnchor), titleField.trailingAnchor.constraint(equalTo: note.trailingAnchor), titleField.heightAnchor.constraint(equalToConstant: 54),
            start.leadingAnchor.constraint(equalTo: titleField.leadingAnchor), start.trailingAnchor.constraint(equalTo: titleField.trailingAnchor), start.heightAnchor.constraint(equalToConstant: 56), start.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22)
        ])
    }

    @objc private func startTapped() {
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard (3...48).contains(title.count) else { present(LMNoticeViewController(style: .warning, title: "Name your live", message: "Use a clear title between 3 and 48 characters."), animated: true); return }
        let decision = LookMeContentPolicy.evaluate(title)
        guard decision.isAllowed else { present(LMNoticeViewController(style: .warning, title: "Please revise the title", message: decision.rejectionReason?.userMessage ?? "Choose a safer, clearer live title."), animated: true); return }
        CallPermissionManager.request(video: true, from: self) { [weak self] in self?.navigationController?.pushViewController(CreatorLiveBroadcastViewController(broadcastTitle: title), animated: true) }
    }
}

private final class CreatorLiveBroadcastViewController: UIViewController {
    private let broadcastTitle: String
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.lookme.creator.broadcast.capture")
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let elapsedLabel = UILabel.lm("00:00", size: 11, weight: .bold)
    private var elapsed = 0
    private var timer: Timer?

    init(broadcastTitle: String) { self.broadcastTitle = broadcastTitle; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black; navigationController?.setNavigationBarHidden(true, animated: false)
        previewLayer.videoGravity = .resizeAspectFill; view.layer.addSublayer(previewLayer)
        let shade = UIView(); shade.isUserInteractionEnabled = false; shade.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(shade); NSLayoutConstraint.activate([shade.leadingAnchor.constraint(equalTo: view.leadingAnchor), shade.trailingAnchor.constraint(equalTo: view.trailingAnchor), shade.bottomAnchor.constraint(equalTo: view.bottomAnchor), shade.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.36)]); DispatchQueue.main.async { LMTheme.gradient(shade, colors: [.clear, UIColor.black.withAlphaComponent(0.82)], horizontal: false) }
        let live = UILabel.lm("  ● LIVE  ", size: 10, weight: .heavy); live.backgroundColor = LMTheme.pink; live.round(11)
        let title = UILabel.lm(broadcastTitle, size: 18, weight: .bold); title.numberOfLines = 2
        elapsedLabel.backgroundColor = UIColor.black.withAlphaComponent(0.34); elapsedLabel.textAlignment = .center; elapsedLabel.round(15)
        let end = UIButton.lm("End", symbol: "xmark"); end.accessibilityIdentifier = "goLive.end"; end.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9); end.round(18); end.addTarget(self, action: #selector(endTapped), for: .touchUpInside)
        let status = UILabel.lm("Your camera and microphone are live", size: 11, weight: .medium, color: .white.withAlphaComponent(0.72))
        [live,title,elapsedLabel,end,status].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        NSLayoutConstraint.activate([
            live.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12), live.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14), live.heightAnchor.constraint(equalToConstant: 24),
            elapsedLabel.leadingAnchor.constraint(equalTo: live.trailingAnchor, constant: 8), elapsedLabel.centerYAnchor.constraint(equalTo: live.centerYAnchor), elapsedLabel.widthAnchor.constraint(equalToConstant: 58), elapsedLabel.heightAnchor.constraint(equalToConstant: 30),
            end.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14), end.centerYAnchor.constraint(equalTo: live.centerYAnchor), end.widthAnchor.constraint(equalToConstant: 76), end.heightAnchor.constraint(equalToConstant: 36),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18), title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18), title.bottomAnchor.constraint(equalTo: status.topAnchor, constant: -6),
            status.leadingAnchor.constraint(equalTo: title.leadingAnchor), status.trailingAnchor.constraint(equalTo: title.trailingAnchor), status.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        configureSession()
    }

    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); previewLayer.frame = view.bounds }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); startSession(); timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() } }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); timer?.invalidate(); timer = nil; stopSession(); navigationController?.setNavigationBarHidden(false, animated: false) }
    deinit { timer?.invalidate(); stopSession() }

    private func configureSession() {
        session.beginConfiguration(); session.sessionPreset = .high
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: camera), session.canAddInput(input) { session.addInput(input) }
        if let microphone = AVCaptureDevice.default(for: .audio), let input = try? AVCaptureDeviceInput(device: microphone), session.canAddInput(input) { session.addInput(input) }
        session.commitConfiguration(); previewLayer.session = session
    }

    private func startSession() { sessionQueue.async { [weak session] in guard let session, !session.isRunning else { return }; session.startRunning() } }
    private func stopSession() { sessionQueue.async { [weak session] in guard let session, session.isRunning else { return }; session.stopRunning() } }
    private func tick() { elapsed += 1; elapsedLabel.text = String(format: "%02d:%02d", elapsed / 60, elapsed % 60) }
    @objc private func endTapped() { stopSession(); let notice = LMNoticeViewController(style: .success, title: "Live ended", message: "Your live conversation has ended safely."); notice.onDone = { [weak self] in self?.navigationController?.popViewController(animated: true) }; present(notice, animated: true) }
}
