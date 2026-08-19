import UIKit

final class PersonalPresenceViewController: LMViewController {
    private let scroll = UIScrollView(); private let stack = UIStackView(); private let name = UILabel.lm(size: 19, weight: .bold); private let identity = UILabel.lm(size: 12, weight: .medium, color: LMTheme.muted); private let coinBalance = UILabel.lm(size: 25, weight: .heavy); private let friendsCount = UILabel.lm(size: 18, weight: .bold); private let followingCount = UILabel.lm(size: 18, weight: .bold); private let followersCount = UILabel.lm(size: 18, weight: .bold)
    private let dailyClaimButton = UIButton(type: .system)
    private weak var coinWalletCard: UIView?
    private weak var friendsButton: UIButton?
    private weak var followingButton: UIButton?
    private weak var followersButton: UIButton?
    override func viewDidLoad() {
        super.viewDidLoad()
        scroll.alwaysBounceVertical = true; scroll.showsVerticalScrollIndicator = false; scroll.contentInset.bottom = 116; scroll.verticalScrollIndicatorInsets.bottom = 116; view.addSubview(scroll); scroll.pin(to: view)
        stack.axis = .vertical; stack.spacing = 10; stack.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 4), stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 14), stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -14), stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24), stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -28)])
        buildHeader(); buildCounts(); buildWallet(); buildTask(); buildMenu()
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refresh() }; refresh()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: false); refresh() }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); navigationController?.setNavigationBarHidden(false, animated: false) }

    private func buildHeader() {
        let header = UIView(); header.heightAnchor.constraint(equalToConstant: 185).isActive = true
        let halo = UIImageView(image: UIImage(named: "profile-orbit-halo.png")); halo.contentMode = .scaleAspectFill; halo.alpha = 0.10; halo.translatesAutoresizingMaskIntoConstraints = false; header.addSubview(halo)
        let avatar = UIImageView(image: UIImage(named: CommunityMediaRegistry.currentUserAvatarAsset)); avatar.accessibilityIdentifier = "profile.avatar"; avatar.accessibilityLabel = "My profile photo"; avatar.accessibilityValue = CommunityMediaRegistry.currentUserAvatarAsset; avatar.isAccessibilityElement = true; avatar.contentMode = .scaleAspectFill; avatar.round(45); avatar.layer.borderWidth = 2.5; avatar.layer.borderColor = LMTheme.pinkSoft.cgColor; avatar.translatesAutoresizingMaskIntoConstraints = false; header.addSubview(avatar)
        let addPhoto = UIButton(type: .system); addPhoto.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)), for: .normal); addPhoto.tintColor = LMTheme.muted; addPhoto.backgroundColor = LMTheme.panel2; addPhoto.layer.borderWidth = 1.5; addPhoto.layer.borderColor = LMTheme.pinkSoft.withAlphaComponent(0.7).cgColor; addPhoto.round(31); addPhoto.addTarget(self, action: #selector(editProfile), for: .touchUpInside); addPhoto.translatesAutoresizingMaskIntoConstraints = false; header.addSubview(addPhoto)
        let tinyHeart = UIImageView(image: UIImage(systemName: "heart.fill")); tinyHeart.tintColor = LMTheme.pink; tinyHeart.translatesAutoresizingMaskIntoConstraints = false; header.addSubview(tinyHeart)
        let edit = UIButton(type: .system); edit.setImage(UIImage(systemName: "square.and.pencil"), for: .normal); edit.tintColor = .white; edit.addTarget(self, action: #selector(editProfile), for: .touchUpInside); edit.translatesAutoresizingMaskIntoConstraints = false
        let gear = UIButton(type: .system); gear.setImage(UIImage(systemName: "gearshape.fill"), for: .normal); gear.tintColor = .white; gear.accessibilityIdentifier = "profile.settings"; gear.accessibilityLabel = "Settings".lmLocalized; gear.addTarget(self, action: #selector(settings), for: .touchUpInside); gear.translatesAutoresizingMaskIntoConstraints = false
        [name, identity, edit, gear].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; header.addSubview($0) }; name.textAlignment = .center; identity.textAlignment = .center
        NSLayoutConstraint.activate([halo.topAnchor.constraint(equalTo: header.topAnchor), halo.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 50), halo.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -50), halo.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -35), gear.topAnchor.constraint(equalTo: header.topAnchor, constant: 9), gear.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -2), gear.widthAnchor.constraint(equalToConstant: 38), gear.heightAnchor.constraint(equalToConstant: 38), avatar.topAnchor.constraint(equalTo: header.topAnchor, constant: 20), avatar.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: -28), avatar.widthAnchor.constraint(equalToConstant: 90), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor), addPhoto.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 15), addPhoto.centerYAnchor.constraint(equalTo: avatar.centerYAnchor, constant: 5), addPhoto.widthAnchor.constraint(equalToConstant: 62), addPhoto.heightAnchor.constraint(equalTo: addPhoto.widthAnchor), tinyHeart.widthAnchor.constraint(equalToConstant: 18), tinyHeart.heightAnchor.constraint(equalTo: tinyHeart.widthAnchor), tinyHeart.trailingAnchor.constraint(equalTo: addPhoto.trailingAnchor, constant: 3), tinyHeart.topAnchor.constraint(equalTo: addPhoto.topAnchor, constant: -3), name.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 11), name.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: -8), edit.leadingAnchor.constraint(equalTo: name.trailingAnchor, constant: 5), edit.centerYAnchor.constraint(equalTo: name.centerYAnchor), edit.widthAnchor.constraint(equalToConstant: 24), edit.heightAnchor.constraint(equalToConstant: 24), identity.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 4), identity.centerXAnchor.constraint(equalTo: header.centerXAnchor)])
        stack.addArrangedSubview(header)
    }
    private func buildCounts() {
        let counts = UIStackView(); counts.axis = .horizontal; counts.distribution = .fillEqually; counts.heightAnchor.constraint(equalToConstant: 58).isActive = true
        [(friendsCount, "Friends", PersonalRelationshipListViewController.Scope.friends), (followingCount, "Following", .following), (followersCount, "Followers", .followers)].forEach { value, label, scope in
            let box = UIButton(type: .system)
            box.tag = scope.rawValue
            box.accessibilityIdentifier = "profile.relationship.\(scope.accessibilityKey)"
            box.accessibilityLabel = label.lmLocalized
            box.accessibilityTraits = .button
            box.addTarget(self, action: #selector(openRelationshipList(_:)), for: .touchUpInside)
            switch scope { case .friends: friendsButton = box; case .following: followingButton = box; case .followers: followersButton = box }
            let l = UILabel.lm(label, size: 11, weight: .medium, color: LMTheme.muted)
            value.textAlignment = .center; l.textAlignment = .center
            [value,l].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; box.addSubview($0) }
            NSLayoutConstraint.activate([value.topAnchor.constraint(equalTo: box.topAnchor, constant: 3), value.centerXAnchor.constraint(equalTo: box.centerXAnchor), l.topAnchor.constraint(equalTo: value.bottomAnchor, constant: 4), l.centerXAnchor.constraint(equalTo: box.centerXAnchor)])
            counts.addArrangedSubview(box)
        }
        stack.addArrangedSubview(counts)
    }
    private func buildWallet() {
        let wallet = LMGradientView(colors: [LMTheme.violet, LMTheme.pink], horizontal: true); wallet.round(14); wallet.heightAnchor.constraint(equalToConstant: 88).isActive = true; wallet.isUserInteractionEnabled = true; wallet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openRecharge))); wallet.isAccessibilityElement = true; wallet.accessibilityIdentifier = "profile.coinVault"; wallet.accessibilityLabel = "My Coin Vault"; wallet.accessibilityTraits = .button
        coinWalletCard = wallet
        let label = UILabel.lm("MY COIN VAULT", size: 10, weight: .heavy, color: .white.withAlphaComponent(0.7)); let hint = UILabel.lm("Tap to add coins", size: 11, weight: .semibold, color: .white.withAlphaComponent(0.72)); let coin = UIImageView(image: UIImage(systemName: "seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35, weight: .bold))); coin.tintColor = UIColor(red: 1, green: 0.82, blue: 0.23, alpha: 1)
        [label, coinBalance, hint, coin].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; wallet.addSubview($0) }
        NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: wallet.leadingAnchor, constant: 17), label.topAnchor.constraint(equalTo: wallet.topAnchor, constant: 13), coinBalance.leadingAnchor.constraint(equalTo: label.leadingAnchor), coinBalance.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4), hint.trailingAnchor.constraint(equalTo: wallet.trailingAnchor, constant: -17), hint.bottomAnchor.constraint(equalTo: wallet.bottomAnchor, constant: -15), coin.trailingAnchor.constraint(equalTo: wallet.trailingAnchor, constant: -18), coin.topAnchor.constraint(equalTo: wallet.topAnchor, constant: 13), coin.widthAnchor.constraint(equalToConstant: 38), coin.heightAnchor.constraint(equalTo: coin.widthAnchor)])
        stack.addArrangedSubview(wallet)
    }
    private func buildTask() {
        let task = UIView(); task.backgroundColor = LMTheme.panel; task.round(10); task.heightAnchor.constraint(equalToConstant: 58).isActive = true
        let icon = UIImageView(image: UIImage(systemName: "sparkles")); icon.tintColor = LMTheme.pinkSoft; let label = UILabel.lm("Daily Coin Drop  +50", size: 14, weight: .bold)
        dailyClaimButton.accessibilityIdentifier = "profile.dailyCoinClaim"; dailyClaimButton.setTitleColor(.white, for: .normal); dailyClaimButton.titleLabel?.font = LMTheme.font(size: 11, weight: .bold); dailyClaimButton.round(13); dailyClaimButton.addTarget(self, action: #selector(claim), for: .touchUpInside)
        [icon,label,dailyClaimButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; task.addSubview($0) }; NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: task.leadingAnchor, constant: 17), icon.centerYAnchor.constraint(equalTo: task.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 25), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 13), label.centerYAnchor.constraint(equalTo: task.centerYAnchor), dailyClaimButton.trailingAnchor.constraint(equalTo: task.trailingAnchor, constant: -15), dailyClaimButton.centerYAnchor.constraint(equalTo: task.centerYAnchor), dailyClaimButton.widthAnchor.constraint(equalToConstant: 72), dailyClaimButton.heightAnchor.constraint(equalToConstant: 26)]); stack.addArrangedSubview(task)
    }
    private func buildMenu() {
        let panel = UIStackView(); panel.axis = .vertical; panel.spacing = 0; panel.backgroundColor = LMTheme.panel; panel.round(10)
        panel.addArrangedSubview(menuButton("Store", "storefront.fill", #selector(openStore), accessory: "gifts, auras, entrance effects")); panel.addArrangedSubview(separator())
        panel.addArrangedSubview(menuButton("Backpack", "backpack.fill", #selector(openBackpack))); panel.addArrangedSubview(separator())
        panel.addArrangedSubview(toggleRow("Messages - Do Not Disturb", "bell.slash.fill", "message")); panel.addArrangedSubview(separator())
        panel.addArrangedSubview(toggleRow("Call - Do Not Disturb", "phone.down.fill", "call")); stack.addArrangedSubview(panel)
    }
    private func menuButton(_ title: String, _ symbol: String, _ selector: Selector, accessory: String? = nil) -> UIButton { let b = UIButton(type: .system); b.accessibilityIdentifier = "profile.menu.\(title.replacingOccurrences(of: " ", with: "").lowercased())"; b.accessibilityLabel = title.lmLocalized; b.heightAnchor.constraint(equalToConstant: 54).isActive = true; let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = title == "Store" ? UIColor(red: 1, green: 0.56, blue: 0.18, alpha: 1) : .white; let label = UILabel.lm(title, size: 14, weight: .bold); let detail = UILabel.lm(accessory ?? "›", size: accessory == nil ? 24 : 11, weight: .medium, color: accessory == nil ? .white : LMTheme.muted); [icon,label,detail].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; b.addSubview($0) }; NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: b.leadingAnchor, constant: 17), icon.centerYAnchor.constraint(equalTo: b.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 22), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 13), label.centerYAnchor.constraint(equalTo: b.centerYAnchor), detail.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: -15), detail.centerYAnchor.constraint(equalTo: b.centerYAnchor)]); b.addTarget(self, action: selector, for: .touchUpInside); return b }
    private func toggleRow(_ title: String, _ symbol: String, _ key: String) -> UIView { let row = UIView(); row.heightAnchor.constraint(equalToConstant: 54).isActive = true; let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = .white; let label = UILabel.lm(title, size: 14, weight: .bold); let toggle = UISwitch(); toggle.transform = CGAffineTransform(scaleX: 0.82, y: 0.82); toggle.onTintColor = LMTheme.pink; toggle.accessibilityIdentifier = key; toggle.isOn = key == "message" ? LookMeExperienceStore.shared.messageDND : LookMeExperienceStore.shared.callDND; toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged); [icon,label,toggle].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; row.addSubview($0) }; NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 17), icon.centerYAnchor.constraint(equalTo: row.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 22), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 13), label.centerYAnchor.constraint(equalTo: row.centerYAnchor), toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10), toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)]); return row }
    private func separator() -> UIView { let line = UIView(); line.backgroundColor = UIColor.white.withAlphaComponent(0.055); line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true; return line }
    private func refresh() {
        let store = LookMeExperienceStore.shared
        name.text = store.nickname
        identity.text = "✦ Ready for thoughtful connections"
        coinBalance.text = "\(store.coins.formatted()) coins"; coinWalletCard?.accessibilityValue = coinBalance.text
        let visibleIDs = Set(store.visibleMembers().map(\.id))
        let visibleFollowing = store.following.intersection(visibleIDs)
        let visibleFollowers = store.incomingFollowers.intersection(visibleIDs)
        followingCount.text = "\(visibleFollowing.count)"; followersCount.text = "\(visibleFollowers.count)"; friendsCount.text = "\(visibleFollowing.intersection(visibleFollowers).count)"
        followingButton?.accessibilityValue = followingCount.text; followersButton?.accessibilityValue = followersCount.text; friendsButton?.accessibilityValue = friendsCount.text
        refreshDailyClaim()
    }
    private func refreshDailyClaim() { let available = LookMeExperienceStore.shared.canClaimDailyCoinDrop; dailyClaimButton.isEnabled = available; dailyClaimButton.setTitle((available ? "Claim" : "Collected").lmLocalized, for: .normal); dailyClaimButton.backgroundColor = available ? UIColor(red: 1, green: 0.54, blue: 0.22, alpha: 1) : LMTheme.muted.withAlphaComponent(0.42); dailyClaimButton.alpha = available ? 1 : 0.76 }
    @objc private func toggleChanged(_ sender: UISwitch) { if sender.accessibilityIdentifier == "message" { LookMeExperienceStore.shared.messageDND = sender.isOn } else { LookMeExperienceStore.shared.callDND = sender.isOn } }
    @objc private func editProfile() { navigationController?.pushViewController(EditProfileViewController(), animated: true) }
    @objc private func settings() { navigationController?.pushViewController(SettingsViewController(), animated: true) }
    @objc private func openStore() { navigationController?.pushViewController(EffectBoutiqueViewController(), animated: true) }
    @objc private func openRecharge() { navigationController?.pushViewController(CoinVaultViewController(), animated: true) }
    @objc private func openBackpack() { navigationController?.pushViewController(BackpackViewController(), animated: true) }
    @objc private func openRelationshipList(_ sender: UIButton) { guard let scope = PersonalRelationshipListViewController.Scope(rawValue: sender.tag) else { return }; navigationController?.pushViewController(PersonalRelationshipListViewController(scope: scope), animated: true) }
    @objc private func claim() { if LookMeExperienceStore.shared.claimDailyTask() { present(LMNoticeViewController(style: .success, title: "+50 coins", message: "Today's Coin Drop landed in your balance."), animated: true) } else { present(LMNoticeViewController(style: .review, title: "Already collected", message: "Your next free Coin Drop arrives tomorrow."), animated: true) } }
}

