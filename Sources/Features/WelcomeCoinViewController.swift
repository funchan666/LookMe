import UIKit

final class WelcomeCoinViewController: UIViewController {
    private let amount: Int
    private let amountLabel = UILabel.lm("0", size: 45, weight: .heavy)
    private let token = UIImageView(image: UIImage(named: "WelcomeCrystalToken"))
    private var displayLink: CADisplayLink?
    private var animationStart: CFTimeInterval?

    init(amount: Int) {
        self.amount = amount
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        let card = UIView(); card.backgroundColor = UIColor(red: 0.095, green: 0.025, blue: 0.245, alpha: 1); card.round(30); card.layer.borderWidth = 1; card.layer.borderColor = LMTheme.pink.withAlphaComponent(0.34).cgColor; card.layer.shadowColor = LMTheme.violet.cgColor; card.layer.shadowOpacity = 0.38; card.layer.shadowRadius = 30; card.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(card)

        let accent = UIView(); accent.backgroundColor = LMTheme.pink; accent.round(2)
        let eyebrow = UILabel.lm("WELCOME GIFT", size: 10, weight: .heavy, color: LMTheme.pinkSoft); eyebrow.letterSpacing(1.8); eyebrow.textAlignment = .center
        token.contentMode = .scaleAspectFit; token.layer.shadowColor = LMTheme.pink.cgColor; token.layer.shadowOpacity = 0.28; token.layer.shadowRadius = 18; token.layer.shadowOffset = .zero
        let title = UILabel.lm("Your LookMe signal is live", size: 22, weight: .bold); title.textAlignment = .center; title.numberOfLines = 0
        let rewardPanel = UIView(); rewardPanel.backgroundColor = UIColor.white.withAlphaComponent(0.055); rewardPanel.round(19); rewardPanel.layer.borderWidth = 1; rewardPanel.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        let unit = UILabel.lm("WELCOME COINS", size: 10, weight: .heavy, color: LMTheme.pinkSoft); unit.letterSpacing(1.15)
        let deposited = UILabel.lm("ADDED TO YOUR VAULT", size: 9, weight: .bold, color: UIColor.white.withAlphaComponent(0.44)); deposited.letterSpacing(0.65)
        let body = UILabel.lm("Use coins for live gifts, room entrances and profile effects.", size: 13, weight: .medium, color: UIColor.white.withAlphaComponent(0.72)); body.numberOfLines = 0; body.textAlignment = .center
        let freeIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))); freeIcon.tintColor = LMTheme.pinkSoft
        let free = UILabel.lm("Messages, calls, comments and follows stay free.", size: 10.5, weight: .semibold, color: UIColor.white.withAlphaComponent(0.56)); free.numberOfLines = 1; free.adjustsFontSizeToFitWidth = true; free.minimumScaleFactor = 0.86
        let freeRow = UIStackView(arrangedSubviews: [freeIcon, free]); freeRow.axis = .horizontal; freeRow.alignment = .center; freeRow.spacing = 6
        let enter = UIButton.lm("Enter LookMe", symbol: "arrow.right"); enter.backgroundColor = LMTheme.pink; enter.round(24); enter.addTarget(self, action: #selector(close), for: .touchUpInside)
        [accent, eyebrow, token, title, rewardPanel, body, freeRow, enter].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        [amountLabel, unit, deposited].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; rewardPanel.addSubview($0) }

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24), card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            accent.topAnchor.constraint(equalTo: card.topAnchor), accent.centerXAnchor.constraint(equalTo: card.centerXAnchor), accent.widthAnchor.constraint(equalToConstant: 54), accent.heightAnchor.constraint(equalToConstant: 4),
            eyebrow.topAnchor.constraint(equalTo: card.topAnchor, constant: 25), eyebrow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), eyebrow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            token.topAnchor.constraint(equalTo: eyebrow.bottomAnchor, constant: 12), token.centerXAnchor.constraint(equalTo: card.centerXAnchor), token.widthAnchor.constraint(equalToConstant: 118), token.heightAnchor.constraint(equalTo: token.widthAnchor),
            title.topAnchor.constraint(equalTo: token.bottomAnchor, constant: 8), title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            rewardPanel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 17), rewardPanel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), rewardPanel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), rewardPanel.heightAnchor.constraint(equalToConstant: 82),
            amountLabel.leadingAnchor.constraint(equalTo: rewardPanel.leadingAnchor, constant: 22), amountLabel.centerYAnchor.constraint(equalTo: rewardPanel.centerYAnchor), unit.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 18), unit.topAnchor.constraint(equalTo: rewardPanel.topAnchor, constant: 23), unit.trailingAnchor.constraint(lessThanOrEqualTo: rewardPanel.trailingAnchor, constant: -12), deposited.leadingAnchor.constraint(equalTo: unit.leadingAnchor), deposited.topAnchor.constraint(equalTo: unit.bottomAnchor, constant: 5), deposited.trailingAnchor.constraint(lessThanOrEqualTo: rewardPanel.trailingAnchor, constant: -12),
            body.topAnchor.constraint(equalTo: rewardPanel.bottomAnchor, constant: 17), body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28), body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            freeRow.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 12), freeRow.centerXAnchor.constraint(equalTo: card.centerXAnchor), freeRow.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 24), freeRow.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -24), freeIcon.widthAnchor.constraint(equalToConstant: 15), freeIcon.heightAnchor.constraint(equalTo: freeIcon.widthAnchor),
            enter.topAnchor.constraint(equalTo: freeRow.bottomAnchor, constant: 21), enter.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), enter.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), enter.heightAnchor.constraint(equalToConstant: 50), enter.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        card.transform = CGAffineTransform(translationX: 0, y: 24).scaledBy(x: 0.96, y: 0.96); card.alpha = 0
        UIView.animate(withDuration: 0.58, delay: 0.08, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4) { card.transform = .identity; card.alpha = 1 }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        token.alpha = 0; token.transform = CGAffineTransform(rotationAngle: -0.07).scaledBy(x: 0.78, y: 0.78)
        UIView.animate(withDuration: 0.72, delay: 0.1, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.45) { self.token.alpha = 1; self.token.transform = .identity }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:))); displayLink = link; link.add(to: .main, forMode: .common)
    }

    @objc private func tick(_ link: CADisplayLink) {
        if animationStart == nil { animationStart = link.timestamp }
        let progress = min((link.timestamp - (animationStart ?? link.timestamp)) / 0.9, 1)
        let eased = 1 - pow(1 - progress, 3)
        amountLabel.text = Int(Double(amount) * eased).formatted()
        if progress >= 1 { link.invalidate(); displayLink = nil }
    }

    @objc private func close() { displayLink?.invalidate(); dismiss(animated: true) }
}

private extension UILabel {
    func letterSpacing(_ value: CGFloat) { guard let text else { return }; attributedText = NSAttributedString(string: text, attributes: [.kern: value, .foregroundColor: textColor as Any, .font: font as Any]) }
}
