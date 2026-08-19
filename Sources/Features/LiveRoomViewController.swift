import UIKit
import AVFoundation

final class LiveRoomViewController: UIViewController, UITextFieldDelegate {
    private let member: CommunityProfile
    private let editorial: LiveBroadcastEditorial
    private let playerView = PlayerSurfaceView()
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var activityTimer: Timer?
    private var activityCursor = 0
    private let followButton = UIButton(type: .system)
    private let viewerLabel = UILabel.lm(size: 11, weight: .bold)
    private let chatStack = UIStackView()
    private let field = UITextField()
    private let heartCaption = UILabel.lm(size: 10, weight: .bold)
    private var hearts: Int

    init(member: CommunityProfile) {
        self.member = member
        let editorial = CommunityMediaRegistry.liveEditorial(for: member)
        self.editorial = editorial
        self.hearts = editorial.appreciationCount
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildVideoBackground()
        buildTopBar()
        buildActions()
        buildChat()
        buildComposer()
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in guard let self, LookMeExperienceStore.shared.blockedUsers.contains(self.member.id) else { return }; self.dismiss(animated: true) }
    }

    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); player?.play(); startAmbientActivity() }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); player?.pause(); activityTimer?.invalidate(); activityTimer = nil }
    deinit { activityTimer?.invalidate(); if let endObserver { NotificationCenter.default.removeObserver(endObserver) } }

    private func buildVideoBackground() {
        playerView.videoGravity = .resizeAspectFill; view.addSubview(playerView); playerView.pin(to: view)
        let videoName = CommunityMediaRegistry.liveVideo(for: member)
        if let url = Bundle.main.url(forResource: videoName, withExtension: nil) {
            let player = AVPlayer(url: url); player.isMuted = false; self.player = player; playerView.player = player
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak player] _ in player?.seek(to: .zero); player?.play() }
        } else {
            let fallback = UIImageView(image: UIImage(named: member.image)); fallback.contentMode = .scaleAspectFill; view.addSubview(fallback); fallback.pin(to: view)
        }
        let topShade = UIView(); topShade.isUserInteractionEnabled = false; topShade.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(topShade)
        let bottomShade = UIView(); bottomShade.isUserInteractionEnabled = false; bottomShade.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(bottomShade)
        NSLayoutConstraint.activate([topShade.topAnchor.constraint(equalTo: view.topAnchor), topShade.leadingAnchor.constraint(equalTo: view.leadingAnchor), topShade.trailingAnchor.constraint(equalTo: view.trailingAnchor), topShade.heightAnchor.constraint(equalToConstant: 190), bottomShade.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottomShade.trailingAnchor.constraint(equalTo: view.trailingAnchor), bottomShade.bottomAnchor.constraint(equalTo: view.bottomAnchor), bottomShade.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.46)])
        DispatchQueue.main.async { LMTheme.gradient(topShade, colors: [UIColor.black.withAlphaComponent(0.65), .clear], horizontal: false); LMTheme.gradient(bottomShade, colors: [.clear, UIColor.black.withAlphaComponent(0.82)], horizontal: false) }
    }

    private func buildTopBar() {
        let host = UIView(); host.backgroundColor = UIColor.black.withAlphaComponent(0.34); host.round(23); host.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(host)
        let avatar = UIButton(type: .custom); avatar.setImage(UIImage(named: member.image), for: .normal); avatar.imageView?.contentMode = .scaleAspectFill; avatar.clipsToBounds = true; avatar.round(19); avatar.layer.borderWidth = 1.5; avatar.layer.borderColor = LMTheme.pink.cgColor; avatar.accessibilityIdentifier = "live.hostAvatar"; avatar.accessibilityLabel = "Open \(member.name)'s profile"; avatar.addTarget(self, action: #selector(openHostProfile), for: .touchUpInside); avatar.translatesAutoresizingMaskIntoConstraints = false; host.addSubview(avatar)
        let name = UILabel.lm(member.name, size: 13, weight: .bold); let live = UILabel.lm("● LIVE", size: 9, weight: .heavy, color: LMTheme.pinkSoft); [name,live].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; host.addSubview($0) }
        followButton.setTitle("Follow".lmLocalized, for: .normal); followButton.setTitleColor(.white, for: .normal); followButton.titleLabel?.font = LMTheme.font(size: 11, weight: .bold); followButton.backgroundColor = LMTheme.pink; followButton.round(14); followButton.addTarget(self, action: #selector(toggleFollow), for: .touchUpInside); followButton.translatesAutoresizingMaskIntoConstraints = false; host.addSubview(followButton)
        viewerLabel.text = "👁  \(compact(editorial.viewerCount))"; viewerLabel.accessibilityIdentifier = "live.viewerCount"; viewerLabel.backgroundColor = UIColor.black.withAlphaComponent(0.34); viewerLabel.textAlignment = .center; viewerLabel.round(15); viewerLabel.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(viewerLabel)
        let more = topButton("ellipsis", #selector(safety)); more.accessibilityLabel = "Report or block"
        let close = topButton("xmark", #selector(closeRoom)); close.accessibilityLabel = "Close live room"
        let prompt = UILabel.lm("  ✦  \(editorial.roomPrompt)  ", size: 9, weight: .bold)
        prompt.backgroundColor = UIColor.black.withAlphaComponent(0.38); prompt.round(13); prompt.accessibilityIdentifier = "live.roomPrompt"; prompt.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(prompt)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), host.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), host.heightAnchor.constraint(equalToConstant: 46), host.widthAnchor.constraint(equalToConstant: 205),
            avatar.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 4), avatar.centerYAnchor.constraint(equalTo: host.centerYAnchor), avatar.widthAnchor.constraint(equalToConstant: 38), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8), name.topAnchor.constraint(equalTo: host.topAnchor, constant: 8), live.leadingAnchor.constraint(equalTo: name.leadingAnchor), live.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 1),
            followButton.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -5), followButton.centerYAnchor.constraint(equalTo: host.centerYAnchor), followButton.widthAnchor.constraint(equalToConstant: 58), followButton.heightAnchor.constraint(equalToConstant: 28),
            viewerLabel.leadingAnchor.constraint(equalTo: host.trailingAnchor, constant: 6), viewerLabel.centerYAnchor.constraint(equalTo: host.centerYAnchor), viewerLabel.widthAnchor.constraint(equalToConstant: 66), viewerLabel.heightAnchor.constraint(equalToConstant: 31),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), close.centerYAnchor.constraint(equalTo: host.centerYAnchor), close.widthAnchor.constraint(equalToConstant: 34), close.heightAnchor.constraint(equalToConstant: 34),
            more.trailingAnchor.constraint(equalTo: close.leadingAnchor, constant: -4), more.centerYAnchor.constraint(equalTo: close.centerYAnchor), more.widthAnchor.constraint(equalToConstant: 34), more.heightAnchor.constraint(equalToConstant: 34),
            prompt.topAnchor.constraint(equalTo: host.bottomAnchor, constant: 8), prompt.leadingAnchor.constraint(equalTo: host.leadingAnchor), prompt.heightAnchor.constraint(equalToConstant: 26), prompt.widthAnchor.constraint(lessThanOrEqualToConstant: 190)
        ])
        updateFollow()
    }

    private func topButton(_ symbol: String, _ selector: Selector) -> UIButton { let button = UIButton(type: .system); button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)), for: .normal); button.tintColor = .white; button.backgroundColor = UIColor.black.withAlphaComponent(0.34); button.round(17); button.translatesAutoresizingMaskIntoConstraints = false; button.addTarget(self, action: selector, for: .touchUpInside); view.addSubview(button); return button }

    private func buildActions() {
        let actions = UIStackView(); actions.axis = .vertical; actions.spacing = 14; actions.alignment = .center; actions.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(actions)
        let heart = LiveActionButton(symbol: "heart.fill", caption: ""); heart.button.tintColor = .white; heart.button.addTarget(self, action: #selector(sendHeart), for: .touchUpInside); heart.captionHost.addSubview(heartCaption); heartCaption.text = compact(hearts); heartCaption.accessibilityIdentifier = "live.appreciationCount"; heartCaption.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([heartCaption.centerXAnchor.constraint(equalTo: heart.captionHost.centerXAnchor), heartCaption.centerYAnchor.constraint(equalTo: heart.captionHost.centerYAnchor)])
        let gift = LiveActionButton(symbol: "gift.fill", caption: "Gift"); gift.button.addTarget(self, action: #selector(openGifts), for: .touchUpInside)
        let share = LiveActionButton(symbol: "arrowshape.turn.up.right.fill", caption: "Share"); share.button.addTarget(self, action: #selector(shareRoom), for: .touchUpInside)
        [heart,gift,share].forEach(actions.addArrangedSubview)
        NSLayoutConstraint.activate([actions.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -94), actions.widthAnchor.constraint(equalToConstant: 58)])
    }

    private func buildChat() {
        chatStack.axis = .vertical; chatStack.spacing = 6; chatStack.alignment = .leading; chatStack.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(chatStack)
        NSLayoutConstraint.activate([chatStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), chatStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -82), chatStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -82)])
        editorial.bulletins.prefix(2).forEach(addBulletin)
        activityCursor = min(2, editorial.bulletins.count)
    }

    private func buildComposer() {
        let composer = UIView(); composer.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(composer)
        field.delegate = self; field.returnKeyType = .send; field.attributedPlaceholder = NSAttributedString(string: "Say something nice…", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.64)]); field.textColor = .white; field.font = LMTheme.font(size: 13, weight: .medium); field.backgroundColor = UIColor.black.withAlphaComponent(0.42); field.layer.borderWidth = 0.7; field.layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor; field.layer.cornerRadius = 21; field.setLeftPadding(14); field.translatesAutoresizingMaskIntoConstraints = false; composer.addSubview(field)
        let send = UIButton(type: .system); send.setImage(UIImage(systemName: "paperplane.fill"), for: .normal); send.tintColor = .white; send.backgroundColor = LMTheme.pink; send.round(20); send.translatesAutoresizingMaskIntoConstraints = false; send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside); composer.addSubview(send)
        NSLayoutConstraint.activate([composer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), composer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12), composer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -7), composer.heightAnchor.constraint(equalToConstant: 44), field.leadingAnchor.constraint(equalTo: composer.leadingAnchor), field.topAnchor.constraint(equalTo: composer.topAnchor), field.bottomAnchor.constraint(equalTo: composer.bottomAnchor), send.leadingAnchor.constraint(equalTo: field.trailingAnchor, constant: 8), send.trailingAnchor.constraint(equalTo: composer.trailingAnchor), send.centerYAnchor.constraint(equalTo: composer.centerYAnchor), send.widthAnchor.constraint(equalToConstant: 40), send.heightAnchor.constraint(equalTo: send.widthAnchor)])
    }

    private func addChat(name: String, text: String, tint: UIColor) {
        if chatStack.arrangedSubviews.count >= 5 { chatStack.arrangedSubviews.first?.removeFromSuperview() }
        let label = UILabel.lm(size: 12, weight: .medium); label.numberOfLines = 2; label.backgroundColor = UIColor.black.withAlphaComponent(0.32); label.round(10); label.attributedText = NSAttributedString(string: "  \(name)  ", attributes: [.foregroundColor: tint, .font: LMTheme.font(size: 12, weight: .bold)]) + NSAttributedString(string: "\(text)  ", attributes: [.foregroundColor: UIColor.white, .font: LMTheme.font(size: 12, weight: .medium)]); label.heightAnchor.constraint(greaterThanOrEqualToConstant: 27).isActive = true; chatStack.addArrangedSubview(label)
    }

    private func addBulletin(_ bulletin: LiveRoomBulletin) {
        guard !LookMeExperienceStore.shared.blockedUsers.contains(bulletin.authorProfileKey) else { return }
        let prefix = bulletin.giftSymbol.map { "\($0) " } ?? ""
        addChat(name: bulletin.authorDisplayName, text: prefix + bulletin.activityText, tint: bulletin.giftSymbol == nil ? LMTheme.pinkSoft : UIColor(red: 1, green: 0.78, blue: 0.28, alpha: 1))
        chatStack.arrangedSubviews.last?.accessibilityIdentifier = bulletin.giftSymbol == nil ? "live.bulletin" : "live.giftActivity"
    }

    private func startAmbientActivity() {
        guard activityTimer == nil, !editorial.bulletins.isEmpty else { return }
        activityTimer = Timer.scheduledTimer(withTimeInterval: 5.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let bulletin = self.editorial.bulletins[self.activityCursor % self.editorial.bulletins.count]
            self.activityCursor += 1
            self.addBulletin(bulletin)
        }
    }

    private func compact(_ value: Int) -> String {
        value >= 1_000 ? String(format: "%.1fK", Double(value) / 1_000) : "\(value)"
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool { sendMessage(); return true }
    @objc private func sendMessage() { guard let message = field.text?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty else { return }; guard LookMeContentPolicy.allows(message) else { present(LMNoticeViewController(style: .warning, title: "Comment not posted", message: "Please revise content that may be unsafe, explicit, threatening or spam-like."), animated: true); return }; addChat(name: "Me", text: message, tint: LMTheme.pinkSoft); field.text = ""; field.resignFirstResponder() }
    @objc private func sendHeart() { hearts += 1; heartCaption.text = compact(hearts); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    @objc private func openGifts() { let sheet = LiveGiftSheetViewController(host: member.name); sheet.onSent = { [weak self] gift in self?.addChat(name: "Me", text: "sent \(gift)", tint: UIColor(red: 1, green: 0.76, blue: 0.22, alpha: 1)) }; present(sheet, animated: true) }
    @objc private func shareRoom() { present(UIActivityViewController(activityItems: ["Watch \(member.name) live on NightHub"], applicationActivities: nil), animated: true) }
    @objc private func toggleFollow() { LookMeExperienceStore.shared.toggleFollow(member.id); updateFollow() }
    private func updateFollow() { let following = LookMeExperienceStore.shared.following.contains(member.id); followButton.setTitle((following ? "Following" : "Follow").lmLocalized, for: .normal); followButton.backgroundColor = following ? UIColor.white.withAlphaComponent(0.24) : LMTheme.pink }
    @objc private func openHostProfile() {
        let profile = CommunityProfileDetailViewController(member: member)
        profile.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeHostProfile))
        profile.navigationItem.leftBarButtonItem?.accessibilityLabel = "Close profile"
        let navigation = UINavigationController(rootViewController: profile)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }
    @objc private func closeHostProfile() { presentedViewController?.dismiss(animated: true) }
    @objc private func safety() { SafetyCoordinator.present(from: self, target: .init(id: "live:\(member.id)", type: "live room", userID: member.id, displayName: member.name)) }
    @objc private func closeRoom() { dismiss(animated: true) }
}