final class PersonalRelationshipListViewController: LMViewController, UITableViewDataSource, UITableViewDelegate {
    enum Scope: Int {
        case friends, following, followers

        var title: String {
            switch self { case .friends: return "Friends"; case .following: return "Following"; case .followers: return "Followers" }
        }
        var accessibilityKey: String {
            switch self { case .friends: return "friends"; case .following: return "following"; case .followers: return "followers" }
        }
        var summary: String {
            switch self {
            case .friends: return "People you independently chose to follow each other."
            case .following: return "People whose presence and moments you follow."
            case .followers: return "People who chose to follow your presence."
            }
        }
        var emptyTitle: String {
            switch self { case .friends: return "No mutual connections yet"; case .following: return "You are not following anyone yet"; case .followers: return "No followers yet" }
        }
        var emptyMessage: String {
            switch self {
            case .friends: return "A connection appears here only after both people choose to follow each other."
            case .following: return "Explore profiles and follow people whose updates you want to see."
            case .followers: return "New followers will appear here when they choose to follow you."
            }
        }
    }

    private let scope: Scope
    private let table = UITableView(frame: .zero, style: .plain)
    private var profiles: [CommunityProfile] {
        let store = LookMeExperienceStore.shared
        return store.visibleMembers().filter { member in
            switch scope {
            case .friends: return store.following.contains(member.id) && store.incomingFollowers.contains(member.id)
            case .following: return store.following.contains(member.id)
            case .followers: return store.incomingFollowers.contains(member.id)
            }
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    init(scope: Scope) { self.scope = scope; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = scope.title
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 66))
        let summary = UILabel.lm(scope.summary, size: 12, weight: .medium, color: LMTheme.muted)
        summary.numberOfLines = 2; summary.translatesAutoresizingMaskIntoConstraints = false; header.addSubview(summary)
        NSLayoutConstraint.activate([summary.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 19), summary.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -19), summary.centerYAnchor.constraint(equalTo: header.centerYAnchor)])
        table.tableHeaderView = header
        table.backgroundColor = .clear; table.separatorStyle = .none; table.rowHeight = 84; table.showsVerticalScrollIndicator = false
        table.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 28, right: 0)
        table.dataSource = self; table.delegate = self; table.register(PersonalRelationshipCell.self, forCellReuseIdentifier: "relationshipRow")
        table.accessibilityIdentifier = "relationship.list.\(scope.accessibilityKey)"
        view.addSubview(table); table.pin(to: view)
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); refresh() }

    private func refresh() {
        table.reloadData()
        guard profiles.isEmpty else { table.backgroundView = nil; return }
        let empty = UIView()
        let iconHolder = UIView(); iconHolder.backgroundColor = LMTheme.violet.withAlphaComponent(0.28); iconHolder.round(32)
        let icon = UIImageView(image: UIImage(systemName: scope == .friends ? "person.2.fill" : "person.crop.circle.badge.questionmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 27, weight: .semibold))); icon.tintColor = LMTheme.pinkSoft
        let heading = UILabel.lm(scope.emptyTitle, size: 18, weight: .bold); heading.textAlignment = .center
        let message = UILabel.lm(scope.emptyMessage, size: 12, weight: .medium, color: LMTheme.muted); message.textAlignment = .center; message.numberOfLines = 0
        [iconHolder,icon,heading,message].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        empty.addSubview(iconHolder); iconHolder.addSubview(icon); empty.addSubview(heading); empty.addSubview(message)
        NSLayoutConstraint.activate([iconHolder.centerXAnchor.constraint(equalTo: empty.centerXAnchor), iconHolder.centerYAnchor.constraint(equalTo: empty.centerYAnchor, constant: -55), iconHolder.widthAnchor.constraint(equalToConstant: 64), iconHolder.heightAnchor.constraint(equalTo: iconHolder.widthAnchor), icon.centerXAnchor.constraint(equalTo: iconHolder.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconHolder.centerYAnchor), heading.topAnchor.constraint(equalTo: iconHolder.bottomAnchor, constant: 18), heading.leadingAnchor.constraint(equalTo: empty.leadingAnchor, constant: 24), heading.trailingAnchor.constraint(equalTo: empty.trailingAnchor, constant: -24), message.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 8), message.leadingAnchor.constraint(equalTo: empty.leadingAnchor, constant: 36), message.trailingAnchor.constraint(equalTo: empty.trailingAnchor, constant: -36)])
        table.backgroundView = empty
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { profiles.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "relationshipRow", for: indexPath) as! PersonalRelationshipCell
        cell.configure(member: profiles[indexPath.row], scope: scope)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(CommunityProfileDetailViewController(member: profiles[indexPath.row]), animated: true)
    }
}

