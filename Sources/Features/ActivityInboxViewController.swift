import UIKit

enum ActivityRoute { case member(CommunityProfile), profile(CommunityProfile), moments, none }
struct ActivityTimelineItem { let title: String; let subtitle: String; let image: String?; let symbol: String?; let tint: UIColor; let badge: String?; let time: String?; let destination: ActivityRoute }

final class ActivityInboxViewController: LMViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .plain)
    private var selectedTab = "Message"
    private var conversations: [CommunityProfile] { LookMeExperienceStore.shared.visibleMembers().filter { member in LookMeExperienceStore.shared.messages.contains(where: { $0.memberID == member.id }) } }
    private var items: [ActivityTimelineItem] {
        switch selectedTab {
        case "Follow":
            let followed = LookMeExperienceStore.shared.visibleMembers().filter { LookMeExperienceStore.shared.following.contains($0.id) }
            return followed.isEmpty ? [ActivityTimelineItem(title: "No followed people yet", subtitle: "Follow someone from Discover to see them here", image: nil, symbol: "person.badge.plus", tint: LMTheme.violet, badge: nil, time: nil, destination: .none)] : followed.map { ActivityTimelineItem(title: $0.name, subtitle: "Following · \($0.country)", image: $0.image, symbol: nil, tint: LMTheme.pink, badge: nil, time: nil, destination: .member($0)) }
        case "Calls":
            return [ActivityTimelineItem(title: "No recent calls", subtitle: "Calls you make will appear here", image: nil, symbol: "video.slash.fill", tint: LMTheme.violet, badge: nil, time: nil, destination: .none)]
        case "Moments":
            let moments = LookMeExperienceStore.shared.visibleMoments.map { moment in ActivityTimelineItem(title: moment.author, subtitle: moment.text, image: moment.image, symbol: moment.image == nil ? "sparkles" : nil, tint: LMTheme.pink, badge: nil, time: LookMeLanguageCenter.shared.relativeTime(from: moment.createdAt), destination: .moments) }
            return moments.isEmpty ? [ActivityTimelineItem(title: "No moments yet", subtitle: "Share a photo or video when you are ready", image: nil, symbol: "sparkles", tint: LMTheme.violet, badge: nil, time: nil, destination: .moments)] : moments
        default:
            let notices = LookMeExperienceStore.shared.systemNotices.compactMap { notice -> ActivityTimelineItem? in guard let id = notice.memberID, let member = LookMeCommunityDirectory.members.first(where: { $0.id == id }), !LookMeExperienceStore.shared.blockedUsers.contains(id) else { return nil }; return ActivityTimelineItem(title: notice.title, subtitle: notice.body, image: member.image, symbol: nil, tint: LMTheme.pink, badge: notice.isRead ? nil : "NEW", time: LookMeLanguageCenter.shared.relativeTime(from: notice.createdAt), destination: .profile(member)) }
            let people = conversations.map { member in ActivityTimelineItem(title: member.name, subtitle: LookMeExperienceStore.shared.messages.last(where: { $0.memberID == member.id })?.text ?? "", image: member.image, symbol: nil, tint: LMTheme.pink, badge: nil, time: LookMeExperienceStore.shared.messages.last(where: { $0.memberID == member.id }).map { DateFormatter.inboxTime.string(from: $0.sentAt) }, destination: .member(member)) }
            let all = notices + people
            return all.isEmpty ? [ActivityTimelineItem(title: "No messages yet", subtitle: "Mutual follows can start a conversation", image: nil, symbol: "bubble.left.and.bubble.right", tint: LMTheme.violet, badge: nil, time: nil, destination: .none)] : all
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let header = ActivityCategoryHeader(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 178)); header.configure(selected: selectedTab); header.onTab = { [weak self, weak header] value in self?.selectedTab = value; header?.configure(selected: value); self?.table.reloadData() }; header.onService = { [weak self, weak header] index in
            guard let self else { return }
            switch index {
            case 0: self.navigationController?.pushViewController(PlatformUpdatesViewController(), animated: true)
            case 1: self.selectedTab = "Follow"; header?.configure(selected: "Follow"); self.table.reloadData()
            default: break
            }
        }
        table.tableHeaderView = header; table.backgroundColor = .clear; table.separatorStyle = .none; table.rowHeight = 76; table.contentInset.bottom = 18; table.dataSource = self; table.delegate = self; table.register(ActivityTimelineCell.self, forCellReuseIdentifier: "inboxRow"); view.addSubview(table); table.pin(to: view)
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.table.reloadData() }
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: false); table.reloadData() }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); navigationController?.setNavigationBarHidden(false, animated: false) }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: "inboxRow", for: indexPath) as! ActivityTimelineCell; cell.configure(items[indexPath.row]); return cell }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true); switch items[indexPath.row].destination { case .member(let member): navigationController?.pushViewController(MutualConversationViewController(member: member), animated: true); case .profile(let member): if let notice = LookMeExperienceStore.shared.systemNotices.first(where: { $0.memberID == member.id && !$0.isRead }) { LookMeExperienceStore.shared.markNoticeRead(notice.id) }; navigationController?.pushViewController(CommunityProfileDetailViewController(member: member), animated: true); case .moments: navigationController?.pushViewController(MomentsFeedViewController(), animated: true); case .none: break } }
    private func showInfo(_ title: String, _ message: String) { let alert = UIAlertController(title: title, message: message, preferredStyle: .alert); alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true) }
}

