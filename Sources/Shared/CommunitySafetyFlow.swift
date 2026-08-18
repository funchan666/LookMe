import UIKit

struct SafetyTarget {
    let id: String
    let type: String
    let userID: String?
    let displayName: String
}

enum SafetyCoordinator {
    static func present(from presenter: UIViewController, target: SafetyTarget) {
        let sheet = SafetyMenuViewController(target: target)
        sheet.onReport = { [weak presenter] in
            presenter?.dismiss(animated: true) {
                guard let presenter else { return }
                presenter.present(ReportReasonViewController(target: target), animated: true)
            }
        }
        sheet.onBlock = { [weak presenter] in
            guard let userID = target.userID else { return }
            presenter?.dismiss(animated: true) {
                LookMeExperienceStore.shared.blockUser(userID)
                presenter?.present(LMNoticeViewController(style: .success, title: "Blocked", message: "\(target.displayName) and their activity are now hidden from your experience."), animated: true)
            }
        }
        presenter.present(sheet, animated: true)
    }
}

final class SafetyMenuViewController: UIViewController {
    var onReport: (() -> Void)?
    var onBlock: (() -> Void)?
    private let target: SafetyTarget

    init(target: SafetyTarget) { self.target = target; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(28); card.layer.borderWidth = 1; card.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor; card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card)
        let grabber = UIView(); grabber.backgroundColor = UIColor.white.withAlphaComponent(0.28); grabber.round(2); grabber.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(grabber)
        let icon = UIImageView(image: UIImage(systemName: "shield.lefthalf.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold))); icon.tintColor = LMTheme.pink; icon.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(icon)
        let title = UILabel.lm("Safety options", size: 20, weight: .bold); title.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(title)
        let subtitle = UILabel.lm("Choose how you want to manage \(target.displayName).", size: 12, weight: .medium, color: LMTheme.muted); subtitle.numberOfLines = 0; subtitle.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(subtitle)
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 10; stack.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(stack)
        let report = action("Report", symbol: "exclamationmark.bubble.fill", color: LMTheme.pinkSoft, selector: #selector(reportTap)); stack.addArrangedSubview(report)
        if target.userID != nil { stack.addArrangedSubview(action("Block user", symbol: "person.crop.circle.badge.xmark", color: .systemRed, selector: #selector(blockTap))) }
        let cancel = action("Cancel", symbol: "xmark", color: .white, selector: #selector(close)); cancel.backgroundColor = LMTheme.panel2; stack.addArrangedSubview(cancel)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12), card.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            grabber.topAnchor.constraint(equalTo: card.topAnchor, constant: 10), grabber.centerXAnchor.constraint(equalTo: card.centerXAnchor), grabber.widthAnchor.constraint(equalToConstant: 38), grabber.heightAnchor.constraint(equalToConstant: 4),
            icon.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 22), icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22), icon.widthAnchor.constraint(equalToConstant: 28), icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 11), title.topAnchor.constraint(equalTo: icon.topAnchor, constant: -1),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor), subtitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20), subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
            stack.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 22), stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14), stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func action(_ title: String, symbol: String, color: UIColor, selector: Selector) -> UIButton {
        let button = UIButton.lm(title, symbol: symbol); button.contentHorizontalAlignment = .leading; button.configuration?.baseForegroundColor = color; button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 17, bottom: 15, trailing: 17); button.backgroundColor = UIColor.white.withAlphaComponent(0.055); button.round(16); button.heightAnchor.constraint(equalToConstant: 54).isActive = true; button.addTarget(self, action: selector, for: .touchUpInside); return button
    }
    @objc private func reportTap() { onReport?() }
    @objc private func blockTap() { onBlock?() }
    @objc private func close() { dismiss(animated: true) }
}