private final class PersonalRelationshipCell: UITableViewCell {
    private let panel = UIView(); private let avatar = UIImageView(); private let nameLabel = UILabel.lm(size: 15, weight: .bold); private let detailLabel = UILabel.lm(size: 11, weight: .medium, color: LMTheme.muted); private let relation = UILabel.lm(size: 10, weight: .bold); private let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)))
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear; selectionStyle = .none
        panel.backgroundColor = LMTheme.panel; panel.round(15); panel.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(panel)
        avatar.contentMode = .scaleAspectFill; avatar.clipsToBounds = true; avatar.round(25); avatar.layer.borderWidth = 1.5; avatar.layer.borderColor = LMTheme.pink.withAlphaComponent(0.65).cgColor
        relation.textAlignment = .center; relation.backgroundColor = LMTheme.violet.withAlphaComponent(0.5); relation.round(11)
        chevron.tintColor = LMTheme.muted
        [avatar,nameLabel,detailLabel,relation,chevron].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; panel.addSubview($0) }
        NSLayoutConstraint.activate([panel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14), panel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14), panel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5), panel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5), avatar.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 12), avatar.centerYAnchor.constraint(equalTo: panel.centerYAnchor), avatar.widthAnchor.constraint(equalToConstant: 50), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor), nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12), nameLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16), nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: relation.leadingAnchor, constant: -8), detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor), detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5), relation.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -9), relation.centerYAnchor.constraint(equalTo: panel.centerYAnchor), relation.heightAnchor.constraint(equalToConstant: 23), relation.widthAnchor.constraint(greaterThanOrEqualToConstant: 62), chevron.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -13), chevron.centerYAnchor.constraint(equalTo: panel.centerYAnchor)])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(member: CommunityProfile, scope: PersonalRelationshipListViewController.Scope) {
        avatar.image = UIImage(named: member.image); nameLabel.text = member.name; detailLabel.text = "\(member.country)  \(member.region) · \(member.presenceTier)"
        let mutual = LookMeExperienceStore.shared.isMutual(with: member.id)
        switch scope { case .friends: relation.text = "  Mutual  "; case .following: relation.text = mutual ? "  Mutual  " : "  Following  "; case .followers: relation.text = mutual ? "  Mutual  " : "  Follows you  " }
        accessibilityIdentifier = "relationship.member.\(member.id)"; accessibilityLabel = "\(member.name), \(relation.text?.trimmingCharacters(in: .whitespaces) ?? "")"; accessibilityTraits = .button
    }
}

