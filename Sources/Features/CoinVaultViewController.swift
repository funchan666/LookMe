import UIKit

final class CoinVaultViewController: LMViewController {
    private let balanceLabel = UILabel.lm(size: 34, weight: .heavy)
    private let packages = CoinPackage.all
    private weak var progress: CoinPurchaseLoadingViewController?
    private var observers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Coin Vault"
        navigationItem.backButtonTitle = ""
        balanceLabel.accessibilityIdentifier = "coin.balance"
        buildInterface()
        refreshBalance()
        CoinPurchaseManager.shared.startObserving()
        observers.append(NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refreshBalance() })
        observers.append(NotificationCenter.default.addObserver(forName: .lookMeCoinPurchaseEvent, object: nil, queue: .main) { [weak self] note in
            guard let event = note.object as? CoinPurchaseEvent else { return }
            self?.handle(event)
        })
    }

    deinit { observers.forEach(NotificationCenter.default.removeObserver) }

    private func buildInterface() {
        let scroll = UIScrollView(); scroll.showsVerticalScrollIndicator = false; scroll.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(scroll)
        let content = UIStackView(); content.axis = .vertical; content.spacing = 14; content.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 14), content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 14), content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -14), content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28), content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -28)
        ])

        content.addArrangedSubview(balanceHero())
        content.addArrangedSubview(sectionTitle("CHOOSE YOUR COIN DROP", detail: "Apple securely handles every purchase"))

        for start in stride(from: 0, to: packages.count, by: 2) {
            let row = UIStackView(); row.axis = .horizontal; row.distribution = .fillEqually; row.spacing = 10
            for index in start..<min(start + 2, packages.count) {
                let card = CoinPackageButton(package: packages[index]); card.tag = index; card.addTarget(self, action: #selector(packageTapped(_:)), for: .touchUpInside); row.addArrangedSubview(card)
            }
            if row.arrangedSubviews.count == 1 { let spacer = UIView(); row.addArrangedSubview(spacer) }
            row.heightAnchor.constraint(equalToConstant: 108).isActive = true
            content.addArrangedSubview(row)
        }

        content.setCustomSpacing(24, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(sectionTitle("WHERE COINS GO", detail: "Social essentials always stay free"))
        content.addArrangedSubview(spendingGuide())

        let footer = UILabel.lm("Coins are consumable digital items. Messaging, following, comments, and voice or video calls never use coins.", size: 11, weight: .medium, color: UIColor.white.withAlphaComponent(0.5)); footer.numberOfLines = 0; footer.textAlignment = .center
        content.addArrangedSubview(footer)
    }

    private func balanceHero() -> UIView {
        let hero = LMGradientView(colors: [LMTheme.violet.withAlphaComponent(0.92), LMTheme.pink.withAlphaComponent(0.88)], horizontal: true); hero.round(24); hero.heightAnchor.constraint(equalToConstant: 154).isActive = true
        let orbit = UIView(); orbit.layer.borderWidth = 1; orbit.layer.borderColor = UIColor.white.withAlphaComponent(0.32).cgColor; orbit.round(37); orbit.translatesAutoresizingMaskIntoConstraints = false; hero.addSubview(orbit)
        let coin = UIImageView(image: UIImage(named: "lookme-presence-mark.png")); coin.contentMode = .scaleAspectFill; coin.clipsToBounds = true; coin.round(27); coin.layer.borderWidth = 1.5; coin.layer.borderColor = UIColor(red: 1, green: 0.83, blue: 0.25, alpha: 0.9).cgColor; coin.translatesAutoresizingMaskIntoConstraints = false; orbit.addSubview(coin)
        let eyebrow = UILabel.lm("YOUR LIVE BALANCE", size: 10, weight: .heavy, color: .white.withAlphaComponent(0.72)); eyebrow.letterSpacing(1.3)
        let unit = UILabel.lm("COINS", size: 11, weight: .heavy, color: .white.withAlphaComponent(0.72)); unit.letterSpacing(1.2)
        let secure = UILabel.lm("✦  synced instantly", size: 11, weight: .semibold, color: .white.withAlphaComponent(0.72))
        [eyebrow, balanceLabel, unit, secure].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; hero.addSubview($0) }
        NSLayoutConstraint.activate([
            orbit.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 20), orbit.centerYAnchor.constraint(equalTo: hero.centerYAnchor), orbit.widthAnchor.constraint(equalToConstant: 74), orbit.heightAnchor.constraint(equalTo: orbit.widthAnchor), coin.centerXAnchor.constraint(equalTo: orbit.centerXAnchor), coin.centerYAnchor.constraint(equalTo: orbit.centerYAnchor), coin.widthAnchor.constraint(equalToConstant: 54), coin.heightAnchor.constraint(equalTo: coin.widthAnchor),
            eyebrow.leadingAnchor.constraint(equalTo: orbit.trailingAnchor, constant: 18), eyebrow.topAnchor.constraint(equalTo: hero.topAnchor, constant: 27),
            balanceLabel.leadingAnchor.constraint(equalTo: eyebrow.leadingAnchor), balanceLabel.topAnchor.constraint(equalTo: eyebrow.bottomAnchor, constant: 5),
            unit.leadingAnchor.constraint(equalTo: balanceLabel.trailingAnchor, constant: 8), unit.firstBaselineAnchor.constraint(equalTo: balanceLabel.firstBaselineAnchor),
            secure.leadingAnchor.constraint(equalTo: eyebrow.leadingAnchor), secure.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 7)
        ])
        return hero
    }

    private func sectionTitle(_ title: String, detail: String) -> UIView {
        let holder = UIView(); holder.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let titleLabel = UILabel.lm(title, size: 11, weight: .heavy); titleLabel.letterSpacing(1.0)
        let detailLabel = UILabel.lm(detail, size: 10, weight: .medium, color: LMTheme.muted)
        [titleLabel, detailLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; holder.addSubview($0) }
        NSLayoutConstraint.activate([titleLabel.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 2), titleLabel.topAnchor.constraint(equalTo: holder.topAnchor), detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)])
        return holder
    }

    private func spendingGuide() -> UIView {
        let panel = UIStackView(); panel.axis = .vertical; panel.spacing = 0; panel.backgroundColor = LMTheme.panel; panel.round(18)
        let uses = [
            ("gift.fill", "Live & room gifts", "25–520 coins", "A visible gift sent by you"),
            ("sparkles", "Room entrance effects", "260–680 coins", "One animated entrance effect"),
            ("person.crop.circle.badge.plus", "Profile aura drops", "220–460 coins", "One collectible profile effect"),
            ("bubble.left.and.bubble.right.fill", "Chat, calls & follows", "Always free", "Never charged")
        ]
        uses.enumerated().forEach { index, item in
            let row = CoinSpendGuideRow(symbol: item.0, title: item.1, cost: item.2, note: item.3); panel.addArrangedSubview(row)
            if index < uses.count - 1 { let line = UIView(); line.backgroundColor = UIColor.white.withAlphaComponent(0.06); line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true; panel.addArrangedSubview(line) }
        }
        return panel
    }

    private func refreshBalance() { balanceLabel.text = LookMeExperienceStore.shared.coins.formatted() }

    @objc private func packageTapped(_ sender: UIButton) {
        guard packages.indices.contains(sender.tag) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        CoinPurchaseManager.shared.purchase(packages[sender.tag])
    }

    private func handle(_ event: CoinPurchaseEvent) {
        switch event {
        case .requesting(let package):
            let progress = CoinPurchaseLoadingViewController(package: package); self.progress = progress; present(progress, animated: true)
        case .purchasing:
            progress?.showAppleConfirmation()
        case .success(let package):
            finishProgress { [weak self] in
                guard let self else { return }
                self.refreshBalance()
                self.present(LMNoticeViewController(style: .success, title: "+\(package.coins.formatted()) coins", message: "Your Coin Vault updated instantly. New balance: \(LookMeExperienceStore.shared.coins.formatted()) coins."), animated: true)
            }
        case .deferred:
            finishProgress { [weak self] in self?.present(LMNoticeViewController(style: .review, title: "Awaiting approval", message: "Apple marked this purchase as pending. Coins will arrive automatically after approval."), animated: true) }
        case .failure(let message):
            finishProgress { [weak self] in self?.present(LMNoticeViewController(style: .warning, title: "Purchase not completed", message: message), animated: true) }
        }
    }

    private func finishProgress(_ completion: @escaping () -> Void) {
        if let progress { progress.dismiss(animated: true, completion: completion) } else { completion() }
        progress = nil
    }
}

