import UIKit
import WebKit

enum PolicyKind {
    case privacy, terms, community, about

    var remoteURL: URL? {
        switch self {
        case .terms: return URL(string: "https://sites.google.com/view/lookme-terms-of-service/home")
        case .privacy: return URL(string: "https://sites.google.com/view/lookme-privacypolicy/home")
        case .community, .about: return nil
        }
    }
}

final class PolicyViewController: LMViewController, WKNavigationDelegate {
    private let kind: PolicyKind
    private var progressObservation: NSKeyValueObservation?
    init(kind: PolicyKind) { self.kind = kind; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = content.title
        if navigationController?.presentingViewController != nil { navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }) }
        if let remoteURL = kind.remoteURL {
            configureWebView(url: remoteURL)
            return
        }
        let scroll = UIScrollView(); scroll.showsVerticalScrollIndicator = false; view.addSubview(scroll); scroll.pin(to: view)
        let hero = UIView(); hero.backgroundColor = LMTheme.panel; hero.round(20); hero.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(hero)
        let icon = UIImageView(image: UIImage(systemName: content.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold))); icon.tintColor = LMTheme.pink; let heading = UILabel.lm(content.title, size: 24, weight: .bold); let updated = UILabel.lm("Effective August 17, 2026", size: 11, weight: .semibold, color: LMTheme.muted); let body = UILabel.lm(content.body, size: 14, weight: .medium, color: UIColor.white.withAlphaComponent(0.82)); body.numberOfLines = 0
        [icon,heading,updated].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; hero.addSubview($0) }; body.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(body)
        NSLayoutConstraint.activate([hero.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 18), hero.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16), hero.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16), hero.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32), hero.heightAnchor.constraint(equalToConstant: 112), icon.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 18), icon.centerYAnchor.constraint(equalTo: hero.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 38), icon.heightAnchor.constraint(equalTo: icon.widthAnchor), heading.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 13), heading.topAnchor.constraint(equalTo: hero.topAnchor, constant: 28), updated.leadingAnchor.constraint(equalTo: heading.leadingAnchor), updated.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 5), body.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 20), body.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 5), body.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -5), body.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -30)])
    }

    private func configureWebView(url: URL) {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = LMTheme.background
        webView.scrollView.backgroundColor = LMTheme.background
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        let progress = UIProgressView(progressViewStyle: .bar)
        progress.progressTintColor = LMTheme.pink
        progress.trackTintColor = LMTheme.panel2
        progress.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progress)
        NSLayoutConstraint.activate([
            progress.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: progress.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { webView, _ in
            DispatchQueue.main.async {
                progress.setProgress(Float(webView.estimatedProgress), animated: true)
                progress.isHidden = webView.estimatedProgress >= 1
            }
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { showWebFailure() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { showWebFailure() }

    private func showWebFailure() {
        guard presentedViewController == nil else { return }
        present(LMNoticeViewController(style: .warning, title: "Page unavailable", message: "The agreement could not be loaded. Check your connection and try again."), animated: true)
    }
    private var content: (title: String, symbol: String, body: String) { switch kind {
        case .privacy: return ("Privacy Policy", "hand.raised.fill", "1. Information you provide\nWe store your profile, follows, messages, posts, reports and safety preferences on your device. Camera, microphone, photo library and location are accessed only after your permission and only for the feature you choose.\n\n2. How information is used\nInformation supports account access, mutual-follow messaging, calls, media publishing, safety moderation and regional discovery. We do not use anonymous matching or random chat.\n\n3. Your controls\nYou may revoke system permissions, unblock users, sign out or delete your account from Settings. Reports and blocks remain on your device so hidden content stays hidden.\n\n4. Safety and retention\nMessages and safety actions persist until you delete your account data. Submitted posts remain pending until moderation approval.\n\n5. Contact\nQuestions about this policy may be submitted through the App Store support channel associated with LookMe.")
        case .terms: return ("Terms of Service", "doc.text.fill", "1. Eligibility\nYou must be at least 18 years old and provide accurate account information.\n\n2. Respectful use\nDo not harass, threaten, impersonate, exploit, spam or share unlawful, hateful, sexual or unsafe material.\n\n3. Communication\nDirect messages and calls are available only when both people independently follow each other. LookMe does not create friendships, accept requests or enable anonymous or random chat on your behalf.\n\n4. User content\nYou retain responsibility for content you submit. New posts may be reviewed before appearing. Content may be hidden after a report or when its author is blocked.\n\n5. Enforcement\nViolations may lead to content removal, communication restrictions or account deletion.\n\n6. Account controls\nYou can sign out or delete your account from Settings at any time.")
        case .community: return ("Community Guidelines", "person.3.fill", "Be real and be respectful\nUse an authentic identity. Do not impersonate others or manipulate follows.\n\nConsent comes first\nMessages and calls require mutual follow. Never pressure someone to follow, reply, meet or share private information.\n\nKeep people safe\nNo bullying, threats, hate speech, sexual exploitation, graphic violence, scams, spam or promotion of dangerous activity. Content involving minors in sexual or exploitative contexts is strictly prohibited.\n\nProtect privacy\nDo not publish another person's private information, intimate media or location without permission.\n\nUse safety tools\nReport content that violates these rules. Block a person when you do not want to see their profile, content or conversations. Reports and blocks hide affected content immediately.\n\nPublishing review\nNew moments are submitted for review and appear only after approval. Repeated violations may result in account removal.")
        case .about: return ("About NightHub", "sparkles", "NightHub is a visual social community for authentic profiles, live rooms, short videos and consent-based conversations. Direct communication unlocks only after both people independently choose to follow each other.\n\nVersion 1.0") }
    }
}

final class BlockedUsersViewController: LMViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(); private let empty = UILabel.lm("Your blocked list is empty.", size: 14, weight: .medium, color: LMTheme.muted)
    private var members: [CommunityProfile] { LookMeCommunityDirectory.members.filter { LookMeExperienceStore.shared.blockedUsers.contains($0.id) } }
    override func viewDidLoad() { super.viewDidLoad(); title = "Blocked accounts"; table.backgroundColor = .clear; table.separatorStyle = .none; table.dataSource = self; table.delegate = self; view.addSubview(table); table.pin(to: view); empty.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(empty); NSLayoutConstraint.activate([empty.centerXAnchor.constraint(equalTo: view.centerXAnchor), empty.centerYAnchor.constraint(equalTo: view.centerYAnchor)]); NotificationCenter.default.addObserver(forName: .lookMeStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refresh() }; refresh() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let member = members[indexPath.row]; let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil); cell.backgroundColor = .clear; cell.textLabel?.text = member.name; cell.textLabel?.textColor = .white; cell.textLabel?.font = LMTheme.font(size: 15, weight: .bold); cell.detailTextLabel?.text = "\(member.country)  \(member.region)"; cell.detailTextLabel?.textColor = LMTheme.muted; var config = UIBackgroundConfiguration.clear(); config.backgroundColor = LMTheme.panel; config.cornerRadius = 15; config.backgroundInsets = NSDirectionalEdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12); cell.backgroundConfiguration = config; let button = UIButton.lm("Unblock"); button.tag = indexPath.row; button.configuration?.baseForegroundColor = LMTheme.pinkSoft; button.addTarget(self, action: #selector(unblock(_:)), for: .touchUpInside); cell.accessoryView = button; return cell }
    @objc private func unblock(_ sender: UIButton) { guard members.indices.contains(sender.tag) else { return }; LookMeExperienceStore.shared.unblockUser(members[sender.tag].id); present(LMNoticeViewController(style: .success, title: "Unblocked", message: "This person's profile and activity can appear again."), animated: true) }
    private func refresh() { table.reloadData(); empty.isHidden = !members.isEmpty }
}

final class AccountProgressViewController: UIViewController {
    var onFinished: (() -> Void)?; private let progressTitle: String; private let success: String
    init(title: String, success: String) { progressTitle = title; self.success = success; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.7); let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(25); card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card); let spinner = UIActivityIndicatorView(style: .large); spinner.color = LMTheme.pink; spinner.startAnimating(); let label = UILabel.lm(progressTitle, size: 17, weight: .bold); [spinner,label].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }; NSLayoutConstraint.activate([card.centerXAnchor.constraint(equalTo: view.centerXAnchor), card.centerYAnchor.constraint(equalTo: view.centerYAnchor), card.widthAnchor.constraint(equalToConstant: 230), card.heightAnchor.constraint(equalToConstant: 150), spinner.topAnchor.constraint(equalTo: card.topAnchor, constant: 30), spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor), label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 14), label.centerXAnchor.constraint(equalTo: card.centerXAnchor)]); let host = presentingViewController; DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in guard let self else { return }; self.dismiss(animated: true) { let notice = LMNoticeViewController(style: .success, title: self.success, message: "Your request has been completed."); notice.onDone = self.onFinished; host?.present(notice, animated: true) } } }
}
