import UIKit

enum LMTheme {
    static let background = UIColor(red: 0.040, green: 0.008, blue: 0.125, alpha: 1)
    static let panel = UIColor(red: 0.095, green: 0.030, blue: 0.235, alpha: 1)
    static let panel2 = UIColor(red: 0.145, green: 0.055, blue: 0.320, alpha: 1)
    static let pink = UIColor(red: 1, green: 0.05, blue: 0.62, alpha: 1)
    static let pinkSoft = UIColor(red: 1, green: 0.24, blue: 0.68, alpha: 1)
    static let violet = UIColor(red: 0.44, green: 0.16, blue: 0.95, alpha: 1)
    static let muted = UIColor(red: 0.62, green: 0.58, blue: 0.72, alpha: 1)

    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let postScriptName: String
        switch weight {
        case ...UIFont.Weight.light: postScriptName = "Quicksand-Light"
        case ..<UIFont.Weight.semibold: postScriptName = weight >= .medium ? "Quicksand-Medium" : "Quicksand-Regular"
        case ..<UIFont.Weight.bold: postScriptName = "Quicksand-SemiBold"
        default: postScriptName = "Quicksand-Bold"
        }
        return UIFont(name: postScriptName, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
    }

    static func displayFont(size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        let postScriptName: String
        switch weight {
        case ...UIFont.Weight.light: postScriptName = "SpaceGrotesk-Light"
        case ..<UIFont.Weight.semibold: postScriptName = weight >= .medium ? "SpaceGrotesk-Medium" : "SpaceGrotesk-Regular"
        default: postScriptName = "SpaceGrotesk-Bold"
        }
        return UIFont(name: postScriptName, size: size) ?? font(size: size, weight: weight)
    }

    static func gradient(_ view: UIView, colors: [UIColor] = [violet, pink], horizontal: Bool = true) {
        view.layoutIfNeeded()
        view.layer.sublayers?.removeAll(where: { $0.name == "LMGradient" })
        let layer = CAGradientLayer(); layer.name = "LMGradient"; layer.frame = view.bounds
        layer.colors = colors.map(\.cgColor)
        layer.startPoint = horizontal ? CGPoint(x: 0, y: 0.5) : CGPoint(x: 0.5, y: 0)
        layer.endPoint = horizontal ? CGPoint(x: 1, y: 0.5) : CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(layer, at: 0)
    }
}

final class LMGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor], horizontal: Bool = true) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = horizontal ? CGPoint(x: 0, y: 0.5) : CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = horizontal ? CGPoint(x: 1, y: 0.5) : CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
}

extension UIView {
    func pin(to view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }
    func round(_ radius: CGFloat) { layer.cornerRadius = radius; layer.masksToBounds = true }
}

extension UILabel {
    static func lm(_ text: String = "", size: CGFloat = 16, weight: UIFont.Weight = .regular, color: UIColor = .white) -> UILabel {
        let label = UILabel(); label.text = text.lmLocalized; label.font = LMTheme.font(size: size, weight: weight); label.textColor = color
        return label
    }
}

extension UIButton {
    static func lm(_ title: String, symbol: String? = nil) -> UIButton {
        var config = UIButton.Configuration.plain(); config.title = title.lmLocalized; config.baseForegroundColor = .white
        if let symbol { config.image = UIImage(systemName: symbol); config.imagePadding = 7 }
        let button = UIButton(configuration: config); button.titleLabel?.font = LMTheme.font(size: 15, weight: .semibold)
        return button
    }
}

extension UITextField {
    func setLeftPadding(_ width: CGFloat) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 1))
        leftViewMode = .always
    }
}

class LMViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMTheme.background
        navigationItem.backButtonTitle = ""
        navigationItem.backButtonDisplayMode = .minimal
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let currentTitle = title { title = currentTitle.lmLocalized }
    }
}