final class LiveActionButton: UIView {
    let button = UIButton(type: .system); let captionHost = UIView()
    init(symbol: String, caption: String) {
        super.init(frame: .zero); button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)), for: .normal); button.tintColor = .white; button.backgroundColor = UIColor.black.withAlphaComponent(0.34); button.round(24); button.translatesAutoresizingMaskIntoConstraints = false; addSubview(button); captionHost.translatesAutoresizingMaskIntoConstraints = false; addSubview(captionHost); if !caption.isEmpty { let label = UILabel.lm(caption, size: 10, weight: .bold); label.translatesAutoresizingMaskIntoConstraints = false; captionHost.addSubview(label); NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: captionHost.centerXAnchor), label.centerYAnchor.constraint(equalTo: captionHost.centerYAnchor)]) }; NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: 58), heightAnchor.constraint(equalToConstant: 68), button.topAnchor.constraint(equalTo: topAnchor), button.centerXAnchor.constraint(equalTo: centerXAnchor), button.widthAnchor.constraint(equalToConstant: 48), button.heightAnchor.constraint(equalTo: button.widthAnchor), captionHost.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 2), captionHost.leadingAnchor.constraint(equalTo: leadingAnchor), captionHost.trailingAnchor.constraint(equalTo: trailingAnchor), captionHost.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class LiveGiftSheetViewController: UIViewController {
    var onSent: ((String) -> Void)?
    private let host: String
    private let balance = UILabel.lm(size: 12, weight: .semibold, color: LMTheme.muted)
    private let gifts = [("🌹", "Rose", 25), ("💋", "Kiss", 60), ("👑", "Crown", 180), ("🚀", "Rocket", 520)]
    init(host: String) { self.host = host; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .pageSheet; if let sheetPresentationController { sheetPresentationController.detents = [.medium()]; sheetPresentationController.prefersGrabberVisible = true } }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = LMTheme.background
        let title = UILabel.lm("Send a gift to \(host)", size: 20, weight: .bold); let stack = UIStackView(); stack.axis = .horizontal; stack.distribution = .fillEqually; stack.spacing = 8; [title,balance,stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        gifts.enumerated().forEach { index,gift in let button = GiftOptionButton(emoji: gift.0, name: gift.1, price: gift.2); button.tag = index; button.addTarget(self, action: #selector(sendGift(_:)), for: .touchUpInside); stack.addArrangedSubview(button) }
        NSLayoutConstraint.activate([title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20), title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18), balance.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18), balance.centerYAnchor.constraint(equalTo: title.centerYAnchor), stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 25), stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12), stack.heightAnchor.constraint(equalToConstant: 130)])
        refreshBalance(); NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refreshBalance() }
    }
    private func refreshBalance() { balance.text = "Balance  \(LookMeExperienceStore.shared.coins.formatted()) coins" }
    @objc private func sendGift(_ sender: UIButton) {
        let gift = gifts[sender.tag]; let presenter = presentingViewController
        guard LookMeExperienceStore.shared.spendCoins(gift.2, reason: "\(gift.1) live gift") else {
            dismiss(animated: true) {
                guard let presenter else { return }
                CoinPrompt.insufficient(from: presenter, required: gift.2, activity: "\(gift.1) live gift") { [weak presenter] in presenter?.navigationController?.pushViewController(CoinVaultViewController(), animated: true) }
            }
            return
        }
        onSent?(gift.0)
        dismiss(animated: true) { if let presenter { CoinPrompt.spent(from: presenter, amount: gift.2, activity: "Your \(gift.1) gift was sent") } }
    }
}

final class GiftOptionButton: UIButton {
    init(emoji: String, name: String, price: Int) { super.init(frame: .zero); backgroundColor = LMTheme.panel; round(12); let icon = UILabel.lm(emoji, size: 37); let title = UILabel.lm(name, size: 11, weight: .bold); let cost = UILabel.lm("● \(price)", size: 10, weight: .bold, color: LMTheme.pinkSoft); [icon,title,cost].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }; NSLayoutConstraint.activate([icon.topAnchor.constraint(equalTo: topAnchor, constant: 15), icon.centerXAnchor.constraint(equalTo: centerXAnchor), title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8), title.centerXAnchor.constraint(equalTo: centerXAnchor), cost.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5), cost.centerXAnchor.constraint(equalTo: centerXAnchor)]) }
    required init?(coder: NSCoder) { fatalError() }
}

private extension NSAttributedString {
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString { let result = NSMutableAttributedString(attributedString: lhs); result.append(rhs); return result }
}