final class PlatformUpdatesViewController: LMViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .plain)
    private let emptyState = UIView()
    private var notices: [ActivityNoticeRecord] {
        LookMeExperienceStore.shared.systemNotices.filter { notice in
            guard let profileKey = notice.memberID else { return true }
            return !LookMeExperienceStore.shared.blockedUsers.contains(profileKey)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Platform updates"
        table.accessibilityIdentifier = "platform.updates.list"
        table.backgroundColor = .clear; table.separatorStyle = .none; table.rowHeight = 82
        table.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 22, right: 0)
        table.dataSource = self; table.delegate = self
        table.register(ActivityTimelineCell.self, forCellReuseIdentifier: "platformUpdateRow")
        view.addSubview(table); table.pin(to: view)
        buildEmptyState()
        NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        refresh()
    }

    private func buildEmptyState() {
        emptyState.isAccessibilityElement = true; emptyState.accessibilityIdentifier = "platform.updates.empty"
        let halo = UIView(); halo.backgroundColor = UIColor(red: 0.98, green: 0.65, blue: 0.20, alpha: 0.16); halo.round(36)
        let icon = UIImageView(image: UIImage(systemName: "megaphone.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold))); icon.tintColor = UIColor(red: 1, green: 0.70, blue: 0.28, alpha: 1)
        let heading = UILabel.lm("You're all caught up", size: 19, weight: .bold); heading.textAlignment = .center
        let note = UILabel.lm("Account, safety and community updates will appear here.", size: 13, weight: .medium, color: LMTheme.muted); note.numberOfLines = 0; note.textAlignment = .center
        [halo, heading, note].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; emptyState.addSubview($0) }; icon.translatesAutoresizingMaskIntoConstraints = false; halo.addSubview(icon)
        table.backgroundView = emptyState
        NSLayoutConstraint.activate([halo.centerXAnchor.constraint(equalTo: emptyState.centerXAnchor), halo.centerYAnchor.constraint(equalTo: emptyState.centerYAnchor, constant: -58), halo.widthAnchor.constraint(equalToConstant: 72), halo.heightAnchor.constraint(equalTo: halo.widthAnchor), icon.centerXAnchor.constraint(equalTo: halo.centerXAnchor), icon.centerYAnchor.constraint(equalTo: halo.centerYAnchor), heading.topAnchor.constraint(equalTo: halo.bottomAnchor, constant: 18), heading.leadingAnchor.constraint(equalTo: emptyState.leadingAnchor, constant: 24), heading.trailingAnchor.constraint(equalTo: emptyState.trailingAnchor, constant: -24), note.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 8), note.leadingAnchor.constraint(equalTo: emptyState.leadingAnchor, constant: 40), note.trailingAnchor.constraint(equalTo: emptyState.trailingAnchor, constant: -40)])
    }

    private func item(for notice: ActivityNoticeRecord) -> ActivityTimelineItem {
        let member = notice.memberID.flatMap { key in LookMeCommunityDirectory.members.first(where: { $0.id == key }) }
        let symbol: String; let tint: UIColor
        switch notice.kind {
        case "follow": symbol = "person.badge.plus"; tint = LMTheme.pink
        case "reward": symbol = "seal.fill"; tint = UIColor(red: 0.98, green: 0.65, blue: 0.20, alpha: 1)
        default: symbol = "megaphone.fill"; tint = LMTheme.violet
        }
        return ActivityTimelineItem(title: notice.title, subtitle: notice.body, image: member?.image, symbol: member == nil ? symbol : nil, tint: tint, badge: notice.isRead ? nil : "NEW", time: LookMeLanguageCenter.shared.relativeTime(from: notice.createdAt), destination: member.map(ActivityRoute.profile) ?? .none)
    }

    private func refresh() {
        table.reloadData(); emptyState.isHidden = !notices.isEmpty
        navigationItem.rightBarButtonItem = notices.contains(where: { !$0.isRead }) ? UIBarButtonItem(title: "Mark all read", style: .plain, target: self, action: #selector(markAllRead)) : nil
    }

    @objc private func markAllRead() { LookMeExperienceStore.shared.markAllNoticesRead() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { notices.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: "platformUpdateRow", for: indexPath) as! ActivityTimelineCell; cell.configure(item(for: notices[indexPath.row])); return cell }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notice = notices[indexPath.row]; LookMeExperienceStore.shared.markNoticeRead(notice.id)
        if let profileKey = notice.memberID, let member = LookMeCommunityDirectory.members.first(where: { $0.id == profileKey }) {
            navigationController?.pushViewController(CommunityProfileDetailViewController(member: member), animated: true)
        } else {
            present(LMNoticeViewController(style: notice.kind == "reward" ? .success : .review, title: notice.title, message: notice.body), animated: true)
        }
    }
}