final class EditProfileViewController: LMViewController {
    private let nickname = UITextField(); private let gender = UITextField(); private let birthday = UITextField(); private let country = UITextField()
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Edit profile"
        let avatar = UIImageView(image: UIImage(named: CommunityMediaRegistry.currentUserAvatarAsset)); avatar.contentMode = .scaleAspectFill; avatar.round(44); avatar.layer.borderWidth = 2; avatar.layer.borderColor = LMTheme.pink.cgColor; avatar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(avatar)
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 10; stack.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(stack)
        [("Nickname", nickname, LookMeExperienceStore.shared.nickname), ("Gender", gender, LookMeExperienceStore.shared.gender), ("Birthday", birthday, LookMeExperienceStore.shared.birthday), ("Country", country, LookMeExperienceStore.shared.country)].forEach { label, field, value in let l = UILabel.lm(label.uppercased(), size: 10, weight: .bold, color: LMTheme.muted); field.text = value; field.textColor = .white; field.font = LMTheme.font(size: 15, weight: .medium); field.backgroundColor = LMTheme.panel; field.layer.cornerRadius = 10; field.setLeftPadding(14); field.heightAnchor.constraint(equalToConstant: 48).isActive = true; stack.addArrangedSubview(l); stack.addArrangedSubview(field) }
        let save = UIButton.lm("Save changes", symbol: "checkmark.circle.fill"); save.backgroundColor = LMTheme.pink; save.round(24); save.heightAnchor.constraint(equalToConstant: 50).isActive = true; save.addTarget(self, action: #selector(saveProfile), for: .touchUpInside); stack.addArrangedSubview(save)
        NSLayoutConstraint.activate([avatar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18), avatar.centerXAnchor.constraint(equalTo: view.centerXAnchor), avatar.widthAnchor.constraint(equalToConstant: 88), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor), stack.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 22), stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)])
    }
    @objc private func saveProfile() { guard let n = nickname.text?.trimmingCharacters(in: .whitespaces), !n.isEmpty else { return }; LookMeExperienceStore.shared.nickname = n; LookMeExperienceStore.shared.gender = gender.text ?? ""; LookMeExperienceStore.shared.birthday = birthday.text ?? ""; LookMeExperienceStore.shared.country = country.text ?? ""; navigationController?.popViewController(animated: true) }
}