final class ReportReasonViewController: UIViewController {
    private let target: SafetyTarget
    private var selected = "Harassment or bullying"
    private let reasons = ["Harassment or bullying", "Hate or discrimination", "Sexual or unsafe content", "Spam or impersonation", "Other concern"]
    private let stack = UIStackView()
    init(target: SafetyTarget) { self.target = target; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(28); card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card)
        let mark = UIImageView(image: UIImage(systemName: "exclamationmark.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))); mark.tintColor = LMTheme.pink; mark.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(mark)
        let title = UILabel.lm("Tell us what happened", size: 21, weight: .bold); let note = UILabel.lm("Your report is saved and the reported content is hidden immediately.", size: 12, weight: .medium, color: LMTheme.muted); note.numberOfLines = 0; [title,note,stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }; stack.axis = .vertical; stack.spacing = 7
        reasons.enumerated().forEach { index, reason in let b = UIButton(type: .system); b.tag = index; b.contentHorizontalAlignment = .leading; b.titleLabel?.font = LMTheme.font(size: 13, weight: .semibold); b.setTitle("  \(reason)", for: .normal); b.setTitleColor(.white, for: .normal); b.heightAnchor.constraint(equalToConstant: 43).isActive = true; b.round(13); b.addTarget(self, action: #selector(reasonTap(_:)), for: .touchUpInside); stack.addArrangedSubview(b) }
        let send = UIButton.lm("Submit report", symbol: "paperplane.fill"); send.backgroundColor = LMTheme.pink; send.round(22); send.translatesAutoresizingMaskIntoConstraints = false; send.addTarget(self, action: #selector(submit), for: .touchUpInside); card.addSubview(send)
        let cancel = UIButton.lm("Cancel"); cancel.translatesAutoresizingMaskIntoConstraints = false; cancel.addTarget(self, action: #selector(close), for: .touchUpInside); card.addSubview(cancel)
        NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18), card.centerYAnchor.constraint(equalTo: view.centerYAnchor), mark.topAnchor.constraint(equalTo: card.topAnchor, constant: 24), mark.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22), title.leadingAnchor.constraint(equalTo: mark.trailingAnchor, constant: 12), title.centerYAnchor.constraint(equalTo: mark.centerYAnchor), note.topAnchor.constraint(equalTo: mark.bottomAnchor, constant: 15), note.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22), note.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22), stack.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 16), stack.leadingAnchor.constraint(equalTo: note.leadingAnchor), stack.trailingAnchor.constraint(equalTo: note.trailingAnchor), send.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 18), send.leadingAnchor.constraint(equalTo: stack.leadingAnchor), send.trailingAnchor.constraint(equalTo: stack.trailingAnchor), send.heightAnchor.constraint(equalToConstant: 48), cancel.topAnchor.constraint(equalTo: send.bottomAnchor, constant: 5), cancel.centerXAnchor.constraint(equalTo: card.centerXAnchor), cancel.heightAnchor.constraint(equalToConstant: 42), cancel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)])
        refreshReasons()
    }
    @objc private func reasonTap(_ sender: UIButton) { selected = reasons[sender.tag]; refreshReasons() }
    private func refreshReasons() { for (index, view) in stack.arrangedSubviews.enumerated() { guard let b = view as? UIButton else { continue }; let on = reasons[index] == selected; b.backgroundColor = on ? LMTheme.violet.withAlphaComponent(0.72) : UIColor.white.withAlphaComponent(0.05); b.setImage(UIImage(systemName: on ? "checkmark.circle.fill" : "circle"), for: .normal); b.tintColor = on ? LMTheme.pinkSoft : LMTheme.muted } }
    @objc private func submit() { let host = presentingViewController; LookMeExperienceStore.shared.report(targetID: target.id, type: target.type, userID: target.userID, reason: selected); dismiss(animated: true) { host?.present(LMNoticeViewController(style: .success, title: "Report received", message: "Thank you for helping keep LookMe respectful. The content has been hidden."), animated: true) } }
    @objc private func close() { dismiss(animated: true) }
}

final class LMNoticeViewController: UIViewController {
    enum Style { case success, review, warning }
    private let noticeTitle: String; private let message: String; private let style: Style; var onDone: (() -> Void)?
    init(style: Style, title: String, message: String) { self.style = style; noticeTitle = title; self.message = message; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.68)
        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(30); card.layer.borderWidth = 1; card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.3).cgColor; card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card)
        let halo = UIView(); halo.backgroundColor = style == .review ? LMTheme.violet : LMTheme.pink; halo.round(35); halo.layer.shadowColor = halo.backgroundColor?.cgColor; halo.layer.shadowOpacity = 0.55; halo.layer.shadowRadius = 24; halo.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(halo)
        let symbol = style == .success ? "checkmark" : (style == .review ? "sparkles" : "exclamationmark")
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .heavy))); icon.tintColor = .white; icon.translatesAutoresizingMaskIntoConstraints = false; halo.addSubview(icon)
        let title = UILabel.lm(noticeTitle, size: 22, weight: .bold); title.textAlignment = .center; let body = UILabel.lm(message, size: 13, weight: .medium, color: UIColor.white.withAlphaComponent(0.72)); body.textAlignment = .center; body.numberOfLines = 0; let done = UIButton.lm("Got it", symbol: "arrow.right"); done.backgroundColor = LMTheme.pink; done.round(22); done.addTarget(self, action: #selector(close), for: .touchUpInside); [title,body,done].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30), card.centerYAnchor.constraint(equalTo: view.centerYAnchor), halo.topAnchor.constraint(equalTo: card.topAnchor, constant: 27), halo.centerXAnchor.constraint(equalTo: card.centerXAnchor), halo.widthAnchor.constraint(equalToConstant: 70), halo.heightAnchor.constraint(equalTo: halo.widthAnchor), icon.centerXAnchor.constraint(equalTo: halo.centerXAnchor), icon.centerYAnchor.constraint(equalTo: halo.centerYAnchor), title.topAnchor.constraint(equalTo: halo.bottomAnchor, constant: 19), title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8), body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 23), body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -23), done.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 23), done.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), done.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), done.heightAnchor.constraint(equalToConstant: 48), done.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)])
    }
    @objc private func close() { dismiss(animated: true) { [weak self] in self?.onDone?() } }
}