final class ActivityCategoryHeader: UIView {
    var onTab: ((String) -> Void)?; var onService: ((Int) -> Void)?
    private let tabs = UIStackView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        tabs.axis = .horizontal; tabs.spacing = 17; tabs.translatesAutoresizingMaskIntoConstraints = false; addSubview(tabs)
        let services = UIStackView(); services.axis = .horizontal; services.distribution = .fillEqually; services.translatesAutoresizingMaskIntoConstraints = false; addSubview(services)
        [("megaphone.fill", "Platform", UIColor(red: 0.98, green: 0.65, blue: 0.20, alpha: 1)), ("heart.fill", "Like you", UIColor(red: 1, green: 0.19, blue: 0.48, alpha: 1))].enumerated().forEach { index, data in let button = ServiceShortcut(symbol: data.0, title: data.1, color: data.2); button.tag = index; button.accessibilityIdentifier = ["activity.service.platform", "activity.service.likes"][index]; button.addTarget(self, action: #selector(serviceTap(_:)), for: .touchUpInside); services.addArrangedSubview(button) }
        NSLayoutConstraint.activate([tabs.topAnchor.constraint(equalTo: topAnchor, constant: 3), tabs.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), tabs.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12), tabs.heightAnchor.constraint(equalToConstant: 41), services.topAnchor.constraint(equalTo: tabs.bottomAnchor, constant: 10), services.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18), services.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18), services.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(selected: String) { tabs.arrangedSubviews.forEach { $0.removeFromSuperview() }; ["Message", "Follow", "Calls", "Moments"].forEach { value in let holder = UIView(); let b = UIButton(type: .system); b.setTitle(value.lmLocalized, for: .normal); b.setTitleColor(value == selected ? .white : LMTheme.muted, for: .normal); b.titleLabel?.font = LMTheme.font(size: 14, weight: value == selected ? .bold : .medium); b.translatesAutoresizingMaskIntoConstraints = false; b.addAction(UIAction { [weak self] _ in self?.onTab?(value) }, for: .touchUpInside); holder.addSubview(b); NSLayoutConstraint.activate([b.topAnchor.constraint(equalTo: holder.topAnchor), b.leadingAnchor.constraint(equalTo: holder.leadingAnchor), b.trailingAnchor.constraint(equalTo: holder.trailingAnchor), b.bottomAnchor.constraint(equalTo: holder.bottomAnchor)]); if value == selected { let line = UIView(); line.backgroundColor = LMTheme.pink; line.round(1.5); line.translatesAutoresizingMaskIntoConstraints = false; holder.addSubview(line); NSLayoutConstraint.activate([line.bottomAnchor.constraint(equalTo: holder.bottomAnchor), line.centerXAnchor.constraint(equalTo: holder.centerXAnchor), line.widthAnchor.constraint(equalToConstant: 22), line.heightAnchor.constraint(equalToConstant: 3)]) }; tabs.addArrangedSubview(holder) } }
    @objc private func serviceTap(_ sender: UIButton) { onService?(sender.tag) }
}