final class SettingsViewController: LMViewController {
    private let selectedLanguageLabel = UILabel.lm(size: 12, weight: .semibold, color: LMTheme.pinkSoft)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings".lmLocalized

        let scroll = UIScrollView(); scroll.showsVerticalScrollIndicator = false; scroll.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(scroll)
        let content = UIStackView(); content.axis = .vertical; content.spacing = 9; content.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20), content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 14), content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -14), content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24), content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -28)
        ])

        content.addArrangedSubview(sectionHeading("LANGUAGE & REGION"))
        let languagePanel = UIStackView(); languagePanel.axis = .vertical; languagePanel.backgroundColor = LMTheme.panel; languagePanel.round(14)
        let languageRow = settingsRow("App language", symbol: "character.bubble.fill", detailLabel: selectedLanguageLabel, tag: 10)
        languageRow.accessibilityIdentifier = "settings.language"
        languageRow.addTarget(self, action: #selector(openLanguagePicker), for: .touchUpInside)
        languagePanel.addArrangedSubview(languageRow); content.addArrangedSubview(languagePanel)

        content.setCustomSpacing(20, after: languagePanel)
        content.addArrangedSubview(sectionHeading("ACCOUNT & PRIVACY"))
        let accountPanel = UIStackView(); accountPanel.axis = .vertical; accountPanel.spacing = 0; accountPanel.backgroundColor = LMTheme.panel; accountPanel.round(14)
        [("Privacy Policy", "hand.raised.fill", 0), ("Terms of Service", "doc.text.fill", 1), ("Community Guidelines", "person.3.fill", 2), ("Blocked accounts", "person.crop.circle.badge.xmark", 3), ("About NightHub", "sparkles", 4)].enumerated().forEach { index, data in
            let row = settingsRow(data.0, symbol: data.1, tag: data.2); row.addTarget(self, action: #selector(rowTap(_:)), for: .touchUpInside); accountPanel.addArrangedSubview(row)
            if index < 4 { accountPanel.addArrangedSubview(separator()) }
        }
        content.addArrangedSubview(accountPanel)

        content.setCustomSpacing(18, after: accountPanel)
        let signOut = UIButton.lm("Sign out", symbol: "rectangle.portrait.and.arrow.right"); signOut.backgroundColor = LMTheme.panel; signOut.configuration?.baseForegroundColor = .systemRed; signOut.round(14); signOut.heightAnchor.constraint(equalToConstant: 52).isActive = true; signOut.addTarget(self, action: #selector(logout), for: .touchUpInside); content.addArrangedSubview(signOut)
        let delete = UIButton.lm("Delete account", symbol: "trash.fill"); delete.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12); delete.configuration?.baseForegroundColor = .systemRed; delete.round(14); delete.heightAnchor.constraint(equalToConstant: 52).isActive = true; delete.addTarget(self, action: #selector(deleteAccount), for: .touchUpInside); content.addArrangedSubview(delete)
        refreshLanguageName()
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); refreshLanguageName() }

    private func sectionHeading(_ text: String) -> UILabel {
        let label = UILabel.lm(text, size: 11, weight: .bold, color: LMTheme.muted); label.heightAnchor.constraint(equalToConstant: 20).isActive = true; return label
    }

    private func settingsRow(_ text: String, symbol: String, detailLabel: UILabel? = nil, tag: Int) -> UIButton {
        let row = UIButton(type: .system); row.tag = tag; row.heightAnchor.constraint(equalToConstant: 58).isActive = true
        let iconHolder = UIView(); iconHolder.backgroundColor = LMTheme.violet.withAlphaComponent(0.24); iconHolder.round(17)
        let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = LMTheme.pinkSoft; icon.contentMode = .scaleAspectFit
        let label = UILabel.lm(text, size: 14, weight: .semibold)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right")); chevron.tintColor = LMTheme.muted
        let views = [iconHolder, icon, label, detailLabel, chevron].compactMap { $0 }; views.forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; row.addSubview($0) }
        var constraints = [
            iconHolder.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 13), iconHolder.centerYAnchor.constraint(equalTo: row.centerYAnchor), iconHolder.widthAnchor.constraint(equalToConstant: 34), iconHolder.heightAnchor.constraint(equalTo: iconHolder.widthAnchor),
            icon.centerXAnchor.constraint(equalTo: iconHolder.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconHolder.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 17), icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
            label.leadingAnchor.constraint(equalTo: iconHolder.trailingAnchor, constant: 12), label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -15), chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ]
        if let detailLabel { constraints.append(contentsOf: [detailLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -9), detailLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor), label.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -8)]) }
        NSLayoutConstraint.activate(constraints); return row
    }

    private func separator() -> UIView { let line = UIView(); line.backgroundColor = UIColor.white.withAlphaComponent(0.06); line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true; return line }
    private func refreshLanguageName() { selectedLanguageLabel.text = LookMeLanguageCenter.shared.selectedLanguage.nativeName }

    @objc private func openLanguagePicker() {
        let picker = LanguageSelectionViewController()
        picker.onSelection = { AppRouter.shared.refreshInterfaceLanguage() }
        present(picker, animated: true)
    }
    @objc private func rowTap(_ sender: UIButton) { switch sender.tag { case 0: navigationController?.pushViewController(PolicyViewController(kind: .privacy), animated: true); case 1: navigationController?.pushViewController(PolicyViewController(kind: .terms), animated: true); case 2: navigationController?.pushViewController(PolicyViewController(kind: .community), animated: true); case 3: navigationController?.pushViewController(BlockedUsersViewController(), animated: true); default: navigationController?.pushViewController(PolicyViewController(kind: .about), animated: true) } }
    @objc private func logout() { let progress = AccountProgressViewController(title: "Signing out".lmLocalized, success: "Signed out successfully".lmLocalized); progress.onFinished = { AppRouter.shared.signOut() }; present(progress, animated: true) }
    @objc private func deleteAccount() { let progress = AccountProgressViewController(title: "Deleting account".lmLocalized, success: "Account deleted successfully".lmLocalized); progress.onFinished = { AppRouter.shared.deleteAccount() }; present(progress, animated: true) }
}