final class CoinPackageButton: UIButton {
    init(package: CoinPackage) {
        super.init(frame: .zero); backgroundColor = LMTheme.panel; round(18); layer.borderWidth = 1; layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        let icon = UIImageView(image: UIImage(systemName: "seal.fill")); icon.tintColor = UIColor(red: 1, green: 0.76, blue: 0.18, alpha: 1)
        let amount = UILabel.lm(package.coins.formatted(), size: 18, weight: .heavy); let unit = UILabel.lm("COINS", size: 9, weight: .heavy, color: LMTheme.muted); let price = UILabel.lm(package.displayPrice, size: 13, weight: .bold, color: LMTheme.pinkSoft)
        [icon, amount, unit, price].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }
        NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13), icon.topAnchor.constraint(equalTo: topAnchor, constant: 15), icon.widthAnchor.constraint(equalToConstant: 24), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), amount.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8), amount.centerYAnchor.constraint(equalTo: icon.centerYAnchor), unit.leadingAnchor.constraint(equalTo: amount.leadingAnchor), unit.topAnchor.constraint(equalTo: amount.bottomAnchor, constant: 4), price.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13), price.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13)])
        if let badge = package.badge { let badgeLabel = UILabel.lm("  \(badge)  ", size: 8, weight: .heavy); badgeLabel.backgroundColor = LMTheme.pink; badgeLabel.round(8); badgeLabel.translatesAutoresizingMaskIntoConstraints = false; addSubview(badgeLabel); NSLayoutConstraint.activate([badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10), badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9), badgeLabel.heightAnchor.constraint(equalToConstant: 16)]) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class CoinSpendGuideRow: UIView {
    init(symbol: String, title: String, cost: String, note: String) {
        super.init(frame: .zero); heightAnchor.constraint(equalToConstant: 68).isActive = true
        let iconHolder = UIView(); iconHolder.backgroundColor = LMTheme.violet.withAlphaComponent(0.28); iconHolder.round(18)
        let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = LMTheme.pinkSoft
        let titleLabel = UILabel.lm(title, size: 13, weight: .bold); let noteLabel = UILabel.lm(note, size: 10, weight: .medium, color: LMTheme.muted); let costLabel = UILabel.lm(cost, size: 11, weight: .bold, color: cost == "Always free" ? .systemGreen : LMTheme.pinkSoft)
        [iconHolder, icon, titleLabel, noteLabel, costLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }
        NSLayoutConstraint.activate([iconHolder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13), iconHolder.centerYAnchor.constraint(equalTo: centerYAnchor), iconHolder.widthAnchor.constraint(equalToConstant: 36), iconHolder.heightAnchor.constraint(equalTo: iconHolder.widthAnchor), icon.centerXAnchor.constraint(equalTo: iconHolder.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconHolder.centerYAnchor), titleLabel.leadingAnchor.constraint(equalTo: iconHolder.trailingAnchor, constant: 11), titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: costLabel.leadingAnchor, constant: -8), noteLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), noteLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4), noteLabel.trailingAnchor.constraint(lessThanOrEqualTo: costLabel.leadingAnchor, constant: -8), costLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13), costLabel.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class CoinPurchaseLoadingViewController: UIViewController {
    private let status = UILabel.lm("Contacting the App Store…", size: 12, weight: .medium, color: .white.withAlphaComponent(0.66))
    init(package: CoinPackage) { super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(26); card.layer.borderWidth = 1; card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.3).cgColor; card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card)
        let spinner = UIActivityIndicatorView(style: .large); spinner.color = LMTheme.pinkSoft; spinner.startAnimating(); let title = UILabel.lm("Opening Coin Vault", size: 18, weight: .bold); status.textAlignment = .center
        [spinner, title, status].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        NSLayoutConstraint.activate([card.centerXAnchor.constraint(equalTo: view.centerXAnchor), card.centerYAnchor.constraint(equalTo: view.centerYAnchor), card.widthAnchor.constraint(equalToConstant: 270), card.heightAnchor.constraint(equalToConstant: 170), spinner.topAnchor.constraint(equalTo: card.topAnchor, constant: 28), spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor), title.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 13), title.centerXAnchor.constraint(equalTo: card.centerXAnchor), status.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 7), status.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), status.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)])
    }
    func showAppleConfirmation() { status.text = "Confirm securely with Apple" }
}

enum CoinPrompt {
    static func insufficient(from presenter: UIViewController, required: Int, activity: String, recharge: @escaping () -> Void) {
        let notice = LMNoticeViewController(style: .warning, title: "More coins needed", message: "\(activity) needs \(required.formatted()) coins. Your current balance is \(LookMeExperienceStore.shared.coins.formatted()).")
        notice.onDone = recharge
        presenter.present(notice, animated: true)
    }

    static func spent(from presenter: UIViewController, amount: Int, activity: String) {
        presenter.present(LMNoticeViewController(style: .success, title: "\(amount.formatted()) coins used", message: "\(activity) is ready. Your balance is now \(LookMeExperienceStore.shared.coins.formatted()) coins."), animated: true)
    }
}

private extension UILabel {
    func letterSpacing(_ value: CGFloat) { guard let text else { return }; attributedText = NSAttributedString(string: text, attributes: [.kern: value, .foregroundColor: textColor as Any, .font: font as Any]) }
}
