import UIKit

enum LoginValidation {
    static func isValidEmail(_ value: String) -> Bool {
        value.range(of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", options: .regularExpression) != nil
    }

    static func isValidPassword(_ value: String) -> Bool { value.count >= 6 }
}

final class StartupLoadingViewController: UIViewController {
    private let onFinished: () -> Void
    private let loadingDots = UIImageView(image: UIImage(named: "launch-signal-pulse.png"))
    private var finished = false

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMTheme.background
        let field = UIImageView(image: UIImage(named: "launch-midnight-field.png"))
        field.contentMode = .scaleAspectFill
        field.alpha = 0.16
        view.addSubview(field)
        field.pin(to: view)
        let icon = UIImageView(image: UIImage(named: "LookMeLaunchMark"))
        icon.contentMode = .scaleAspectFit
        loadingDots.contentMode = .scaleAspectFit
        [icon, loadingDots].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),
            icon.widthAnchor.constraint(equalToConstant: 88),
            icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
            loadingDots.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingDots.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            loadingDots.widthAnchor.constraint(equalToConstant: 72),
            loadingDots.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingDots.alpha = 0.42
        UIView.animate(withDuration: 0.72, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut, .allowUserInteraction]) {
            self.loadingDots.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) { [weak self] in self?.finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinished()
    }
}

final class AuthProgressViewController: UIViewController {
    private let progressTitle: String
    private let detail: String
    private let onFinished: () -> Void
    private let heart = UIImageView(image: UIImage(named: "authentication-presence-pulse.png"))

    init(title: String, detail: String, onFinished: @escaping () -> Void) {
        progressTitle = title
        self.detail = detail
        self.onFinished = onFinished
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.025, green: 0.003, blue: 0.08, alpha: 0.91)

        let card = UIView()
        card.backgroundColor = UIColor(red: 0.10, green: 0.025, blue: 0.23, alpha: 0.96)
        card.layer.cornerRadius = 32
        card.layer.borderWidth = 1
        card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.3).cgColor
        card.layer.shadowColor = LMTheme.pink.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 30
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        heart.contentMode = .scaleAspectFit
        let title = UILabel.lm(progressTitle, size: 22, weight: .bold)
        title.textAlignment = .center
        let subtitle = UILabel.lm(detail, size: 13, weight: .medium, color: UIColor.white.withAlphaComponent(0.68))
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        [heart, title, subtitle].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -31),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heart.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            heart.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            heart.widthAnchor.constraint(equalToConstant: 184),
            heart.heightAnchor.constraint(equalToConstant: 102),
            title.topAnchor.constraint(equalTo: heart.bottomAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            subtitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            subtitle.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -27)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        heart.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        heart.alpha = 0.82
        UIView.animate(withDuration: 0.9, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut, .allowUserInteraction]) {
            self.heart.transform = CGAffineTransform(scaleX: 1.015, y: 1.015)
            self.heart.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true, completion: self.onFinished)
        }
    }
}

final class AgreementRequiredViewController: UIViewController {
    var onReview: (() -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        let card = UIView()
        card.backgroundColor = LMTheme.panel
        card.layer.cornerRadius = 30
        card.layer.borderWidth = 1
        card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.35).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let art = UIImageView(image: UIImage(named: "lookme-presence-mark.png"))
        art.contentMode = .scaleAspectFit
        let title = UILabel.lm("One thoughtful tap", size: 23, weight: .bold)
        title.textAlignment = .center
        let body = UILabel.lm("Please read and accept both the Terms of Service and Privacy Policy before continuing.", size: 14, weight: .medium, color: UIColor.white.withAlphaComponent(0.76))
        body.numberOfLines = 0
        body.textAlignment = .center
        let review = UIButton.lm("Review & agree", symbol: "checkmark.shield.fill")
        review.backgroundColor = LMTheme.pink
        review.layer.cornerRadius = 23
        review.addTarget(self, action: #selector(reviewAgreement), for: .touchUpInside)
        [art, title, body, review].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            art.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            art.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            art.widthAnchor.constraint(equalToConstant: 76),
            art.heightAnchor.constraint(equalTo: art.widthAnchor),
            title.topAnchor.constraint(equalTo: art.bottomAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            review.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 23),
            review.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            review.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            review.heightAnchor.constraint(equalToConstant: 50),
            review.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
    }

    @objc private func reviewAgreement() {
        dismiss(animated: true) { [weak self] in self?.onReview?() }
    }
}