final class LanguageSelectionViewController: UIViewController {
    var onSelection: (() -> Void)?

    init() { super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.76)
        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(28); card.layer.borderWidth = 1; card.layer.borderColor = LMTheme.violet.withAlphaComponent(0.62).cgColor
        let handle = UIView(); handle.backgroundColor = UIColor.white.withAlphaComponent(0.16); handle.round(2)
        let eyebrow = UILabel.lm("NIGHTHUB AROUND THE WORLD", size: 9, weight: .heavy, color: LMTheme.pinkSoft); eyebrow.textAlignment = .center
        let title = UILabel.lm("Choose your language", size: 23, weight: .bold); title.font = LMTheme.displayFont(size: 23, weight: .bold); title.textAlignment = .center
        let note = UILabel.lm("The interface updates now and remembers your choice.", size: 11, weight: .medium, color: LMTheme.muted); note.textAlignment = .center; note.numberOfLines = 0
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 7
        LookMeInterfaceLanguage.allCases.enumerated().forEach { index, language in stack.addArrangedSubview(languageRow(language, tag: index)) }
        let later = UIButton.lm("Not now"); later.backgroundColor = UIColor.white.withAlphaComponent(0.07); later.round(20); later.addTarget(self, action: #selector(close), for: .touchUpInside)
        [card, handle, eyebrow, title, note, stack, later].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(card); [handle, eyebrow, title, note, stack, later].forEach(card.addSubview)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            handle.topAnchor.constraint(equalTo: card.topAnchor, constant: 12), handle.centerXAnchor.constraint(equalTo: card.centerXAnchor), handle.widthAnchor.constraint(equalToConstant: 38), handle.heightAnchor.constraint(equalToConstant: 4),
            eyebrow.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 18), eyebrow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), eyebrow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            title.topAnchor.constraint(equalTo: eyebrow.bottomAnchor, constant: 7), title.leadingAnchor.constraint(equalTo: eyebrow.leadingAnchor), title.trailingAnchor.constraint(equalTo: eyebrow.trailingAnchor),
            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6), note.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28), note.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 19), stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 13), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -13),
            later.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 15), later.leadingAnchor.constraint(equalTo: stack.leadingAnchor), later.trailingAnchor.constraint(equalTo: stack.trailingAnchor), later.heightAnchor.constraint(equalToConstant: 44), later.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -13)
        ])
    }

    private func languageRow(_ language: LookMeInterfaceLanguage, tag: Int) -> UIButton {
        let selected = language == LookMeLanguageCenter.shared.selectedLanguage
        let row = UIButton(type: .system); row.tag = tag; row.backgroundColor = selected ? LMTheme.violet.withAlphaComponent(0.34) : UIColor.white.withAlphaComponent(0.045); row.round(15); row.heightAnchor.constraint(equalToConstant: 55).isActive = true
        let monogram = UILabel.lm(language.monogram, size: 11, weight: .heavy); monogram.textAlignment = .center; monogram.backgroundColor = selected ? LMTheme.pink : LMTheme.panel2; monogram.round(16)
        let name = UILabel.lm(language.nativeName, size: 14, weight: .bold)
        let market = UILabel.lm(language.marketNote, size: 9, weight: .medium, color: LMTheme.muted)
        let check = UIImageView(image: UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")); check.tintColor = selected ? LMTheme.pinkSoft : UIColor.white.withAlphaComponent(0.24)
        [monogram, name, market, check].forEach { $0.isUserInteractionEnabled = false; $0.translatesAutoresizingMaskIntoConstraints = false; row.addSubview($0) }
        NSLayoutConstraint.activate([
            monogram.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 11), monogram.centerYAnchor.constraint(equalTo: row.centerYAnchor), monogram.widthAnchor.constraint(equalToConstant: 32), monogram.heightAnchor.constraint(equalTo: monogram.widthAnchor),
            name.leadingAnchor.constraint(equalTo: monogram.trailingAnchor, constant: 11), name.topAnchor.constraint(equalTo: row.topAnchor, constant: 11),
            market.leadingAnchor.constraint(equalTo: name.leadingAnchor), market.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 2),
            check.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -13), check.centerYAnchor.constraint(equalTo: row.centerYAnchor), check.widthAnchor.constraint(equalToConstant: 21), check.heightAnchor.constraint(equalTo: check.widthAnchor)
        ])
        row.accessibilityLabel = language.nativeName; row.accessibilityValue = selected ? "Selected".lmLocalized : nil; row.addTarget(self, action: #selector(selectLanguage(_:)), for: .touchUpInside); return row
    }

    @objc private func selectLanguage(_ sender: UIButton) {
        guard LookMeInterfaceLanguage.allCases.indices.contains(sender.tag) else { return }
        LookMeLanguageCenter.shared.select(LookMeInterfaceLanguage.allCases[sender.tag])
        UISelectionFeedbackGenerator().selectionChanged()
        dismiss(animated: true) { [weak self] in self?.onSelection?() }
    }

    @objc private func close() { dismiss(animated: true) }
}