final class ServiceShortcut: UIButton {
    init(symbol: String, title: String, color: UIColor) {
        super.init(frame: .zero)
        let circle = UIView(); circle.isUserInteractionEnabled = false; circle.backgroundColor = color; circle.round(27); circle.layer.shadowColor = color.cgColor; circle.layer.shadowOpacity = 0.28; circle.layer.shadowRadius = 12; circle.translatesAutoresizingMaskIntoConstraints = false; addSubview(circle)
        let image = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold))); image.tintColor = .white; image.translatesAutoresizingMaskIntoConstraints = false; circle.addSubview(image)
        let label = UILabel.lm(title, size: 13, weight: .bold); label.textAlignment = .center; label.translatesAutoresizingMaskIntoConstraints = false; addSubview(label)
        NSLayoutConstraint.activate([circle.topAnchor.constraint(equalTo: topAnchor, constant: 2), circle.centerXAnchor.constraint(equalTo: centerXAnchor), circle.widthAnchor.constraint(equalToConstant: 54), circle.heightAnchor.constraint(equalTo: circle.widthAnchor), image.centerXAnchor.constraint(equalTo: circle.centerXAnchor), image.centerYAnchor.constraint(equalTo: circle.centerYAnchor), label.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 7), label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)])
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class ActivityTimelineCell: UITableViewCell {
    private let avatar = UIImageView(); private let icon = UIImageView(); private let titleLabel = UILabel.lm(size: 15, weight: .bold); private let subtitleLabel = UILabel.lm(size: 12, color: LMTheme.muted); private let timeLabel = UILabel.lm(size: 10, color: LMTheme.muted); private let badge = UILabel.lm(size: 9, weight: .bold)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier); backgroundColor = .clear; selectionStyle = .none
        avatar.contentMode = .scaleAspectFill; avatar.round(24); icon.contentMode = .center; icon.round(17); badge.backgroundColor = LMTheme.pink; badge.textAlignment = .center; badge.round(8)
        [avatar, icon, titleLabel, subtitleLabel, timeLabel, badge].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        NSLayoutConstraint.activate([avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14), avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor), avatar.widthAnchor.constraint(equalToConstant: 48), avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor), icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18), icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 42), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 11), titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8), subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4), subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -45), timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15), timeLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor), badge.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor), badge.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 7), badge.heightAnchor.constraint(equalToConstant: 16), badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 30)])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(_ item: ActivityTimelineItem) { titleLabel.text = item.title; subtitleLabel.text = item.subtitle; timeLabel.text = item.time; badge.text = item.badge.map { " \($0) " }; badge.isHidden = item.badge == nil; if let image = item.image { avatar.image = UIImage(named: image); avatar.isHidden = false; icon.isHidden = true } else { avatar.isHidden = true; icon.isHidden = false; icon.image = item.symbol.flatMap { UIImage(systemName: $0, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)) }; icon.tintColor = .white; icon.backgroundColor = item.tint } }
}

private extension DateFormatter { static let inboxTime: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }() }
